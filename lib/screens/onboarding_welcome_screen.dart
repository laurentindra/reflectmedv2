import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import 'login_auth_screen.dart';
import 'main_navigation_scaffold.dart';

class OnboardingWelcomeScreen extends StatelessWidget {
  const OnboardingWelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stages = [
      {'num': '01', 'name': 'Deskripsi', 'color': AppTheme.stageDeskripsi},
      {'num': '02', 'name': 'Perasaan', 'color': AppTheme.stagePerasaan},
      {'num': '03', 'name': 'Evaluasi', 'color': AppTheme.stageEvaluasi},
      {'num': '04', 'name': 'Analisis', 'color': AppTheme.stageAnalisis},
      {'num': '05', 'name': 'Kesimpulan', 'color': AppTheme.stageKesimpulan},
      {'num': '06', 'name': 'Rencana Aksi', 'color': AppTheme.stageRencana},
    ];

    return Scaffold(
      backgroundColor: AppTheme.parchmentBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP HEADER (JURNAL REFLEKSI KLINIS - VOL. I · 2026)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'JURNAL REFLEKSI KLINIS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  Text(
                    'VOL. I · 2026',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(height: 1, color: AppTheme.lightBorder),
              const SizedBox(height: 28),

              // 2. ECG ICON BADGE
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primaryTeal, width: 1.5),
                ),
                child: Center(
                  child: CustomPaint(
                    size: const Size(28, 20),
                    painter: _EcgLinePainter(color: AppTheme.primaryTeal),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // 3. TITLE (ReflectMed AI)
              Text(
                'ReflectMed',
                style: GoogleFonts.newsreader(
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textInk,
                  height: 1.05,
                ),
              ),
              Text(
                'AI',
                style: GoogleFonts.newsreader(
                  fontSize: 38,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.primaryTeal,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 20),

              // 4. SUBTITLE
              Text(
                'Ubah setiap pengalaman klinis menjadi pembelajaran terstruktur — dipandu Siklus Gibbs dan kecerdasan buatan.',
                style: GoogleFonts.newsreader(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFF33423F),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 36),

              // 5. ENAM TAHAP REFLEKSI
              Text(
                'ENAM TAHAP REFLEKSI',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 12),

              // 6. GIBBS STAGES LIST
              Column(
                children: stages.map((item) {
                  return Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE5DDD1), width: 1),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Row(
                      children: [
                        Text(
                          item['num'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: item['color'] as Color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          item['name'] as String,
                          style: GoogleFonts.newsreader(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textInk,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 36),

              // 7. BUTTONS
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginAuthScreen()),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Masuk ke Jurnal',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceWarm,
                    side: const BorderSide(color: AppTheme.textInk, width: 1.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MainNavigationScaffold()),
                    );
                  },
                  child: Text(
                    'Buka Akun Baru',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textInk,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 8. FOOTER
              Center(
                child: Text(
                  'UNTUK MAHASISWA & RESIDEN KEDOKTERAN',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    color: AppTheme.textLight,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _EcgLinePainter extends CustomPainter {
  final Color color;
  _EcgLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(0, size.height * 0.55);
    path.lineTo(size.width * 0.25, size.height * 0.55);
    path.lineTo(size.width * 0.40, size.height * 0.15);
    path.lineTo(size.width * 0.55, size.height * 0.90);
    path.lineTo(size.width * 0.70, size.height * 0.40);
    path.lineTo(size.width * 0.85, size.height * 0.55);
    path.lineTo(size.width, size.height * 0.55);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
