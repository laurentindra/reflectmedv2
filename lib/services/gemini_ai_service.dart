import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/chat_message.dart';
import 'ai_training_service.dart';

class GeminiAiService {
  String? _apiKey;
  String _modelName = 'gemini-1.5-flash';
  GenerativeModel? _model;

  void updateApiKey(String? key, {String? modelName}) {
    _apiKey = key;
    if (modelName != null && modelName.trim().isNotEmpty) {
      _modelName = modelName.trim();
    }
    if (key != null && key.trim().isNotEmpty) {
      final calibratedPrompt = AiTrainingService().buildCalibratedSystemPrompt();
      _model = GenerativeModel(
        model: _modelName,
        apiKey: key.trim(),
        systemInstruction: Content.system(calibratedPrompt),
      );
    } else {
      _model = null;
    }
  }

  String? lastError;
  bool get hasApiKey => _apiKey != null && _apiKey!.trim().isNotEmpty;
  String get activeModelName => _modelName;

  /// Mengirim pesan ke AI Mentor (dengan fallback cerdas offline jika tidak ada API key atau error)
  Future<String> sendMessage(String userText, List<ChatMessage> history) async {
    if (_model != null) {
      try {
        // Format riwayat percakapan sesuai aturan multi-turn Gemini API:
        // 1. Role awal harus 'user'
        // 2. Role harus bergantian secara ketat: user -> model -> user -> model
        // 3. Pesan userText aktif tidak dimasukkan ke history (karena dikirim via chat.sendMessage)
        final validHistory = <Content>[];

        // Ambil riwayat sebelum userText terakhir yang sedang dikirim
        final pastMessages = history.where((m) => m.id != 'welcome').toList();
        if (pastMessages.isNotEmpty && pastMessages.last.isUser && pastMessages.last.text == userText) {
          pastMessages.removeLast();
        }

        String? lastRole;
        for (final msg in pastMessages) {
          final role = msg.isUser ? 'user' : 'model';
          // Gemini mensyaratkan pesan pertama dalam riwayat harus 'user'
          if (validHistory.isEmpty && role != 'user') continue;

          // Pastikan terjadi pergantian role yang valid
          if (role != lastRole) {
            validHistory.add(
              msg.isUser
                  ? Content.text(msg.text)
                  : Content.model([TextPart(msg.text)]),
            );
            lastRole = role;
          }
        }

        // Jika riwayat berakhir pada pesan 'user', buang agar giliran berikutnya (sendMessage) valid
        if (validHistory.isNotEmpty && lastRole == 'user') {
          validHistory.removeLast();
        }

        final chat = _model!.startChat(history: validHistory);
        final response = await chat.sendMessage(Content.text(userText));
        if (response.text != null && response.text!.isNotEmpty) {
          lastError = null;
          return response.text!;
        }
      } catch (e) {
        lastError = e.toString();
        debugPrint('[ReflectMed GeminiAiService API Warning]: $e');
        // Jika terjadi error kuota/koneksi API, beralih ke Fallback Scaffolding Engine
        return _generateIntelligentScaffoldingResponse(userText, history);
      }
    }

    // Default: Intelligent Clinical Mentor Scaffolding Engine (Built-in AMEE Guide 44 & Gibbs)
    return _generateIntelligentScaffoldingResponse(userText, history);
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
