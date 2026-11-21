import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/chat_message.dart';
import 'ai_training_service.dart';

class GibbsStageEvaluation {
  final bool isComplete;
  final String feedback;
  final GibbsPhase? nextPhase;
  final String question;

  const GibbsStageEvaluation({
    required this.isComplete,
    required this.feedback,
    required this.nextPhase,
    required this.question,
  });

  String get displayText {
    if (feedback.trim().isEmpty) return question;
    if (question.trim().isEmpty) return feedback;
    return '${feedback.trim()}\n\n${question.trim()}';
  }
}

class GeminiAiService {
  String? _apiKey;
  String _modelName = 'glm-5.3-flash';
  String _apiBaseUrl = 'https://tokengateway.dev/v1';
  GenerativeModel? _geminiModel;

  bool _isGeminiKey(String? key) {
    final value = key?.trim() ?? '';
    return value.startsWith('AIzaSy') || value.startsWith('AQ.Ab');
  }

  void updateApiKey(String? key, {String? modelName, String? baseUrl}) {
    _apiKey = key;
    if (modelName != null && modelName.trim().isNotEmpty) {
      final m = modelName.trim();
      if (m.contains('pass-glm') || m.contains('deepseek')) {
        _modelName = 'glm-5.3-flash';
      } else {
        _modelName = m;
      }
    }
    _apiBaseUrl = baseUrl?.trim() ?? '';
    _geminiModel = null;

    final trimmedKey = key?.trim();
    // Inisialisasi Google Gemini untuk key format AIzaSy atau AQ.Ab
    if (_isGeminiKey(trimmedKey)) {
      final calibratedPrompt = AiTrainingService().buildCalibratedSystemPrompt();
      _geminiModel = GenerativeModel(
        model: _modelName.contains('deepseek') ? 'gemini-1.5-flash' : _modelName,
        apiKey: trimmedKey!,
        systemInstruction: Content.system(calibratedPrompt),
      );
    } else {
      _geminiModel = null;
    }
  }

  String? lastError;
  String connectionStatus = 'Belum diuji';
  bool get hasApiKey => _apiKey != null && _apiKey!.trim().isNotEmpty;
  String get activeModelName => _modelName;
  String get activeBaseUrl => _apiBaseUrl;

  Future<bool> testConnection() async {
    final key = _apiKey?.trim();
    if (key == null || !_isGeminiKey(key)) {
      lastError = 'Kunci API Gemini tidak dikenali.';
      connectionStatus = 'Key tidak valid';
      return false;
    }

    try {
      final model = GenerativeModel(
        model: _modelName.contains('deepseek') ||
                _modelName.contains('pass-glm') ||
                _modelName.contains('glm')
            ? 'gemini-2.5-flash'
            : _modelName,
        apiKey: key!,
      );
      final response = await model.generateContent([
        Content.text('Balas hanya dengan kata "Terhubung".'),
      ]);
      if (response.text != null && response.text!.trim().isNotEmpty) {
        lastError = null;
        connectionStatus = 'Terhubung';
        return true;
      }

      lastError = 'Gemini tidak mengembalikan respons.';
      connectionStatus = 'Tidak ada respons';
      return false;
    } catch (e) {
      lastError = e.toString();
      connectionStatus = 'Gagal terhubung';
      debugPrint('[ReflectMed Gemini Test Error]: $e');
      return false;
    }
  }

  bool get isTokenGateway =>
      _apiKey != null &&
      (_apiKey!.trim().startsWith('tk-gw-') ||
          _apiBaseUrl.contains('tokengateway') ||
          _modelName.toLowerCase().contains('deepseek'));

  String _phaseName(GibbsPhase phase) {
    switch (phase) {
      case GibbsPhase.description:
        return 'Description / Deskripsi';
      case GibbsPhase.feelings:
        return 'Feelings / Perasaan';
      case GibbsPhase.evaluation:
        return 'Evaluation / Evaluasi';
      case GibbsPhase.analysis:
        return 'Analysis / Analisis';
      case GibbsPhase.conclusion:
        return 'Conclusion / Kesimpulan';
      case GibbsPhase.actionPlan:
        return 'Action Plan / Rencana Aksi';
    }
  }

