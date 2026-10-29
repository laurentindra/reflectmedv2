import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk Text-To-Speech (Voice Over) AI Mentor Refleksi Klinis.
/// Mengonversi tanggapan sokratik dr. Mentor menjadi suara alami berbahasa Indonesia.
class VoiceOverService {
  static final VoiceOverService _instance = VoiceOverService._internal();
  factory VoiceOverService() => _instance;
  VoiceOverService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  final ValueNotifier<bool> isSpeakingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isMutedNotifier = ValueNotifier<bool>(false);

  bool get isSpeaking => isSpeakingNotifier.value;
  bool get isMuted => isMutedNotifier.value;

  VoidCallback? onSpeechStarted;
  VoidCallback? onSpeechCompleted;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      isMutedNotifier.value = prefs.getBool('voice_over_muted') ?? false;

      // Inisialisasi konfigurasi suara
      await _flutterTts.awaitSpeakCompletion(true);

      // Coba atur bahasa Indonesia (id-ID)
      var isLanguageAvailable = await _flutterTts.isLanguageAvailable("id-ID");
      if (isLanguageAvailable) {
        await _flutterTts.setLanguage("id-ID");
      } else {
        await _flutterTts.setLanguage("en-US");
      }

      // Kecepatan dan nada bersahabat layaknya dokter konsulen ramah
      await _flutterTts.setSpeechRate(0.48); // Kecepatan tenang dan jelas
      await _flutterTts.setPitch(1.0);       // Nada suara natural
      await _flutterTts.setVolume(1.0);

      _flutterTts.setStartHandler(() {
        isSpeakingNotifier.value = true;
        onSpeechStarted?.call();
      });

      _flutterTts.setCompletionHandler(() {
        isSpeakingNotifier.value = false;
        onSpeechCompleted?.call();
      });

      _flutterTts.setCancelHandler(() {
        isSpeakingNotifier.value = false;
        onSpeechCompleted?.call();
      });

      _flutterTts.setErrorHandler((dynamic msg) {
        debugPrint("VoiceOverService TTS error: $msg");
        isSpeakingNotifier.value = false;
        onSpeechCompleted?.call();
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint("VoiceOverService initialization error: $e");
    }
  }

  /// Bersihkan format markdown, tag, dan karakter khusus agar dibaca luwes
  String _cleanTextForSpeech(String rawText) {
    String text = rawText;

    // Hapus markdown bold, italic, code, headers
    text = text.replaceAll(RegExp(r'\*\*|\*|__|_|`|#+'), '');
    // Hapus bullet points
    text = text.replaceAll(RegExp(r'^\s*[-*•]\s*', multiLine: true), '');
    // Hapus tautan [teks](url)
    text = text.replaceAll(RegExp(r'\[(.*?)\]\(.*?\)'), r'$1');
    // Hapus emotikon/simbol umum yang mengganggu lafal
    text = text.replaceAll(RegExp(r'[^\w\s.,!?:;\-\/()"]'), ' ');
    // Rapikan spasi berlebih
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return text;
  }

  /// Jalankan Voice Over untuk teks
  Future<void> speak(String text) async {
    if (isMutedNotifier.value) return;

    if (!_isInitialized) {
      await init();
    }

    final cleaned = _cleanTextForSpeech(text);
    if (cleaned.isEmpty) return;

    try {
      await _flutterTts.stop();
      await _flutterTts.speak(cleaned);
    } catch (e) {
      debugPrint("VoiceOverService speak error: $e");
      isSpeakingNotifier.value = false;
    }
  }

  /// Hentikan suara yang sedang berbicara
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint("VoiceOverService stop error: $e");
    } finally {
      isSpeakingNotifier.value = false;
      onSpeechCompleted?.call();
    }
  }

  /// Toggle mute/unmute suara AI
  Future<void> toggleMute() async {
    final nextState = !isMutedNotifier.value;
    isMutedNotifier.value = nextState;

    if (nextState) {
      await stop();
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('voice_over_muted', nextState);
    } catch (_) {}
  }
}
