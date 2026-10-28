import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';

class ProgressAnalyticsScreen extends StatefulWidget {
  const ProgressAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<ProgressAnalyticsScreen> createState() => _ProgressAnalyticsScreenState();
}

class _ProgressAnalyticsScreenState extends State<ProgressAnalyticsScreen> {
  String _selectedPeriod = 'BULAN';

  final List<Map<String, dynamic>> _competencies = [
    {'name': 'Komunikasi Pasien', 'score': 88, 'color': AppTheme.stageDeskripsi},
    {'name': 'Pengambilan Keputusan', 'score': 75, 'color': AppTheme.stagePerasaan},
    {'name': 'Manajemen Risiko', 'score': 82, 'color': AppTheme.stageKesimpulan},
    {'name': 'Kerja Tim', 'score': 91, 'color': AppTheme.stageEvaluasi},
    {'name': 'Praktik Berbasis Bukti', 'score': 68, 'color': AppTheme.stageAnalisis},
    {'name': 'Refleksi Diri', 'score': 85, 'color': AppTheme.stageRencana},
  ];

  final List<Map<String, dynamic>> _categories = [
    {'count': 5, 'name': 'KARDIOLOGI', 'color': AppTheme.catKardiologi},
    {'count': 4, 'name': 'RESPIRASI', 'color': AppTheme.catRespirasi},
    {'count': 3, 'name': 'ENDOKRIN', 'color': AppTheme.catEndokrin},
    {'count': 2, 'name': 'NEURO', 'color': AppTheme.catNeuro},
    {'count': 3, 'name': 'LAIN', 'color': AppTheme.catLain},
  ];