  GibbsPhase _nextPhase(GibbsPhase phase) {
    final values = GibbsPhase.values;
    final index = values.indexOf(phase);
    if (index < 0 || index >= values.length - 1) return phase;
    return values[index + 1];
  }

  GibbsPhase? _parseNextPhase(dynamic value) {
    final normalized = value?.toString().toLowerCase().trim() ?? '';
    for (final phase in GibbsPhase.values) {
      if (normalized.contains(phase.name.toLowerCase())) return phase;
    }
    if (normalized.contains('descrip') ||
        normalized.contains('description') ||
        normalized.contains('deskripsi')) {
      return GibbsPhase.description;
    }
    if (normalized.contains('feeling') ||
        normalized.contains('perasaan') ||
        normalized.contains('emosi')) {
      return GibbsPhase.feelings;
    }
    if (normalized.contains('evalu')) return GibbsPhase.evaluation;
    if (normalized.contains('analys') || normalized.contains('analisis')) {
      return GibbsPhase.analysis;
    }
    if (normalized.contains('concl') || normalized.contains('kesimpulan')) {
      return GibbsPhase.conclusion;
    }
    if (normalized.contains('action') ||
        normalized.contains('rencana') ||
        normalized.contains('aksi')) {
      return GibbsPhase.actionPlan;
    }
    return null;
  }

  GibbsStageEvaluation _parseStageEvaluation(
    String raw,
    GibbsPhase activePhase,
    String userText,
  ) {
    var cleaned = raw.trim();
    if (cleaned.contains('{') && cleaned.contains('}')) {
      final start = cleaned.indexOf('{');
      final end = cleaned.lastIndexOf('}');
      cleaned = cleaned.substring(start, end + 1);
    }

    try {
      final decoded = jsonDecode(cleaned);
      if (decoded is Map<String, dynamic>) {
        final status = (decoded['status'] ?? '').toString().toLowerCase();
        final isComplete = status == 'complete';
        final feedback = (decoded['feedback'] ?? '').toString();
        final question = (decoded['question'] ?? '').toString();
        final parsedNext = _parseNextPhase(decoded['nextPhase']);
        return GibbsStageEvaluation(
          isComplete: isComplete,
          feedback: feedback,
          nextPhase: isComplete
              ? (parsedNext ?? _nextPhase(activePhase))
              : activePhase,
          question: question.isNotEmpty
              ? question
              : isComplete
                  ? 'Bagaimana jawabanmu untuk tahap berikutnya?'
                  : 'Bisakah kamu memperjelas jawaban untuk tahap ini?',
        );
      }
    } catch (e) {
      debugPrint('[ReflectMed Stage JSON Parse Error]: $e');
    }

    final lowerRaw = raw.toLowerCase();
    final statusMatch = RegExp(r'"?status"?\s*[:=]\s*"?(complete|incomplete)',
            caseSensitive: false)
        .firstMatch(lowerRaw);
    if (statusMatch != null) {
      final isComplete = statusMatch.group(1)?.toLowerCase() == 'complete';
      return GibbsStageEvaluation(
        isComplete: isComplete,
        feedback: '',
        nextPhase: isComplete ? _nextPhase(activePhase) : activePhase,
        question: raw
            .replaceAll(RegExp(r'\{[^}]*\}'), '')
            .trim()
            .isEmpty
            ? (isComplete
                ? 'Mari lanjutkan ke tahap berikutnya.'
                : 'Bisakah kamu memperjelas jawaban ini sedikit lagi?')
            : raw.trim(),
      );
    }

    final localResult =
        _generateLocalStageEvaluation(userText, activePhase);
    if (raw.trim().isNotEmpty &&
        !raw.contains('Jawaban ini masih perlu diperjelas')) {
      return GibbsStageEvaluation(
        isComplete: localResult.isComplete,
        feedback: '',
        nextPhase: localResult.nextPhase,
        question: raw.trim(),
      );
    }

    return localResult;
  }

