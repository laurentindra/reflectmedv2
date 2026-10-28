import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/chat_message.dart';
import '../models/student_profile.dart';
import '../services/gemini_ai_service.dart';
import '../services/storage_service.dart';
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

  StudentProfile _profile = StudentProfile();
  List<ChatMessage> _messages = [];
  bool _isTyping = false;
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
    _initChat();
  }

  Future<void> _initChat() async {
    final profile = await StorageService.loadProfile();
    final savedChat = await StorageService.loadActiveChat();

    setState(() {
      _profile = profile;
      _aiService.updateApiKey(profile.geminiApiKey, modelName: profile.geminiModelName);
      _messages = savedChat;
    });

    if (_messages.isEmpty) {
      final welcomeMsg = ChatMessage(
        id: 'welcome',
        text: 'Selamat datang, dr. Ahmad. Saya ReflectMed AI — pemandu refleksi klinis Anda melalui Siklus Gibbs. Ceritakan satu pengalaman klinis yang ingin Anda telaah hari ini, dan kita mulai dari awal.',
        isUser: false,
        timestamp: DateTime.now(),
        estimatedPhase: GibbsPhase.description,
      );
      setState(() {
        _messages = [welcomeMsg];
      });
      StorageService.saveActiveChat(_messages);
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
        text: 'Selamat datang, ${_profile.fullName.isNotEmpty ? _profile.fullName : 'Dokter'}. Saya ReflectMed AI — pemandu refleksi klinis Anda melalui Siklus Gibbs. Ceritakan satu pengalaman klinis yang ingin Anda telaah hari ini, dan kita mulai dari awal.',
        isUser: false,
        timestamp: DateTime.now(),
        estimatedPhase: GibbsPhase.description,
      );
      setState(() {
        _messages = [welcomeMsg];
        _activeStepIndex = 0;
      });
      await StorageService.saveActiveChat(_messages);
    }
  }

  Future<void> _sendMessage([String? presetText]) async {
    final text = presetText ?? _textController.text.trim();
    if (text.isEmpty) return;

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
      _scrollToBottom();
      await StorageService.saveActiveChat(_messages);

      if (_aiService.lastError != null && mounted) {
        final err = _aiService.lastError!;
        final isAuthErr = err.contains('invalid authentication') || err.contains('API key not valid');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF991B1B),
            behavior: SnackBarBehavior.floating,
            content: Text(
              isAuthErr
                  ? 'Kunci API Gemini tidak valid (Google mewajibkan format resmi awalan "AIzaSy..."). Masuk ke Pengaturan untuk memperbarui.'
                  : 'Koneksi AI: $err',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            duration: const Duration(seconds: 6),
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
    return Scaffold(
      backgroundColor: AppTheme.parchmentBg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP APP BAR (Lightbulb, ReflectMed AI + GEMINI FINE-TUNED, Settings Gear)
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

                  // Center Brand Title & Model Info
                  Column(
                    children: [
                      Text(
                        'ReflectMed AI',
                        style: GoogleFonts.newsreader(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textInk,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _aiService.hasApiKey ? const Color(0xFF10B981) : const Color(0xFFB37D2E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _aiService.hasApiKey
                                ? (_profile.geminiModelName.contains('tuned') ? 'MODEL TERLATIH AKTIF' : 'GEMINI ONLINE')
                                : 'MODE OFFLINE',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Actions: Reset Chat & Settings Gear
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: _resetChat,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceWarm,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.lightBorder),
                          ),
                          child: const Icon(
                            Icons.restart_alt,
                            color: AppTheme.textMuted,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _openSettings,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceWarm,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.lightBorder),
                          ),
                          child: const Icon(
                            Icons.settings_outlined,
                            color: AppTheme.textMuted,
                            size: 20,
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

            // 2. HORIZONTAL GIBBS PHASE STRIP
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE5DDD1), width: 1),
                ),
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _gibbsPhases.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (ctx, i) {
                  final phase = _gibbsPhases[i];
                  final isActive = _activeStepIndex == i;
                  final color = phase['color'] as Color;

                  return GestureDetector(
                    onTap: () => setState(() => _activeStepIndex = i),
                    child: Center(
                      child: Text(
                        '${phase['code']} ${phase['name']}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                          letterSpacing: 1.0,
                          color: isActive ? color : AppTheme.textLight,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 3. CHAT MESSAGES CANVAS
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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

            // 4. CHAT INPUT BAR & DISCLAIMER
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                      const SizedBox(width: 10),
                      // Sand / Tan Send Button
                      InkWell(
                        onTap: () => _sendMessage(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 46,
                          height: 46,
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
                  const SizedBox(height: 8),
                  Text(
                    'VERIFIKASI SELALU DENGAN SUPERVISOR KLINIS ANDA',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
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
        margin: const EdgeInsets.only(bottom: 20, left: 32),
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
      // AI Message: Minimalist Editorial Left Accent Bar
      return Container(
        margin: const EdgeInsets.only(bottom: 24, right: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 3,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    msg.text,
                    style: GoogleFonts.newsreader(
                      fontSize: 16,
                      color: AppTheme.textInk,
                      height: 1.45,
                    ),
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
            'ReflectMed AI sedang menyusun tanggapan...',
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
