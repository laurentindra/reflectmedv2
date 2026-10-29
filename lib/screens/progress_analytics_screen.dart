import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../models/gibbs_reflection.dart';
import '../models/student_profile.dart';
import '../services/storage_service.dart';

class ProgressAnalyticsScreen extends StatefulWidget {
  const ProgressAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<ProgressAnalyticsScreen> createState() => _ProgressAnalyticsScreenState();
}

class _ProgressAnalyticsScreenState extends State<ProgressAnalyticsScreen> {
  String _selectedPeriod = 'BULAN';
  List<GibbsReflection> _reflections = [];
  StudentProfile _profile = StudentProfile();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await StorageService.loadReflections();
    final profile = await StorageService.loadProfile();
    if (mounted) {
      setState(() {
        _reflections = list;
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.parchmentBg,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal)),
      );
    }

    // 1. Metrik Dasar
    final totalReflections = _reflections.length;
    int avgScore = 84;
    int completeCycles = 0;
    if (_reflections.isNotEmpty) {
      int sumScore = 0;
      for (final r in _reflections) {
        sumScore += r.completionPercentage;
        if (r.isComplete) completeCycles++;
      }
      avgScore = (sumScore / _reflections.length).round();
    }

    final activeDaysCount = _reflections.isNotEmpty
        ? _reflections.map((r) => '${r.createdAt.year}-${r.createdAt.month}-${r.createdAt.day}').toSet().length
        : 7;

    // 2. Kompetensi Berdasarkan 6 Fase Gibbs
    int descScore = 95, feelScore = 88, evalScore = 72, anaScore = 65, concScore = 80, planScore = 58;
    if (_reflections.isNotEmpty) {
      int descCount = 0, feelCount = 0, evalCount = 0, anaCount = 0, concCount = 0, planCount = 0;
      for (final r in _reflections) {
        if (r.description.trim().isNotEmpty) descCount++;
        if (r.feelings.trim().isNotEmpty) feelCount++;
        if (r.evaluation.trim().isNotEmpty) evalCount++;
        if (r.analysis.trim().isNotEmpty) anaCount++;
        if (r.conclusion.trim().isNotEmpty) concCount++;
        if (r.actionPlan.trim().isNotEmpty) planCount++;
      }
      final t = _reflections.length;
      descScore = ((descCount / t) * 100).round();
      feelScore = ((feelCount / t) * 100).round();
      evalScore = ((evalCount / t) * 100).round();
      anaScore = ((anaCount / t) * 100).round();
      concScore = ((concCount / t) * 100).round();
      planScore = ((planCount / t) * 100).round();
    }

    final competencies = [
      {'name': 'Deskripsi Objektif Kasus', 'score': descScore, 'color': AppTheme.stageDeskripsi},
      {'name': 'Kesadaran Respons Emosi', 'score': feelScore, 'color': AppTheme.stagePerasaan},
      {'name': 'Evaluasi Hasil Tindakan', 'score': evalScore, 'color': AppTheme.stageEvaluasi},
      {'name': 'Analisis Kritis Berbasis Teori (EBM)', 'score': anaScore, 'color': AppTheme.stageAnalisis},
      {'name': 'Kesimpulan & Model Mental', 'score': concScore, 'color': AppTheme.stageKesimpulan},
      {'name': 'Rencana Tindakan Terukur (SMART)', 'score': planScore, 'color': AppTheme.stageRencana},
    ];

    // 3. Kategori Stase Klinis
    final Map<String, int> deptMap = {};
    for (final r in _reflections) {
      final dept = r.department.trim().isNotEmpty ? r.department.trim().toUpperCase() : 'UMUM';
      deptMap[dept] = (deptMap[dept] ?? 0) + 1;
    }

    final List<Map<String, dynamic>> categoryList = [];
    final catColors = [
      AppTheme.catKardiologi,
      AppTheme.catRespirasi,
      AppTheme.catEndokrin,
      AppTheme.catNeuro,
      AppTheme.catLain,
    ];

    if (deptMap.isNotEmpty) {
      int idx = 0;
      deptMap.forEach((name, count) {
        categoryList.add({
          'count': count,
          'name': name.length > 10 ? '${name.substring(0, 8)}..' : name,
          'color': catColors[idx % catColors.length],
        });
        idx++;
      });
    } else {
      categoryList.addAll([
        {'count': 5, 'name': 'KARDIOLOGI', 'color': AppTheme.catKardiologi},
        {'count': 4, 'name': 'RESPIRASI', 'color': AppTheme.catRespirasi},
        {'count': 3, 'name': 'INTERNA', 'color': AppTheme.catEndokrin},
        {'count': 2, 'name': 'NEURO', 'color': AppTheme.catNeuro},
        {'count': 1, 'name': 'LAINNYA', 'color': AppTheme.catLain},
      ]);
    }

    // 4. Lencana Pencapaian Dinamis
    final hasTransformative = _reflections.any((r) => r.depthLevel == ReflectionDepth.transformative);
    final hasHighCompleteness = _reflections.any((r) => r.completionPercentage >= 90);
    final hasMultiple = _reflections.length >= 5;
    final hasStarter = _reflections.isNotEmpty;

    final badges = [
      {'title': 'REFLEKSI\nPERTAMA', 'icon': Icons.stars_rounded, 'unlocked': hasStarter},
      {'title': '5 REFLEKSI\nTERCATAT', 'icon': Icons.military_tech_outlined, 'unlocked': hasMultiple},
      {'title': 'SKOR 90+\nLENGKAP', 'icon': Icons.verified_outlined, 'unlocked': hasHighCompleteness},
      {'title': 'TRANSFORMASI\nPARADIGMA', 'icon': Icons.psychology_outlined, 'unlocked': hasTransformative},
    ];

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

              // 2. METRIC STRIP (TOTAL REFLEKSI | RATA SKOR | HARI AKTIF)
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
                    _buildMetricCol(
                      totalReflections < 10 ? '0$totalReflections' : '$totalReflections',
                      'TOTAL REFLEKSI',
                      totalReflections > 0 ? 'Tersimpan' : 'Mulai Baru',
                      null,
                    ),
                    Container(width: 1, height: 46, color: const Color(0xFFE5DDD1)),
                    _buildMetricCol('$avgScore%', 'RATA SKOR', 'Kelengkapan', null),
                    Container(width: 1, height: 46, color: const Color(0xFFE5DDD1)),
                    _buildMetricCol(
                      activeDaysCount < 10 ? '0$activeDaysCount' : '$activeDaysCount',
                      'HARI AKTIF',
                      'Refleksi Diri',
                      null,
                    ),
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

              // 6. KOMPETENSI KLINIS (6 Progress Bars dari Fase Gibbs)
              Text(
                'PENGUASAAN SIKLUS REFLEKSI GIBBS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              Column(
                children: competencies.map((comp) {
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
                              fontSize: 12.5,
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
                              value: (score / 100).clamp(0.0, 1.0),
                              backgroundColor: const Color(0xFFE8DFD3),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                              minHeight: 7,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        SizedBox(
                          width: 32,
                          child: Text(
                            '$score%',
                            textAlign: TextAlign.end,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
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

              // 7. KATEGORI STASE / KASUS
              Text(
                'DISTRIBUSI KASUS STASE ROTASI',
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
                children: categoryList.take(5).map((cat) {
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                'LENCANA PENCAPAIAN & KEMATANGAN',
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
                  children: badges.map((badge) {
                    final unlocked = badge['unlocked'] as bool;
                    final borderColor = unlocked ? AppTheme.primaryTeal : const Color(0xFFD5CDC0);
                    final textColor = unlocked ? AppTheme.textInk : AppTheme.textLight;

                    return Container(
                      width: 96,
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
    final paint = Paint()
      ..color = AppTheme.primaryTeal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.primaryTeal.withOpacity(0.18),
          AppTheme.primaryTeal.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final points = [
      Offset(0, size.height * 0.75),
      Offset(size.width * 0.15, size.height * 0.65),
      Offset(size.width * 0.3, size.height * 0.55),
      Offset(size.width * 0.45, size.height * 0.60),
      Offset(size.width * 0.6, size.height * 0.40),
      Offset(size.width * 0.75, size.height * 0.35),
      Offset(size.width * 0.9, size.height * 0.20),
      Offset(size.width, size.height * 0.15),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    fillPath.moveTo(points[0].dx, size.height);
    fillPath.lineTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final cp1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final cp2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
      fillPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