  GibbsStageEvaluation _generateLocalStageEvaluation(
    String text,
    GibbsPhase activePhase,
  ) {
    final normalized = text.toLowerCase().trim();
    final wordCount = normalized.isEmpty
        ? 0
        : normalized.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;

    bool complete;
    String question;
    switch (activePhase) {
      case GibbsPhase.description:
        complete = wordCount >= 10 &&
            (normalized.contains('pasien') ||
                normalized.contains('tindakan') ||
                normalized.contains('kejadian') ||
                normalized.contains('saat') ||
                normalized.contains('konsulen') ||
                normalized.contains('bangsal') ||
                normalized.contains('ruangan') ||
                normalized.contains('shift') ||
                normalized.contains('jaga'));
        question = 'Terima sudah berbagi. Bisakah jelaskan kronologi singkatnya: apa yang terjadi, di mana, dan siapa yang terlibat?';
        break;
      case GibbsPhase.feelings:
        complete = wordCount >= 12 &&
            RegExp(r'(sedih|cemas|takut|gugup|malu|bersalah|bingung|marah|tekan|khawatir|bangga|lega|terkejut|panik)').hasMatch(normalized);
        question = 'Perasaan apa yang paling kuat saat kejadian berlangsung dan setelahnya? Apa respons emosionalmu?';
        break;
      case GibbsPhase.evaluation:
        complete = wordCount >= 16 &&
            (normalized.contains('baik') ||
                normalized.contains('berhasil') ||
                normalized.contains('kurang') ||
                normalized.contains('sulit') ||
                normalized.contains('berjalan'));
        question = 'Manakah hal yang berjalan baik dan hal yang kurang baik? Apa yang menjadi bukti atau dampaknya?';
        break;
      case GibbsPhase.analysis:
        complete = wordCount >= 24 &&
            (normalized.contains('karena') ||
                normalized.contains('mengapa') ||
                normalized.contains('faktor') ||
                normalized.contains('sebab') ||
                normalized.contains('akibat') ||
                normalized.contains('komunikasi') ||
                normalized.contains('teori'));
        question = 'Mengapa kejadian itu bisa terjadi menurutmu? Hubungkan faktor penyebab, komunikasi, emosi, sistem, atau teori yang relevan.';
        break;
      case GibbsPhase.conclusion:
        complete = wordCount >= 16 &&
            (normalized.contains('pelajaran') ||
                normalized.contains('kesimpulan') ||
                normalized.contains('menyadari') ||
                normalized.contains('insight') ||
                normalized.contains('belajar') ||
                normalized.contains('berubah'));
        question = 'Apa pelajaran atau pemahaman baru yang kamu peroleh tentang dirimu dan situasi klinis tersebut?';
        break;
      case GibbsPhase.actionPlan:
        complete = wordCount >= 18 &&
            (normalized.contains('akan') ||
                normalized.contains('rencana') ||
                normalized.contains('langkah') ||
                normalized.contains('besok') ||
                normalized.contains('minggu') ||
                normalized.contains('berikutnya'));
        question = 'Apa tindakan konkret yang akan kamu lakukan, kapan dilaksanakan, dan bagaimana kamu akan mengukur keberhasilannya?';
        break;
    }

    if (complete) {
      return GibbsStageEvaluation(
        isComplete: true,
        feedback: 'Jawabanmu sudah cukup memadai untuk tahap ${_phaseName(activePhase)}.',
        nextPhase: _nextPhase(activePhase),
        question: activePhase == GibbsPhase.actionPlan
            ? 'Refleksi ini sudah lengkap. Kamu dapat menyusun laporan akhir sekarang.'
            : 'Sekarang, mari lanjut ke tahap berikutnya.',
      );
    }

    return GibbsStageEvaluation(
      isComplete: false,
      feedback: 'Jawaban untuk tahap ${_phaseName(activePhase)} masih perlu diperjelas.',
      nextPhase: activePhase,
      question: question,
    );
  }

