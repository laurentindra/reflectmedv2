import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/constants/prompt_templates.dart';
import '../models/chat_message.dart';
import '../models/gibbs_reflection.dart';
import '../models/student_profile.dart';

class GibbsExtractorService {
  final String? apiKey;
  final String? baseUrl;
  final String? modelName;

  GibbsExtractorService({
    this.apiKey,
    this.baseUrl,
    this.modelName,
  });

  /// Helper untuk memanggil LLM baik via TokenGateway (GLM) maupun Google Gemini
  Future<String?> _callLlm({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final key = apiKey?.trim() ?? '';
    if (key.isEmpty) return null;

    // 1. Jalur Google Gemini (AIzaSy...)
    if (key.startsWith('AIzaSy')) {
      try {
        final model = GenerativeModel(
          model: (modelName != null &&
                  !modelName!.contains('deepseek') &&
                  !modelName!.contains('glm'))
              ? modelName!
              : 'gemini-1.5-flash',
          apiKey: key,
          systemInstruction: Content.system(systemPrompt),
        );
        final res = await model.generateContent([Content.text(userPrompt)]);
        return res.text;
      } catch (e) {
        debugPrint('[GibbsExtractorService Gemini Error]: $e');
        return null;
      }
    }

    // 2. Jalur TokenGateway (GLM 5.3 Flash / OpenAI-compatible)
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 40);
    try {
      final effectiveUrl = baseUrl?.trim().isNotEmpty == true
          ? baseUrl!.trim()
          : 'https://tokengateway.ai.id/v1';
      final endpoint = effectiveUrl.endsWith('/')
          ? '${effectiveUrl}chat/completions'
          : '$effectiveUrl/chat/completions';

      String effectiveModel = modelName?.trim() ?? '';
      if (effectiveModel.isEmpty ||
          effectiveModel.contains('deepseek') ||
          effectiveModel.contains('pass-glm')) {
        effectiveModel = 'glm-5.3-flash';
      }

      final request = await client.postUrl(Uri.parse(endpoint));
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.headers.set('Authorization', 'Bearer $key');
      request.headers.set('User-Agent', 'ReflectMedApp/1.0 (Mobile; Android)');

      final payload = jsonEncode({
        'model': effectiveModel,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.3,
      });

      request.add(utf8.encode(payload));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(responseBody) as Map<String, dynamic>;
        final choices = json['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'] as Map<String, dynamic>?;
          return message?['content'] as String?;
        }
      } else {
        debugPrint('[GibbsExtractorService TokenGateway HTTP ${response.statusCode}]: $responseBody');
      }
    } catch (e) {
      debugPrint('[GibbsExtractorService TokenGateway Error]: $e');
    } finally {
      client.close();
    }
    return null;
  }

  /// Helper untuk membersihkan dan mem-parse respons JSON dari LLM
  Map<String, dynamic>? _parseJsonSafely(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    var cleaned = raw.trim();

    // Hapus code fence markdown jika ada
    if (cleaned.contains('{') && cleaned.contains('}')) {
      final startIndex = cleaned.indexOf('{');
      final endIndex = cleaned.lastIndexOf('}');
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        cleaned = cleaned.substring(startIndex, endIndex + 1);
      }
    }

    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (e) {
      debugPrint('[GibbsExtractorService JSON Parse Error]: $e\nRaw: $raw');
    }
    return null;
  }

  /// 1. Mengekstrak seluruh riwayat percakapan menjadi dokumen Gibbs terstruktur via LLM
  Future<GibbsReflection> extractReflection({
    required List<ChatMessage> messages,
    required StudentProfile profile,
    String? customTitle,
  }) async {
    final transcript = messages.map((m) {
      final sender = m.isUser ? "Mahasiswa" : "AI Mentor";
      return "$sender: ${m.text}";
    }).join("\n\n");

    if (apiKey != null && apiKey!.trim().isNotEmpty) {
      final rawResponse = await _callLlm(
        systemPrompt: 'Kamu adalah sistem pakar analisis refleksi klinis Gibbs untuk pendidikan kedokteran. Keluaran wajib berupa JSON valid tanpa komentar lain.',
        userPrompt: "${PromptTemplates.gibbsExtractionPrompt}\n\nTRANSKRIP CURHAT MAHASISWA:\n$transcript",
      );

      final jsonMap = _parseJsonSafely(rawResponse);
      if (jsonMap != null) {
        return _buildFromJson(jsonMap, profile);
      }
    }

    // Fallback: Local Intelligent Rule-Based Extractor
    return _buildFromLocalHeuristics(messages, profile, customTitle);
  }

  /// 2. Menganalisis dan memperkaya refleksi manual dari formulir dengan Skor Kedalaman & SMART Plan
  Future<GibbsReflection> analyzeAndEnrichReflection({
    required GibbsReflection reflection,
    required StudentProfile profile,
  }) async {
    if (apiKey != null && apiKey!.trim().isNotEmpty) {
      final prompt = '''
Berikut adalah 6 fase refleksi klinis Gibbs yang ditulis oleh mahasiswa kedokteran (${profile.fullName}, Stase ${profile.currentDepartment}):
1. Deskripsi: ${reflection.description}
2. Perasaan: ${reflection.feelings}
3. Evaluasi: ${reflection.evaluation}
4. Analisis: ${reflection.analysis}
5. Kesimpulan: ${reflection.conclusion}
6. Rencana Aksi: ${reflection.actionPlan}

Tugas Anda sesuai standar AMEE Guide No. 44 (Sandars, 2009):
1. Evaluasi level kedalaman refleksi: "Superficial" (hanya deskriptif fakta), "Analytical" (mengaitkan emosi, teori & evaluasi diri), atau "Transformative" (terjadi pergeseran paradigma/model mental).
2. Tuliskan alasan pedagogis penilaian (depthRationale).
3. Buat 1 kalimat mutiara / pembelajaran inti (keyTakeaway).
4. Rumuskan Rencana Aksi SMART (Specific, Measurable, Achievable, Relevant, TimeBound).

Format keluaran HARUS berupa JSON valid persis seperti skema berikut:
{
  "depthLevel": "Analytical",
  "depthRationale": "Penjelasan mengapa refleksi ini dinilai pada level tersebut...",
  "keyTakeaway": "Kalimat mutiara pembelajaran klinis...",
  "smartAction": {
    "specific": "Tindakan spesifik...",
    "measurable": "Indikator terukur...",
    "achievable": "Cara pencapaian...",
    "relevant": "Kerelevanan dengan kompetensi...",
    "timeBound": "Target waktu pelaksanaan..."
  }
}
''';

      final rawResponse = await _callLlm(
        systemPrompt: 'Kamu adalah penilai refleksi klinis AMEE Guide 44. Keluaran wajib berupa JSON valid.',
        userPrompt: prompt,
      );

      final jsonMap = _parseJsonSafely(rawResponse);
      if (jsonMap != null) {
        ReflectionDepth depth = ReflectionDepth.analytical;
        final depthStr = (jsonMap['depthLevel'] ?? '').toString().toLowerCase();
        if (depthStr.contains('transformative')) {
          depth = ReflectionDepth.transformative;
        } else if (depthStr.contains('superficial')) {
          depth = ReflectionDepth.superficial;
        }

        final smartMap = jsonMap['smartAction'] is Map<String, dynamic>
            ? jsonMap['smartAction'] as Map<String, dynamic>
            : <String, dynamic>{};

        reflection.depthLevel = depth;
        reflection.depthRationale = jsonMap['depthRationale'] ?? reflection.depthRationale;
        reflection.keyTakeaway = jsonMap['keyTakeaway'] ?? reflection.keyTakeaway;
        reflection.smartAction = SmartActionPlan(
          specific: smartMap['specific'] ?? reflection.smartAction.specific,
          measurable: smartMap['measurable'] ?? reflection.smartAction.measurable,
          achievable: smartMap['achievable'] ?? reflection.smartAction.achievable,
          relevant: smartMap['relevant'] ?? reflection.smartAction.relevant,
          timeBound: smartMap['timeBound'] ?? reflection.smartAction.timeBound,
        );
        return reflection;
      }
    }

    // Default Fallback jika offline
    _enrichFromLocalHeuristics(reflection);
    return reflection;
  }

  /// 3. Memberikan umpan balik / coaching instan untuk 1 tahap tertentu di formulir
  Future<String> getStageFeedback({
    required int stageIndex,
    required String stageTitle,
    required String currentText,
    required StudentProfile profile,
  }) async {
    if (apiKey != null && apiKey!.trim().isNotEmpty) {
      final prompt = '''
Anda adalah dr. Mentor Refleksi Pendidikan Kedokteran (AMEE Guide No. 44). Mahasiswa (${profile.fullName}) sedang mengisi tahap "$stageTitle" pada Siklus Gibbs dengan teks berikut:

"$currentText"

Berikan umpan balik atau pertanyaan pemandu singkat (maksimal 2-3 kalimat yang hangat, empatik, dan Sokratik). 
Pandu mahasiswa agar tidak hanya menulis fakta dangkal, melainkan menggali pemikiran yang lebih kritis dan bermakna untuk pertumbuhan profesionalnya.
''';

      final res = await _callLlm(
        systemPrompt: 'Anda adalah dr. Mentor Refleksi Klinis yang empatik dan suportif. Jawab dalam 2-3 kalimat langsung.',
        userPrompt: prompt,
      );

      if (res != null && res.trim().isNotEmpty) {
        return res.trim();
      }
    }

    // Fallback lokal berdasarkan stage
    switch (stageIndex) {
      case 1:
        return 'Draf deskripsi Anda sudah mencakup kronologi. Cobalah tambahkan siapa saja yang terlibat dan bagaimana kondisi lingkungan saat kejadian berlangsung.';
      case 2:
        return 'Bagus, Anda mulai mengenali perasaan Anda. Lebih dalam lagi, apa ketakutan atau kekhawatiran terbesar Anda saat peristiwa itu terjadi?';
      case 3:
        return 'Evaluasi yang seimbang! Sebutkan juga satu hal spesifik yang seharusnya bisa diantisipasi lebih awal agar tidak menjadi kendala.';
      case 4:
        return 'Analisis ini menuju arah yang tepat. Coba hubungkan peristiwa ini dengan pedoman klinis (EBM), faktor beban kerja, atau komunikasi tim.';
      case 5:
        return 'Kesimpulan yang berharga. Apa pemahaman baru yang Anda peroleh tentang diri Anda sebagai calon dokter dari kejadian ini?';
      case 6:
        return 'Rencana aksi Anda cukup baik. Pastikan memiliki target waktu yang jelas (Time-Bound) dan dapat diukur secara konkret pada rotasi berikutnya.';
      default:
        return 'Refleksi yang baik adalah yang berani melihat ke dalam diri dan berkomitmen untuk bertumbuh.';
    }
  }

  GibbsReflection _buildFromJson(Map<String, dynamic> json, StudentProfile profile) {
    ReflectionDepth depth = ReflectionDepth.analytical;
    final depthStr = (json['depthLevel'] ?? '').toString().toLowerCase();
    if (depthStr.contains('transformative')) {
      depth = ReflectionDepth.transformative;
    } else if (depthStr.contains('superficial')) {
      depth = ReflectionDepth.superficial;
    }

    final smartMap = json['smartAction'] is Map<String, dynamic>
        ? json['smartAction'] as Map<String, dynamic>
        : <String, dynamic>{};

    return GibbsReflection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      title: json['title'] ?? 'Refleksi Kasus Rotasi Klinik',
      studentName: profile.fullName,
      studentId: profile.studentId,
      department: profile.currentDepartment,
      hospital: profile.teachingHospital,
      supervisorName: profile.supervisorName,
      description: json['description'] ?? '',
      feelings: json['feelings'] ?? '',
      evaluation: json['evaluation'] ?? '',
      analysis: json['analysis'] ?? '',
      conclusion: json['conclusion'] ?? '',
      actionPlan: json['actionPlan'] ?? '',
      smartAction: SmartActionPlan(
        specific: smartMap['specific'] ?? '',
        measurable: smartMap['measurable'] ?? '',
        achievable: smartMap['achievable'] ?? '',
        relevant: smartMap['relevant'] ?? '',
        timeBound: smartMap['timeBound'] ?? '',
      ),
      depthLevel: depth,
      depthRationale: json['depthRationale'] ?? 'Refleksi telah mencakup evaluasi diri dan rencana perbaikan terukur.',
      keyTakeaway: json['keyTakeaway'] ?? 'Pengalaman klinis bermakna adalah jembatan menuju profesionalisme berkelanjutan.',
    );
  }

  GibbsReflection _buildFromLocalHeuristics(
    List<ChatMessage> messages,
    StudentProfile profile,
    String? customTitle,
  ) {
    final userMessages = messages.where((m) => m.isUser).map((m) => m.text).toList();
    
    String desc = userMessages.isNotEmpty ? userMessages.first : 'Belum ada deskripsi peristiwa.';
    String feel = '';
    String eval = '';
    String ana = '';
    String conc = '';
    String plan = '';

    if (userMessages.length >= 2) feel = userMessages[1];
    if (userMessages.length >= 3) eval = userMessages[2];
    if (userMessages.length >= 4) ana = userMessages[3];
    if (userMessages.length >= 5) conc = userMessages[4];
    if (userMessages.length >= 6) {
      plan = userMessages.sublist(5).join(' ');
    } else if (userMessages.length >= 2) {
      plan = "Mempersiapkan SOP dan melakukan simulasi teknik mandiri sebelum menghadapi rotasi jaga berikutnya.";
    }

    // Deteksi kedalaman refleksi
    final fullText = userMessages.join(' ').toLowerCase();
    ReflectionDepth depth = ReflectionDepth.analytical;
    String rationale = "Mahasiswa mampu mengevaluasi faktor pendukung dan penghambat secara kritis.";

    if (fullText.contains('asumsi') || fullText.contains('menyadari keliru') || fullText.contains('perspektif') || fullText.contains('merombak') || fullText.contains('paradigma')) {
      depth = ReflectionDepth.transformative;
      rationale = "Refleksi mencapai tingkat transformatif: terdapat pergeseran perspektif mendasar dan perombakan model mental (Mezirow, 1981).";
    } else if (userMessages.length <= 2) {
      depth = ReflectionDepth.superficial;
      rationale = "Refleksi masih didominasi deskripsi kejadian murni; disarankan memperdalam analisis mengapa peristiwa terjadi (AMEE Guide 44).";
    }

    return GibbsReflection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      title: customTitle ?? 'Laporan Refleksi Kasus: ${profile.currentDepartment}',
      studentName: profile.fullName,
      studentId: profile.studentId,
      department: profile.currentDepartment,
      hospital: profile.teachingHospital,
      supervisorName: profile.supervisorName,
      description: desc,
      feelings: feel.isNotEmpty ? feel : "Merasa cemas dan tertekan namun termotivasi untuk belajar dari kekurangan.",
      evaluation: eval.isNotEmpty ? eval : "Komunikasi awal dengan perawat berjalan cukup baik, namun persiapan instrumen belum optimal.",
      analysis: ana.isNotEmpty ? ana : "Situasi terjadi akibat beban kerja yang tinggi serta kurangnya latihan 'deliberate practice' sebelum tindakan.",
      conclusion: conc.isNotEmpty ? conc : "Kompetensi klinis memerlukan ketenangan metakognitif dan penguasaan langkah teknis yang matang.",
      actionPlan: plan.isNotEmpty ? plan : "Melakukan briefing 5 menit sebelum ronde dan meminta umpan balik langsung kepada DPJP.",
      smartAction: SmartActionPlan(
        specific: "Membaca kembali panduan klinis dan berlatih prosedur mandiri sebelum dinas.",
        measurable: "Mampu melakukan prosedur tanpa keraguan minimal pada 2 pasien rotasi berikutnya.",
        achievable: "Dapat dilakukan di skill lab kampus pada hari persiapan.",
        relevant: "Terkait langsung dengan kebutuhan kompetensi stase ${profile.currentDepartment}.",
        timeBound: "Diterapkan mulai dinas jaga minggu depan.",
      ),
      depthLevel: depth,
      depthRationale: rationale,
      keyTakeaway: "Refleksi yang jujur mengubah pengalaman klinis biasa menjadi keahlian profesional sejati.",
    );
  }

  void _enrichFromLocalHeuristics(GibbsReflection reflection) {
    final full = '${reflection.description} ${reflection.feelings} ${reflection.evaluation} ${reflection.analysis} ${reflection.conclusion} ${reflection.actionPlan}'.toLowerCase();
    if (full.contains('asumsi') || full.contains('paradigma') || full.contains('model mental') || full.contains('transformasi')) {
      reflection.depthLevel = ReflectionDepth.transformative;
      reflection.depthRationale = 'Refleksi menunjukkan kesadaran kritis tingkat tinggi dan transformasi pemahaman profesional.';
    } else if (reflection.analysis.length > 50 && reflection.evaluation.length > 50) {
      reflection.depthLevel = ReflectionDepth.analytical;
      reflection.depthRationale = 'Analisis mengaitkan emosi dan pertimbangan klinis secara komprehensif.';
    } else {
      reflection.depthLevel = ReflectionDepth.superficial;
      reflection.depthRationale = 'Refleksi masih dominan deskriptif naratif; perlu memperdalam eksplorasi "mengapa" dan emosi diri.';
    }

    if (reflection.keyTakeaway.isEmpty) {
      reflection.keyTakeaway = 'Keterbukaan terhadap evaluasi diri adalah pondasi utama keselamatan pasien dan ketahanan profesional.';
    }

    if (!reflection.smartAction.isComplete) {
      reflection.smartAction = SmartActionPlan(
        specific: reflection.actionPlan.isNotEmpty ? reflection.actionPlan : 'Meninjau ulang SOP dan latihan keterampilan mandiri.',
        measurable: 'Mencapai skor evaluasi mandiri memuaskan pada minimal 2 kasus serupa berikutnya.',
        achievable: 'Dapat dilakukan dengan bimbingan residen atau DPJP.',
        relevant: 'Relevan langsung dengan stase rotasi aktif.',
        timeBound: 'Diterapkan dalam rotasi klinis 1 pekan ke depan.',
      );
    }
  }
}