  final List<Map<String, dynamic>> _badges = [
    {'title': '7 HARI\nBERUNTUN', 'icon': Icons.military_tech_outlined, 'unlocked': true},
    {'title': '10\nREFLEKSI', 'icon': Icons.military_tech_outlined, 'unlocked': true},
    {'title': 'SKOR 90+', 'icon': Icons.military_tech_outlined, 'unlocked': true},
    {'title': '50\nREFLEKSI', 'icon': Icons.military_tech_outlined, 'unlocked': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.parchmentBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP HEADER (LAPORAN KEMAJUAN & Perkembangan Kompetensi Klinis)
              Text(
                'LAPORAN KEMAJUAN',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Perkembangan\nKompetensi Klinis',
                style: GoogleFonts.newsreader(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textInk,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 20),

              // 2. METRIC STRIP (47 TOTAL REFLEKSI | 84 RATA SKOR | 23 HARI AKTIF)
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFE5DDD1), width: 1),
                    bottom: BorderSide(color: Color(0xFFE5DDD1), width: 1),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    _buildMetricCol('47', 'TOTAL REFLEKSI', '+12 BLN INI', null),
                    Container(width: 1, height: 46, color: const Color(0xFFE5DDD1)),
                    _buildMetricCol('84', 'RATA SKOR', '↑ 6 POIN', null),
                    Container(width: 1, height: 46, color: const Color(0xFFE5DDD1)),
                    _buildMetricCol('23', 'HARI AKTIF', 'BLN INI', null),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. PERIOD TABS (MINGGU | BULAN | TAHUN)
              Row(
                children: ['MINGGU', 'BULAN', 'TAHUN'].map((period) {
                  final isActive = _selectedPeriod == period;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPeriod = period),
                    child: Container(
                      margin: const EdgeInsets.only(right: 20),
                      padding: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isActive ? AppTheme.primaryTeal : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        period,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: isActive ? AppTheme.primaryTeal : AppTheme.textLight,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // 4. REFLECTION SCORE TREND (TREN SKOR REFLEKSI)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TREN SKOR REFLEKSI',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  Text(
                    '↑ +19 POIN',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Smooth Trend Line Chart
              Container(
                height: 110,
                width: double.infinity,
                child: CustomPaint(
                  painter: _SmoothTrendChartPainter(),
                ),
              ),
              const SizedBox(height: 4),
              // Month labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['O', 'N', 'D', 'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S'].map((m) {
                  return SizedBox(
                    width: 20,
                    child: Text(
                      m,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textLight,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // 5. AKTIVITAS MINGGU INI (Weekly Bar Chart)
              Text(
                'AKTIVITAS MINGGU INI',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildDayBar('S', 34),
                  _buildDayBar('S', 18),
                  _buildDayBar('R', 52),
                  _buildDayBar('K', 6),
                  _buildDayBar('J', 38),
                  _buildDayBar('S', 18),
                  _buildDayBar('M', 18),
                ],
              ),
              const SizedBox(height: 28),

              // 6. KOMPETENSI KLINIS (6 Progress Bars)
              Text(
                'KOMPETENSI KLINIS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              Column(
                children: _competencies.map((comp) {
                  final score = comp['score'] as int;
                  final color = comp['color'] as Color;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            comp['name'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textInk,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 110,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: score / 100,
                              backgroundColor: const Color(0xFFE8DFD3),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                              minHeight: 7,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        SizedBox(
                          width: 24,
                          child: Text(
                            '$score',
                            textAlign: TextAlign.end,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // 7. KATEGORI KASUS TERBANYAK (Blocks with numbers above)
              Text(
                'KATEGORI KASUS TERBANYAK',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _categories.map((cat) {
                  final count = cat['count'] as int;
                  final color = cat['color'] as Color;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        children: [
                          Text(
                            '$count',
                            style: GoogleFonts.newsreader(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 38,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat['name'] as String,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // 8. LENCANA PENCAPAIAN
              Text(
                'LENCANA PENCAPAIAN',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _badges.map((badge) {
                    final unlocked = badge['unlocked'] as bool;
                    final borderColor = unlocked ? AppTheme.primaryTeal : const Color(0xFFD5CDC0);
                    final textColor = unlocked ? AppTheme.textInk : AppTheme.textLight;

                    return Container(
                      width: 92,
                      height: 104,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceWarm,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 1.2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            badge['icon'] as IconData,
                            size: 24,
                            color: unlocked ? AppTheme.primaryTeal : AppTheme.textLight,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            badge['title'] as String,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: textColor,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCol(String value, String title, String subtitle, String? badge) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.newsreader(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: AppTheme.textInk,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayBar(String day, double height) {
    return Column(
      children: [
        Container(
          width: 36,
          height: height,
          decoration: BoxDecoration(
            color: AppTheme.primaryTeal,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.textLight,
          ),
        ),
      ],
    );
  }
}

class _SmoothTrendChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 12 data points corresponding to O N D J F M A M J J A S
    final points = [
      Offset(size.width * 0.04, size.height * 0.82),
      Offset(size.width * 0.12, size.height * 0.72),
      Offset(size.width * 0.20, size.height * 0.60),
      Offset(size.width * 0.28, size.height * 0.76),
      Offset(size.width * 0.38, size.height * 0.52),
      Offset(size.width * 0.46, size.height * 0.45),
      Offset(size.width * 0.54, size.height * 0.55),
      Offset(size.width * 0.63, size.height * 0.35),
      Offset(size.width * 0.72, size.height * 0.30),
      Offset(size.width * 0.80, size.height * 0.26),
      Offset(size.width * 0.89, size.height * 0.36),
      Offset(size.width * 0.96, size.height * 0.12),
    ];

    final path = Path();
    final fillPath = Path();

    path.moveTo(points.first.dx, points.first.dy);
    fillPath.moveTo(points.first.dx, size.height);
    fillPath.lineTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
      fillPath.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    // Fill paint with soft gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppTheme.primaryTeal.withValues(alpha: 0.18),
          AppTheme.primaryTeal.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Line stroke paint
    final linePaint = Paint()
      ..color = AppTheme.primaryTeal
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, linePaint);

    // Draw circular dots
    final dotPaint = Paint()
      ..color = AppTheme.surfaceWarm
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = AppTheme.primaryTeal
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final pt in points) {
      canvas.drawCircle(pt, 3.5, dotPaint);
      canvas.drawCircle(pt, 3.5, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