  Future<GibbsStageEvaluation> evaluateStage({
    required String userText,
    required List<ChatMessage> history,
    required GibbsPhase activePhase,
  }) async {
    final key = _apiKey?.trim();
    if (key == null || key.isEmpty) {
      return _generateLocalStageEvaluation(userText, activePhase);
    }

    final activeName = _phaseName(activePhase);
    final nextName = _phaseName(_nextPhase(activePhase));
    final evaluatorPrompt = '''
TAHAP GIBBS AKTIF SAAT INI: $activeName

Tugasmu adalah menilai jawaban mahasiswa untuk tahap ini, lalu memberi respons mentoring.

Balas seperti mentor klinis yang sedang bercakap-cakap dengan mahasiswa.
Jangan menggunakan kalimat evaluasi mekanis atau menyebutkan nama internal tahap dalam jawaban.
Ajukan paling banyak satu pertanyaan yang terarah dan hangat.

Kriteria tahap:
- Description: kronologi, lokasi, pihak yang terlibat, dan kejadian objektif.
- Feelings: emosi, respons internal, dan dampak emosional saat/sesudah kejadian.
- Evaluation: hal yang berjalan baik dan yang sulit atau kurang baik.
- Analysis: penyebab, alasan, komunikasi, emosi, teori, dan faktor sistem.
- Conclusion: insight atau pembelajaran baru yang spesifik.
- Action Plan: tindakan konkret, indikator keberhasilan, relevansi, dan target waktu.

Aturan:
1. Gunakan "complete" hanya jika jawaban cukup spesifik dan relevan untuk tahap aktif.
2. Jika belum memadai, gunakan "incomplete", tetap pada tahap aktif, dan ajukan satu pertanyaan klarifikasi terarah.
3. Jika complete, akui secara singkat dan lanjutkan ke tahap berikutnya: $nextName.
4. Jangan menilai jawaban sebagai complete hanya karena panjang; nilai isi refleksinya.
5. Untuk Action Plan, lanjutkan ke tahap actionPlan tetap bila belum ada indikator atau target waktu yang jelas.
6. Gunakan Bahasa Indonesia hangat, suportif, dan tidak menghakimi.
7. Keluaran WAJIB JSON valid tanpa teks atau code fence lain.

Jawaban mahasiswa:
"$userText"

Format:
{
  "status": "complete" atau "incomplete",
  "feedback": "Umpan balik singkat",
  "nextPhase": "$nextName",
  "question": "Satu pertanyaan terarah"
}
''';

    final raw = await sendMessage(evaluatorPrompt, history);
    return _parseStageEvaluation(raw, activePhase, userText);
  }

  /// Mengirim pesan ke AI Mentor (Otomatis mendeteksi TokenGateway DeepSeek atau Google Gemini)
  Future<String> sendMessage(String userText, List<ChatMessage> history) async {
    final key = _apiKey?.trim();

    // 1. Jalur Google Gemini Resmi
    if (_isGeminiKey(key)) {
      if (_geminiModel == null) {
        final calibratedPrompt = AiTrainingService().buildCalibratedSystemPrompt();
        _geminiModel = GenerativeModel(
          model: _modelName.contains('deepseek') ? 'gemini-1.5-flash' : _modelName,
          apiKey: key!,
          systemInstruction: Content.system(calibratedPrompt),
        );
      }

      try {
        final validHistory = <Content>[];
        final pastMessages = history.where((m) => m.id != 'welcome').toList();
        if (pastMessages.isNotEmpty &&
            pastMessages.last.isUser &&
            pastMessages.last.text == userText) {
          pastMessages.removeLast();
        }

        String? lastRole;
        for (final msg in pastMessages) {
          final role = msg.isUser ? 'user' : 'model';
          if (validHistory.isEmpty && role != 'user') continue;

          if (role != lastRole) {
            validHistory.add(
              msg.isUser
                  ? Content.text(msg.text)
                  : Content.model([TextPart(msg.text)]),
            );
            lastRole = role;
          }
        }

        if (validHistory.isNotEmpty && lastRole == 'user') {
          validHistory.removeLast();
        }

        final chat = _geminiModel!.startChat(history: validHistory);
        final response = await chat.sendMessage(Content.text(userText));
        if (response.text != null && response.text!.isNotEmpty) {
          lastError = null;
          return response.text!;
        }
      } catch (e) {
        lastError = e.toString();
        debugPrint('[ReflectMed Gemini API Error]: $e');
        return _generateIntelligentScaffoldingResponse(userText, history);
      }
    }

    // 2. Jalur TokenGateway (DeepSeek / OpenAI Compatible)
    if (key != null && key.isNotEmpty &&
        (key.startsWith('tk-gw-') || _apiBaseUrl.contains('tokengateway'))) {
      return await _sendTokenGatewayMessage(userText, history);
    }

    // 3. Fallback: Intelligent Clinical Mentor Scaffolding Engine (Built-in AMEE Guide 44 & Gibbs)
    return _generateIntelligentScaffoldingResponse(userText, history);
  }

