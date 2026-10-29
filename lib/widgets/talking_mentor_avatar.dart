import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';

enum MentorState {
  listening, // Mahasiswa sedang mengetik/bercerita
  thinking,  // AI sedang menyusun tanggapan/analisis
  asking,    // AI sedang mengajukan pertanyaan reflektif (animasi berbicara)
}

/// Widget Interaktif Karakter Mentor Klinis yang dapat "Berbicara"
/// Menghadirkan suasana percakapan yang hangat, empatik, dan interaktif
class TalkingMentorAvatar extends StatefulWidget {
  final MentorState state;
  final String? activeQuestion;
  final VoidCallback? onReplayVoice;
  final VoidCallback? onStopVoice;
  final VoidCallback? onToggleMute;
  final bool isSpeaking;
  final bool isMuted;
  final bool showSpeechBubble;

  const TalkingMentorAvatar({
    Key? key,
    required this.state,
    this.activeQuestion,
    this.onReplayVoice,
    this.onStopVoice,
    this.onToggleMute,
    this.isSpeaking = false,
    this.isMuted = false,
    this.showSpeechBubble = true,
  }) : super(key: key);

  @override
  State<TalkingMentorAvatar> createState() => _TalkingMentorAvatarState();
}

class _TalkingMentorAvatarState extends State<TalkingMentorAvatar>
    with TickerProviderStateMixin {
  late AnimationController _mouthController;
  late AnimationController _pulseController;
  late AnimationController _blinkController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();

    // 1. Animasi Gerak Mulut (Talking Mouth)
    _mouthController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    // 2. Animasi Gelombang Suara Melingkar (Vocal Aura Ripple)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // 3. Animasi Berkedip Alami (Blinking Eyes)
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    // 4. Animasi Soundwave Equalizer (Batang Suara)
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _updateAnimationStates();
    _startRandomBlinking();
  }

  void _startRandomBlinking() async {
    while (mounted) {
      await Future.delayed(Duration(milliseconds: 2500 + math.Random().nextInt(2000)));
      if (mounted) {
        await _blinkController.forward();
        if (mounted) await _blinkController.reverse();
      }
    }
  }

  @override
  void didUpdateWidget(TalkingMentorAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state || oldWidget.isSpeaking != widget.isSpeaking) {
      _updateAnimationStates();
    }
  }

  void _updateAnimationStates() {
    if (widget.state == MentorState.asking || widget.isSpeaking) {
      _mouthController.repeat(reverse: true);
      _pulseController.repeat();
      _waveController.repeat(reverse: true);
    } else if (widget.state == MentorState.thinking) {
      _mouthController.stop();
      _mouthController.value = 0.0;
      _pulseController.repeat();
      _waveController.stop();
    } else {
      // Listening / Idle
      _mouthController.stop();
      _mouthController.value = 0.0;
      _pulseController.stop();
      _waveController.stop();
    }
  }

  @override
  void dispose() {
    _mouthController.dispose();
    _pulseController.dispose();
    _blinkController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color auraColor;
    String statusTitle;
    String statusSubtitle;
    IconData statusIcon;

    switch (widget.state) {
      case MentorState.asking:
        auraColor = AppTheme.primaryTeal;
        statusTitle = 'dr. Mentor Refleksi';
        statusSubtitle = 'Sedang Berbicara & Bertanya...';
        statusIcon = Icons.record_voice_over_rounded;
        break;
      case MentorState.thinking:
        auraColor = const Color(0xFFD97706); // Warm Amber
        statusTitle = 'dr. Mentor Refleksi';
        statusSubtitle = 'Menelaah Pengalaman Klinis Anda...';
        statusIcon = Icons.psychology_rounded;
        break;
      case MentorState.listening:
        auraColor = const Color(0xFF10B981); // Emerald
        statusTitle = 'dr. Mentor Refleksi';
        statusSubtitle = 'Mendengarkan Curhat Anda...';
        statusIcon = Icons.hearing_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWarm,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: auraColor.withOpacity(0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: auraColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar dengan Gelombang Suara (Pulsing Ripple + Animated Mouth)
              SizedBox(
                width: 68,
                height: 68,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Gelombang Suara Melingkar (Ripples)
                    if (widget.state == MentorState.asking || widget.state == MentorState.thinking)
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          final scale = 1.0 + (_pulseController.value * 0.35);
                          final opacity = (1.0 - _pulseController.value).clamp(0.0, 1.0);
                          return Container(
                            width: 60 * scale,
                            height: 60 * scale,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: auraColor.withOpacity(opacity * 0.7),
                                width: 2,
                              ),
                            ),
                          );
                        },
                      ),

                    // Avatar Wajah Dokter dengan Lukisan Vektor
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE8F5E9),
                        border: Border.all(color: auraColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: AnimatedBuilder(
                          animation: Listenable.merge([
                            _mouthController,
                            _blinkController,
                          ]),
                          builder: (context, _) {
                            return CustomPaint(
                              painter: _DoctorFacePainter(
                                mouthOpenRatio: _mouthController.value,
                                eyeBlinkRatio: _blinkController.value,
                                isAsking: widget.state == MentorState.asking,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Badge Indikator Status di Pojok Kanan Bawah
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: auraColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Info Nama Mentor & Indikator Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          statusTitle,
                          style: GoogleFonts.newsreader(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textInk,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: auraColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 9, color: auraColor),
                              const SizedBox(width: 2.5),
                              Text(
                                widget.state == MentorState.asking
                                    ? 'BICARA'
                                    : (widget.state == MentorState.thinking ? 'BERPIKIR' : 'MENYIMAK'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: auraColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (widget.onToggleMute != null)
                          InkWell(
                            onTap: widget.onToggleMute,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: widget.isMuted
                                    ? Colors.black.withOpacity(0.05)
                                    : AppTheme.primaryTeal.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                    size: 11,
                                    color: widget.isMuted ? AppTheme.textLight : AppTheme.primaryTeal,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    widget.isMuted ? 'MUTE' : 'ON',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                      color: widget.isMuted ? AppTheme.textLight : AppTheme.primaryTeal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      statusSubtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 5),

                    // Animasi Visualizer Equalizer Gelombang Suara (Voice Waveform)
                    if (widget.state == MentorState.asking)
                      _buildEqualizerWaveform(auraColor)
                    else if (widget.state == MentorState.thinking)
                      _buildThinkingDots(auraColor)
                    else
                      Text(
                        'Silakan utarakan kasus / emosi yang Anda rasakan...',
                        style: GoogleFonts.newsreader(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.textLight,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Speech Bubble yang Menyorot Pertanyaan Sokratik AI Saat Ini
          if (widget.showSpeechBubble &&
              widget.activeQuestion != null &&
              widget.activeQuestion!.isNotEmpty &&
              widget.state == MentorState.asking) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.format_quote_rounded,
                        size: 18,
                        color: AppTheme.primaryTeal,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.activeQuestion!,
                          style: GoogleFonts.newsreader(
                            fontSize: 13.5,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                            color: AppTheme.textInk,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (widget.onReplayVoice != null)
                        InkWell(
                          onTap: widget.isSpeaking ? widget.onStopVoice : widget.onReplayVoice,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryTeal.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  widget.isSpeaking ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                                  size: 14,
                                  color: AppTheme.primaryTeal,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.isSpeaking
                                      ? 'Hentikan Suara'
                                      : (widget.isMuted ? 'Suara Dibisukan' : 'Dengarkan Pertanyaan'),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryTeal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Equalizer Gelombang Suara (Voice Wave) saat Mentor Bertanya
  Widget _buildEqualizerWaveform(Color color) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, _) {
        final val = _waveController.value;
        final heights = [
          6.0 + 10.0 * math.sin(val * math.pi),
          4.0 + 14.0 * math.cos(val * math.pi * 0.8).abs(),
          8.0 + 12.0 * math.sin((val + 0.3) * math.pi).abs(),
          5.0 + 16.0 * math.sin((val + 0.6) * math.pi).abs(),
          7.0 + 9.0 * math.cos((val + 0.2) * math.pi).abs(),
          4.0 + 13.0 * math.sin((val + 0.9) * math.pi).abs(),
        ];

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...heights.map((h) => Container(
              width: 3.5,
              height: h,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            )),
            const SizedBox(width: 6),
            Text(
              'Suara mentor aktif',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThinkingDots(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 2, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          'Menganalisis sudut pandang Gibbs...',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Pelukis Vektor Wajah Dokter Ramah dengan Gerakan Mulut dan Kedipan Mata
class _DoctorFacePainter extends CustomPainter {
  final double mouthOpenRatio; // 0.0 (tertutup) sampai 1.0 (terbuka berbicara)
  final double eyeBlinkRatio;  // 0.0 (melek) sampai 1.0 (merem berkedip)
  final bool isAsking;

  _DoctorFacePainter({
    required this.mouthOpenRatio,
    required this.eyeBlinkRatio,
    required this.isAsking,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // 1. Latar Belakang Hangat
    final bgPaint = Paint()..color = const Color(0xFFF0FDF4);
    canvas.drawCircle(center, w / 2, bgPaint);

    // 2. Jas Dokter (Lab Coat) Putih di Bagian Bawah
    final coatPaint = Paint()..color = Colors.white;
    final coatPath = Path()
      ..moveTo(w * 0.15, h)
      ..lineTo(w * 0.35, h * 0.72)
      ..lineTo(w * 0.5, h * 0.82)
      ..lineTo(w * 0.65, h * 0.72)
      ..lineTo(w * 0.85, h)
      ..close();
    canvas.drawPath(coatPath, coatPaint);

    // Kerah Jas Dokter
    final collarPaint = Paint()
      ..color = const Color(0xFF0F766E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawLine(Offset(w * 0.35, h * 0.72), Offset(w * 0.5, h * 0.88), collarPaint);
    canvas.drawLine(Offset(w * 0.65, h * 0.72), Offset(w * 0.5, h * 0.88), collarPaint);

    // Stetoskop Sederhana
    final stethoPaint = Paint()
      ..color = const Color(0xFF047857)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final stethoPath = Path()
      ..moveTo(w * 0.25, h * 0.75)
      ..quadraticBezierTo(w * 0.5, h * 0.98, w * 0.75, h * 0.75);
    canvas.drawPath(stethoPath, stethoPaint);

    // 3. Kepala & Wajah
    final skinPaint = Paint()..color = const Color(0xFFFFDBAC);
    final headRect = Rect.fromCenter(center: Offset(center.dx, center.dy - 4), width: w * 0.56, height: h * 0.56);
    canvas.drawOval(headRect, skinPaint);

    // Rambut Rapi Profesional
    final hairPaint = Paint()..color = const Color(0xFF2C3E50);
    final hairPath = Path()
      ..moveTo(center.dx - w * 0.28, center.dy - 4)
      ..quadraticBezierTo(center.dx - w * 0.25, center.dy - h * 0.34, center.dx, center.dy - h * 0.32)
      ..quadraticBezierTo(center.dx + w * 0.25, center.dy - h * 0.34, center.dx + w * 0.28, center.dy - 4)
      ..quadraticBezierTo(center.dx + w * 0.15, center.dy - h * 0.18, center.dx, center.dy - h * 0.20)
      ..quadraticBezierTo(center.dx - w * 0.15, center.dy - h * 0.18, center.dx - w * 0.28, center.dy - 4)
      ..close();
    canvas.drawPath(hairPath, hairPaint);

    // Kacamata Dokter Intelektual
    final glassesPaint = Paint()
      ..color = const Color(0xFF0F766E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final leftGlass = Rect.fromCenter(center: Offset(center.dx - 8, center.dy - 4), width: 12, height: 9);
    final rightGlass = Rect.fromCenter(center: Offset(center.dx + 8, center.dy - 4), width: 12, height: 9);
    canvas.drawRRect(RRect.fromRectAndRadius(leftGlass, const Radius.circular(3)), glassesPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rightGlass, const Radius.circular(3)), glassesPaint);
    canvas.drawLine(Offset(center.dx - 2, center.dy - 4), Offset(center.dx + 2, center.dy - 4), glassesPaint);

    // 4. Mata (Blinking)
    final eyePaint = Paint()
      ..color = const Color(0xFF1F2937)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    if (eyeBlinkRatio > 0.5) {
      // Mata Berkedip (Garis Melengkung Senyum)
      canvas.drawLine(Offset(center.dx - 11, center.dy - 4), Offset(center.dx - 5, center.dy - 4), eyePaint);
      canvas.drawLine(Offset(center.dx + 5, center.dy - 4), Offset(center.dx + 11, center.dy - 4), eyePaint);
    } else {
      // Mata Terbuka Menyimak
      canvas.drawCircle(Offset(center.dx - 8, center.dy - 4), 1.8, eyePaint);
      canvas.drawCircle(Offset(center.dx + 8, center.dy - 4), 1.8, eyePaint);
    }

    // 5. Mulut yang Bergerak Berbicara (Talking Animation)
    final mouthPaint = Paint()
      ..color = const Color(0xFF991B1B)
      ..style = isAsking ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    if (isAsking && mouthOpenRatio > 0.15) {
      // Mulut Terbuka Berbicara (Oval Dinamis Sesuai Ritme Suara)
      final mouthHeight = 3.0 + (mouthOpenRatio * 5.0);
      final mouthWidth = 8.0 + (mouthOpenRatio * 3.0);
      final mouthRect = Rect.fromCenter(
        center: Offset(center.dx, center.dy + 6.5),
        width: mouthWidth,
        height: mouthHeight,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(mouthRect, const Radius.circular(4)), mouthPaint);

      // Gigi Atas Halus
      final teethPaint = Paint()..color = Colors.white;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(center.dx - 3, center.dy + 6.5 - mouthHeight / 2, 6, 2),
          const Radius.circular(1),
        ),
        teethPaint,
      );
    } else {
      // Mulut Tersenyum Hangat Ramah (Saat Mendengarkan / Diam)
      final smilePath = Path()
        ..moveTo(center.dx - 5.5, center.dy + 6)
        ..quadraticBezierTo(center.dx, center.dy + 8.5, center.dx + 5.5, center.dy + 6);
      canvas.drawPath(smilePath, mouthPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DoctorFacePainter oldDelegate) {
    return oldDelegate.mouthOpenRatio != mouthOpenRatio ||
        oldDelegate.eyeBlinkRatio != eyeBlinkRatio ||
        oldDelegate.isAsking != isAsking;
  }
}
