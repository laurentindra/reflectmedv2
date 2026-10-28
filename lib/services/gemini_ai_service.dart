import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/chat_message.dart';
import 'ai_training_service.dart';

class GeminiAiService {
  String? _apiKey;
  String _modelName = 'deepseek-chat';
  String _apiBaseUrl = 'https://tokengateway.ai.id/v1';
  GenerativeModel? _geminiModel;

  void updateApiKey(String? key, {String? modelName, String? baseUrl}) {
    _apiKey = key;
    if (modelName != null && modelName.trim().isNotEmpty) {
      _modelName = modelName.trim();
    }
    if (baseUrl != null && baseUrl.trim().isNotEmpty) {
      _apiBaseUrl = baseUrl.trim();
    }

    final trimmedKey = key?.trim();
    // Inisialisasi Google Gemini jika key berformat resmi Google AIzaSy
    if (trimmedKey != null && trimmedKey.isNotEmpty && trimmedKey.startsWith('AIzaSy')) {
      final calibratedPrompt = AiTrainingService().buildCalibratedSystemPrompt();
      _geminiModel = GenerativeModel(
        model: _modelName.contains('deepseek') ? 'gemini-1.5-flash' : _modelName,
        apiKey: trimmedKey,
        systemInstruction: Content.system(calibratedPrompt),
      );
    } else {
      _geminiModel = null;
    }
  }

  String? lastError;
  bool get hasApiKey => _apiKey != null && _apiKey!.trim().isNotEmpty;
  String get activeModelName => _modelName;
  String get activeBaseUrl => _apiBaseUrl;

  bool get isTokenGateway =>
      _apiKey != null &&
      (_apiKey!.trim().startsWith('tk-gw-') ||
          _apiBaseUrl.contains('tokengateway') ||
          _modelName.toLowerCase().contains('deepseek'));

  /// Mengirim pesan ke AI Mentor (Otomatis mendeteksi TokenGateway DeepSeek atau Google Gemini)
  Future<String> sendMessage(String userText, List<ChatMessage> history) async {
    final key = _apiKey?.trim();

    // 1. Jalur TokenGateway (DeepSeek / OpenAI Compatible)
    if (key != null && key.isNotEmpty && (key.startsWith('tk-gw-') || _apiBaseUrl.contains('tokengateway'))) {
      return await _sendTokenGatewayMessage(userText, history);
    }

    // 2. Jalur Google Gemini Resmi
    if (_geminiModel != null) {
      try {
        final validHistory = <Content>[];
        final pastMessages = history.where((m) => m.id != 'welcome').toList();
        if (pastMessages.isNotEmpty && pastMessages.last.isUser && pastMessages.last.text == userText) {
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
      final request = await client.postUrl(url);
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.headers.set('Authorization', 'Bearer ${_apiKey!.trim()}');

      final payload = jsonEncode({
        'model': _modelName.trim().isNotEmpty ? _modelName.trim() : 'deepseek-chat',
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

      throw Exception('TokenGateway [HTTP ${response.statusCode}]: $responseBody');
    } catch (e) {
      lastError = e.toString();
      debugPrint('[ReflectMed TokenGateway Error]: $e');
      return _generateIntelligentScaffoldingResponse(userText, history);
    } finally {
      client.close();
    }
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