  /// Panggilan ke TokenGateway (https://tokengateway.ai.id/v1/chat/completions) dengan Model DeepSeek
  Future<String> _sendTokenGatewayMessage(String userText, List<ChatMessage> history) async {
    final calibratedPrompt = AiTrainingService().buildCalibratedSystemPrompt();

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': calibratedPrompt},
    ];

    // Riwayat percakapan sebelumnya
    final pastMessages = history.where((m) => m.id != 'welcome').toList();
    if (pastMessages.isNotEmpty && pastMessages.last.isUser && pastMessages.last.text == userText) {
      pastMessages.removeLast();
    }

    for (final msg in pastMessages) {
      messages.add({
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.text,
      });
    }

    // Pesan pengguna aktif saat ini
    messages.add({
      'role': 'user',
      'content': userText,
    });

    final endpoint = _apiBaseUrl.endsWith('/')
        ? '${_apiBaseUrl}chat/completions'
        : '$_apiBaseUrl/chat/completions';
    final url = Uri.parse(endpoint);

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 30);

    try {
      String effectiveModel = _modelName.trim();
      if (effectiveModel.isEmpty ||
          effectiveModel.contains('deepseek') ||
          effectiveModel.contains('pass-glm')) {
        effectiveModel = 'glm-5.3-flash';
      }

      final request = await client.postUrl(url);
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.headers.set('Authorization', 'Bearer ${_apiKey!.trim()}');
      request.headers.set('User-Agent', 'ReflectMedApp/1.0 (Mobile; Android)');

      final payload = jsonEncode({
        'model': effectiveModel,
        'messages': messages,
        'temperature': 0.7,
      });

      request.add(utf8.encode(payload));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(responseBody) as Map<String, dynamic>;
        final choices = json['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'] as Map<String, dynamic>?;
          final content = message?['content'] as String?;
          if (content != null && content.trim().isNotEmpty) {
            lastError = null;
            return content.trim();
          }
        }
      }

      if (response.statusCode == 404 && responseBody.contains('model_not_found')) {
        // Otomatis tanyakan ke TokenGateway daftar model yang diizinkan untuk API Key ini
        final availableModels = await _fetchAvailableTokenGatewayModels(client);
        if (availableModels.isNotEmpty) {
          final match = availableModels.firstWhere(
            (m) =>
                m.toLowerCase().contains('glm') ||
                m.toLowerCase().contains('flash') ||
                m.toLowerCase().contains('deepseek'),
            orElse: () => availableModels.first,
          );
          if (match != _modelName) {
            debugPrint('[ReflectMed Auto-Fix]: Beralih dari $_modelName ke model resmi TokenGateway: $match');
            _modelName = match;
            // Coba kirim ulang dengan ID model yang benar dari server
            return await _sendTokenGatewayMessage(userText, history);
          }
          throw Exception('Model "$_modelName" tidak ditemukan. Model aktif di akun Anda: ${availableModels.join(", ")}');
        }
      }

      throw Exception('TokenGateway [HTTP ${response.statusCode}]: $responseBody');
    } catch (e) {
      lastError = e.toString();
      debugPrint('[ReflectMed TokenGateway Error]: $e');
      return _generateIntelligentScaffoldingResponse(userText, history);
    } finally {
      client.close();
    }
  }

  /// Mengambil daftar model yang diizinkan untuk API Key ini dari TokenGateway
  Future<List<String>> _fetchAvailableTokenGatewayModels(HttpClient client) async {
    try {
      final endpoint = _apiBaseUrl.endsWith('/') ? '${_apiBaseUrl}models' : '$_apiBaseUrl/models';
      final req = await client.getUrl(Uri.parse(endpoint));
      req.headers.set('Authorization', 'Bearer ${_apiKey!.trim()}');
      req.headers.set('User-Agent', 'ReflectMedApp/1.0 (Mobile; Android)');
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        final data = json['data'] as List<dynamic>?;
        if (data != null) {
          return data
              .map((item) => (item as Map<String, dynamic>)['id'] as String)
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[ReflectMed] Error fetching models from TokenGateway: $e');
    }
    return [];
  }

  /// Engine pedagogis bawaan berbasis aturan AMEE Guide 44 & Siklus Gibbs
  String _generateIntelligentScaffoldingResponse(String text, List<ChatMessage> history) {
    final lower = text.toLowerCase();
    final step = history.where((m) => m.isUser).length;

    // Deteksi emosi & empati awal
    if (lower.contains('grogi') || lower.contains('takut') || lower.contains('gugup') || lower.contains('panik') || lower.contains('stres')) {
      return "Saya sangat mengerti perasaan itu. Sangat manusiawi dan wajar sekali bagi seorang dokter muda merasakan cemas atau grogi saat dihadapkan pada situasi kritis di bangsal. Terima kasih sudah berani jujur mengutarakannya.\n\nBisa ceritakan lebih spesifik, apa yang sebenarnya memicu rasa cemas itu saat kejadian berlangsung? Apakah karena kondisi pasien, kehadiran konsulen, atau rasa takut berbuat keliru?";
    }

    if (lower.contains('gagal') || lower.contains('salah') || lower.contains('marah') || lower.contains('komplain') || lower.contains('marahin') || lower.contains('bentak')) {
      return "Momen seperti ini memang berat dan seringkali meninggalkan rasa tidak nyaman berhari-hari. Ingat bahwa di pendidikan kedokteran, ketidaknyamanan emosional ini adalah gerbang *transformative learning*.\n\nMari kita urai bersama: selain rasa tertekan itu, menurutmu apa yang sebenarnya menjadi akar penyebab situasi tersebut berkembang seperti itu?";
    }

    if (lower.contains('mati') || lower.contains('meninggal') || lower.contains('arrest') || lower.contains('rjp') || lower.contains('kematian')) {
      return "Menghadapi kehilangan pasien untuk pertama kalinya atau dalam kondisi darurat adalah beban emosional yang sangat mendalam bagi setiap dokter. Duka dan rasa kehilangan ini adalah bukti integritas kemanusiaanmu.\n\nSaat peristiwa itu berlangsung, apa hal yang paling membekas di pikiranmu? Dan bagaimana caramu merawat kesehatan mentalmu malam ini?";
    }

    // Probing bertahap sesuai Gibbs
    if (step <= 1) {
      return "Terima kasih sudah berbagi pengalaman ini. Kedengarannya situasi tersebut sangat berkesan bagi rotasi klinikmu.\n\nSaat peristiwa itu sedang terjadi di ruangan, apa yang pertama kali kamu rasakan di dalam diri, dan bagaimana reaksimu saat itu?";
    } else if (step == 2) {
      return "Sangat menarik kamu memperhatikan respon emosionalmu sendiri. Sekarang coba kita evaluasi sejenak:\n\nDari seluruh rangkaian kejadian tersebut, apa hal yang menurutmu sudah kamu lakukan dengan baik, dan apa aspek yang terasa kurang berjalan lancar?";
    } else if (step == 3) {
      return "Evaluasi yang sangat jujur dan objektif. Mari kita melangkah ke analisis lebih dalam:\n\nMengapa menurutmu hal tersebut bisa terjadi? Apakah ada faktor komunikasi klinis, beban kerja/kelelahan, kurangnya persiapan sebelum tindakan, atau dinamika tim di ruangan?";
    } else if (step == 4) {
      return "Analisis yang tajam. Ini menyentuh inti dari model mentalmu sebagai calon dokter.\n\nSekarang, apa kesimpulan atau pembelajaran terpenting tentang dirimu dan situasi klinis tersebut yang kamu peroleh dari insiden ini?";
    } else {
      return "Refleksi yang sangat matang. Kita sudah sampai pada tahap terpenting: *Altered Action*.\n\nJika minggu depan kamu berada di situasi atau stase yang serupa, langkah konkret apa yang akan kamu lakukan secara berbeda? Mari kita buat rencanamu menjadi spesifik dan terukur (SMART)!";
    }
  }
}
