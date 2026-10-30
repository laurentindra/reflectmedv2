import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/chat_message.dart';
import '../models/student_profile.dart';
import '../services/gemini_ai_service.dart';
import '../services/storage_service.dart';
import '../services/voice_over_service.dart';
import '../widgets/talking_mentor_avatar.dart';
import '../widgets/quick_scenario_chips.dart';
import '../services/gibbs_extractor_service.dart';
import 'gibbs_report_screen.dart';
import 'profile_settings_screen.dart';

class ReflectiveChatScreen extends StatefulWidget {
  const ReflectiveChatScreen({Key? key}) : super(key: key);

  @override
  State<ReflectiveChatScreen> createState() => _ReflectiveChatScreenState();
}

class _ReflectiveChatScreenState extends State<ReflectiveChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiAiService _aiService = GeminiAiService();
  final VoiceOverService _voiceService = VoiceOverService();

  StudentProfile _profile = StudentProfile();
  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isMentorSpeaking = false;
  String? _activeQuestion;
  Timer? _speakingTimer;
  bool _showQuickChips = true;
  int _activeStepIndex = 0;

  final List<Map<String, dynamic>> _gibbsPhases = [
    {'code': '01', 'name': 'DESKRIPSI', 'color': AppTheme.stageDeskripsi, 'phase': GibbsPhase.description},
    {'code': '02', 'name': 'PERASAAN', 'color': AppTheme.stagePerasaan, 'phase': GibbsPhase.feelings},
    {'code': '03', 'name': 'EVALUASI', 'color': AppTheme.stageEvaluasi, 'phase': GibbsPhase.evaluation},
    {'code': '04', 'name': 'ANALISIS', 'color': AppTheme.stageAnalisis, 'phase': GibbsPhase.analysis},
    {'code': '05', 'name': 'KESIMPULAN', 'color': AppTheme.stageKesimpulan, 'phase': GibbsPhase.conclusion},
    {'code': '06', 'name': 'RENCANA AKSI', 'color': AppTheme.stageRencana, 'phase': GibbsPhase.actionPlan},
  ];

  @override
  void initState() {
    super.initState();
    _voiceService.init().then((_) {
      if (mounted) setState(() {});
    });
    _voiceService.onSpeechStarted = () {
      if (mounted) {
        setState(() => _isMentorSpeaking = true);
      }
    };
    _voiceService.onSpeechCompleted = () {
      if (mounted) {
        setState(() => _isMentorSpeaking = false);
      }
    };
    _initChat();
  }

  @override
  void dispose() {
    _speakingTimer?.cancel();
    _voiceService.stop();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _extractQuestion(String text) {
    // Ambil kalimat yang memuat tanda tanya '?'
    final sentences = text.split(RegExp(r'(?<=[.!?\n])\s+'));
    final questions = sentences.where((s) => s.contains('?')).toList();
    if (questions.isNotEmpty) {
      return questions.join(' ');
    }
    return text.length > 130 ? '${text.substring(0, 130)}...' : text;
  }

  void _triggerMentorSpeaking(String text, {bool speakFull = false}) {
    _speakingTimer?.cancel();
    final question = _extractQuestion(text);
    final textToSpeak = speakFull ? text : (question.isNotEmpty ? question : text);

    setState(() {
      _isMentorSpeaking = true;
      _activeQuestion = question.isNotEmpty ? question : text;
    });

    // Jalankan Voice Over audio sesungguhnya
    _voiceService.speak(textToSpeak);

    // Safety fallback timer untuk perangkat yang tidak memicu onComplete
    final durationSeconds = (textToSpeak.length / 15).clamp(4, 18).toInt();
    _speakingTimer = Timer(Duration(seconds: durationSeconds), () {
      if (mounted && !_voiceService.isSpeaking) {
        setState(() => _isMentorSpeaking = false);
      }
    });
  }

  Future<void> _initChat() async {
    final profile = await StorageService.loadProfile();
    final savedChat = await StorageService.loadActiveChat();

    setState(() {
      _profile = profile;
      _aiService.updateApiKey(
        profile.geminiApiKey,
        modelName: profile.geminiModelName,
        baseUrl: profile.apiBaseUrl,
      );
      _messages = savedChat;
    });

    if (_messages.isEmpty) {
      final welcomeMsg = ChatMessage(
        id: 'welcome',
        text: 'Selamat datang, ${_profile.fullName.isNotEmpty ? _profile.fullName : 'Dokter'}. Saya dr. Mentor Refleksi Anda. Ceritakan satu pengalaman klinis atau momen menantang yang ingin Anda telaah hari ini, dan kita bedah bersama melalui Siklus Gibbs.',
        isUser: false,
        timestamp: DateTime.now(),
        estimatedPhase: GibbsPhase.description,
      );
      setState(() {
        _messages = [welcomeMsg];
        _activeQuestion = 'Ceritakan satu pengalaman klinis yang ingin Anda telaah hari ini...';
      });
      StorageService.saveActiveChat(_messages);
    } else {
      final lastAi = _messages.lastWhere((m) => !m.isUser, orElse: () => _messages.first);
      _activeQuestion = _extractQuestion(lastAi.text);
    }
  }

  void _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileSettingsScreen()),
    );
    _initChat();
  }

  void _resetChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceWarm,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Mulai Refleksi Baru?',
          style: GoogleFonts.newsreader(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textInk),
        ),
        content: Text(
          'Percakapan saat ini akan dibersihkan agar Anda bisa menelaah kasus klinis baru dari awal Siklus Gibbs.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Mulai Baru', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final welcomeMsg = ChatMessage(
        id: 'welcome',
        text: 'Selamat datang, ${_profile.fullName.isNotEmpty ? _profile.fullName : 'Dokter'}. Saya dr. Mentor Refleksi Anda. Ceritakan satu pengalaman klinis yang ingin Anda telaah hari ini, dan kita mulai dari awal.',
        isUser: false,
        timestamp: DateTime.now(),
        estimatedPhase: GibbsPhase.description,
      );
      setState(() {
        _messages = [welcomeMsg];
        _activeStepIndex = 0;
        _isMentorSpeaking = false;
        _showQuickChips = true;
        _activeQuestion = 'Ceritakan satu pengalaman klinis yang ingin Anda telaah hari ini...';
      });
      await StorageService.saveActiveChat(_messages);
    }
  }

  Future<void> _generateGibbsReport() async {
    final userMessages = _messages.where((m) => m.isUser).toList();
    if (userMessages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.primaryTeal,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Belum ada percakapan refleksi. Ceritakan pengalaman klinis Anda terlebih dahulu.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: AppTheme.surfaceWarm,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryTeal,
                    strokeWidth: 3.5,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Menyusun Laporan Refleksi Gibbs',
                  style: GoogleFonts.newsreader(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textInk,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'AI Mentor sedang membedah dialog klinis Anda ke dalam 6 fase Gibbs, mengevaluasi kedalaman refleksi, dan merumuskan SMART Plan...',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final extractor = GibbsExtractorService(
        apiKey: _profile.geminiApiKey,
        baseUrl: _profile.apiBaseUrl,
        modelName: _profile.geminiModelName,
      );

      final reflection = await extractor.extractReflection(
        messages: _messages,
        profile: _profile,
      );

      await StorageService.saveReflection(reflection);

      if (mounted) {
        Navigator.pop(context); // Tutup dialog loading

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GibbsReportScreen(reflection: reflection),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Tutup dialog loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF991B1B),
            content: Text('Gagal menyusun laporan refleksi: $e'),
          ),
        );
      }
    }
  }

  Future<void> _sendMessage([String? presetText]) async {
    final text = presetText ?? _textController.text.trim();
    if (text.isEmpty) return;

    _speakingTimer?.cancel();

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _textController.clear();
      _isTyping = true;
      _isMentorSpeaking = false;
    });
    _scrollToBottom();
    await StorageService.saveActiveChat(_messages);

    try {
      final reply = await _aiService.sendMessage(text, _messages);

      final aiMsg = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: reply,
        isUser: false,
        timestamp: DateTime.now(),
        estimatedPhase: _gibbsPhases[_activeStepIndex]['phase'] as GibbsPhase,
      );

      setState(() {
        _messages.add(aiMsg);
        _isTyping = false;
        if (_activeStepIndex < _gibbsPhases.length - 1) {
          _activeStepIndex++;
        }
      });
      _triggerMentorSpeaking(reply);
      _scrollToBottom();
      await StorageService.saveActiveChat(_messages);

      if (_aiService.lastError != null && mounted) {
        final err = _aiService.lastError!;
        final isAuthErr = err.contains('invalid authentication') || err.contains('API key not valid');
        final isNetErr = err.contains('Failed host lookup') || err.contains('SocketException') || err.contains('Network is unreachable') || err.contains('errno = 7');

        String message;
        if (isAuthErr) {
          message = 'Kunci API Gemini tidak valid (Google mewajibkan format resmi awalan "AIzaSy..."). Masuk ke Pengaturan untuk memperbarui.';
        } else if (isNetErr) {
          message = 'Koneksi internet terputus atau gagal menghubungi server TokenGateway (AI otomatis beralih ke Mode Mentor Offline).';
        } else {
          message = 'Koneksi AI: $err';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF991B1B),
            behavior: SnackBarBehavior.floating,
            content: Text(
              message,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() => _isTyping = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Koneksi AI: $e')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mentorState = _isTyping
        ? MentorState.thinking
        : (_isMentorSpeaking ? MentorState.asking : MentorState.listening);

    return Scaffold(
      backgroundColor: AppTheme.parchmentBg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP APP BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE5DDD1), width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Lightbulb Icon Container
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceWarm,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primaryTeal, width: 1.2),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline,
                      color: AppTheme.primaryTeal,
                      size: 20,
                    ),
                  ),

                  // Center Brand Title
                  Text(
                    'ReflectMed AI',
                    style: GoogleFonts.newsreader(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textInk,
                    ),
                  ),

                  // Actions: Buat Laporan (AI), Toggle Scenario Chips, Reset Chat & Settings Gear
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tombol Ekstrak ke Laporan Gibbs (AI)
                      InkWell(
                        onTap: _generateGibbsReport,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryTeal,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryTeal.withValues(alpha: 0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.auto_awesome, color: AppTheme.accentAmber, size: 17),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => setState(() => _showQuickChips = !_showQuickChips),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            color: _showQuickChips ? AppTheme.primaryTeal.withValues(alpha: 0.12) : AppTheme.surfaceWarm,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _showQuickChips ? AppTheme.primaryTeal : AppTheme.lightBorder,
                            ),
                          ),
                          child: Icon(
                            Icons.auto_stories_outlined,
                            color: _showQuickChips ? AppTheme.primaryTeal : AppTheme.textMuted,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: _resetChat,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceWarm,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.lightBorder),
                          ),
                          child: const Icon(
                            Icons.restart_alt,
                            color: AppTheme.textMuted,
                            size: 19,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: _openSettings,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 35,
                          height: 35,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceWarm,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.lightBorder),
                          ),
                          child: const Icon(
                            Icons.settings_outlined,
                            color: AppTheme.textMuted,
                            size: 19,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Banner Aktivasi API Key jika belum dipasang
            if (!_aiService.hasApiKey)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAF0E6),
                  border: Border(bottom: BorderSide(color: Color(0xFFE5DDD1))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 15, color: Color(0xFFB37D2E)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI aktif dalam mode offline. Pasang API Key untuk model terlatih Google Cloud.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7A4E1D),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _openSettings,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          'Hubungkan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryTeal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 2. LIVING MENTOR TALKING AVATAR & PRESENCE BAR
            TalkingMentorAvatar(
              state: mentorState,
              activeQuestion: _activeQuestion,
              isSpeaking: _isMentorSpeaking || _voiceService.isSpeaking,
              isMuted: _voiceService.isMuted,
              onToggleMute: () async {
                await _voiceService.toggleMute();
                setState(() {});
              },
              onStopVoice: () async {
                await _voiceService.stop();
                setState(() => _isMentorSpeaking = false);
              },
              onReplayVoice: () {
                if (_messages.isNotEmpty) {
                  final lastAi = _messages.lastWhere((m) => !m.isUser, orElse: () => _messages.first);
                  _triggerMentorSpeaking(lastAi.text);
                }
              },
            ),

            // 4. CHAT MESSAGES CANVAS
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isTyping) {
                    return _buildTypingIndicator();
                  }
                  final msg = _messages[index];
                  return _buildMessageItem(msg);
                },
              ),
            ),

            // 5. QUICK SCENARIO CHIPS (Jika diaktifkan)
            if (_showQuickChips)
              QuickScenarioChips(
                onSelectScenario: (scenarioPrompt) {
                  _sendMessage(scenarioPrompt);
                },
              ),

            // Call-to-action banner: Selesai bercerita? Ekstrak Laporan Gibbs (AI)
            if (_messages.where((m) => m.isUser).length >= 2)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: InkWell(
                  onTap: _generateGibbsReport,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceWarm,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.35)),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryTeal.withOpacity(0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryTeal.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.auto_awesome, color: AppTheme.primaryTeal, size: 14),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selesai berdiskusi? Buat Laporan Gibbs',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textInk,
                                ),
                              ),
                              Text(
                                'AI akan merangkum 6 fase, skor kedalaman, & SMART Plan',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.primaryTeal, size: 13),
                      ],
                    ),
                  ),
                ),
              ),

            // 6. CHAT INPUT BAR DENGAN MICROPHONE ICON
            Container(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              decoration: const BoxDecoration(
                color: AppTheme.parchmentBg,
                border: Border(
                  top: BorderSide(color: Color(0xFFE5DDD1), width: 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Tombol Mikrofon Suara (Siap untuk integrasi Voice STT)
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppTheme.primaryTeal,
                              behavior: SnackBarBehavior.floating,
                              content: Row(
                                children: [
                                  const Icon(Icons.mic, color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Fitur Suara: Anda dapat langsung bercerita dengan menekan tombol mic ini!',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryTeal.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.35)),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.mic_none_rounded,
                              size: 22,
                              color: AppTheme.primaryTeal,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Input Teks
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceSand,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: TextField(
                            controller: _textController,
                            style: GoogleFonts.newsreader(
                              fontSize: 15,
                              color: AppTheme.textInk,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Tuliskan pengalaman klinis Anda...',
                              hintStyle: GoogleFonts.newsreader(
                                fontSize: 14.5,
                                fontStyle: FontStyle.italic,
                                color: AppTheme.textMuted,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Tombol Kirim
                      InkWell(
                        onTap: () => _sendMessage(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDDD4C6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.send_rounded,
                              size: 19,
                              color: AppTheme.textInk,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'VERIFIKASI SELALU DENGAN SUPERVISOR KLINIS ANDA',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage msg) {
    final timeStr = DateFormat('HH:mm').format(msg.timestamp);

    if (msg.isUser) {
      return Container(
        margin: const EdgeInsets.only(bottom: 18, left: 32),
        alignment: Alignment.centerRight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWarm,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.lightBorder),
              ),
              child: Text(
                msg.text,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppTheme.textInk,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'DOKTER · $timeStr',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: AppTheme.textLight,
              ),
            ),
          ],
        ),
      );
    } else {
      // AI Message
      final question = _extractQuestion(msg.text);
      final isCurrentlyPlaying = _isMentorSpeaking && _activeQuestion == question;

      return Container(
        margin: const EdgeInsets.only(bottom: 22, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 3.5,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg.text,
                        style: GoogleFonts.newsreader(
                          fontSize: 15.5,
                          color: AppTheme.textInk,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Tombol Dengarkan / Hentikan Suara
                      InkWell(
                        onTap: () {
                          if (isCurrentlyPlaying) {
                            _voiceService.stop();
                            setState(() => _isMentorSpeaking = false);
                          } else {
                            _triggerMentorSpeaking(msg.text);
                          }
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: isCurrentlyPlaying
                                ? AppTheme.primaryTeal
                                : AppTheme.primaryTeal.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCurrentlyPlaying ? Icons.stop_circle_rounded : Icons.record_voice_over_rounded,
                                size: 12,
                                color: isCurrentlyPlaying ? Colors.white : AppTheme.primaryTeal,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isCurrentlyPlaying
                                    ? 'Hentikan Suara'
                                    : (_voiceService.isMuted ? 'Suara Dibisukan' : 'Dengarkan Pertanyaan'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isCurrentlyPlaying ? Colors.white : AppTheme.primaryTeal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 17),
              child: Text(
                'REFLECTMED AI · $timeStr',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppTheme.textLight,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 17),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryTeal),
          ),
          const SizedBox(width: 10),
          Text(
            'dr. Mentor sedang menelaah pengalaman Anda...',
            style: GoogleFonts.newsreader(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
