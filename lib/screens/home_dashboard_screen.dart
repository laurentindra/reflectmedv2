import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../models/gibbs_reflection.dart';
import '../models/student_profile.dart';
import '../services/storage_service.dart';
import 'gibbs_report_screen.dart';
import 'main_navigation_scaffold.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({Key? key}) : super(key: key);

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  StudentProfile _profile = StudentProfile();
  List<GibbsReflection> _reflections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final profile = await StorageService.loadProfile();
    final list = await StorageService.loadReflections();
    if (mounted) {
      setState(() {
        _profile = profile;
        _reflections = list;
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

    // 1. Hitung skor tiap tahap Gibbs secara dinamis dari arsip refleksi nyata
    int descScore = 95;
    int feelScore = 88;
    int evalScore = 72;
    int anaScore = 65;
    int concScore = 80;
    int planScore = 58;

    if (_reflections.isNotEmpty) {
      int descCount = 0;
      int feelCount = 0;
      int evalCount = 0;
      int anaCount = 0;
      int concCount = 0;
      int planCount = 0;

      for (final r in _reflections) {
        if (r.description.trim().isNotEmpty) descCount++;
        if (r.feelings.trim().isNotEmpty) feelCount++;
        if (r.evaluation.trim().isNotEmpty) evalCount++;
        if (r.analysis.trim().isNotEmpty) anaCount++;
        if (r.conclusion.trim().isNotEmpty) concCount++;
        if (r.actionPlan.trim().isNotEmpty) planCount++;
      }

      final total = _reflections.length;
      descScore = ((descCount / total) * 100).round();
      feelScore = ((feelCount / total) * 100).round();
      evalScore = ((evalCount / total) * 100).round();
      anaScore = ((anaCount / total) * 100).round();
      concScore = ((concCount / total) * 100).round();
      planScore = ((planCount / total) * 100).round();
    }

    final gibbsStages = [
      {'num': '01', 'name': 'Deskripsi', 'score': descScore, 'color': AppTheme.stageDeskripsi},
      {'num': '02', 'name': 'Perasaan', 'score': feelScore, 'color': AppTheme.stagePerasaan},
      {'num': '03', 'name': 'Evaluasi', 'score': evalScore, 'color': AppTheme.stageEvaluasi},
      {'num': '04', 'name': 'Analisis', 'score': anaScore, 'color': AppTheme.stageAnalisis},
      {'num': '05', 'name': 'Kesimpulan', 'score': concScore, 'color': AppTheme.stageKesimpulan},
      {'num': '06', 'name': 'Rencana Aksi', 'score': planScore, 'color': AppTheme.stageRencana},
    ];

    // Cari tahap dengan skor terendah untuk rekomendasi cerdas AI
    var lowestStage = gibbsStages.first;
    for (final s in gibbsStages) {
      if ((s['score'] as int) < (lowestStage['score'] as int)) {
        lowestStage = s;
      }
    }

    // Hitung rata-rata skor kelengkapan
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

    // Format tanggal hari ini
    final now = DateTime.now();
    final dayNames = ['SENIN', 'SELASA', 'RABU', 'KAMIS', 'JUMAT', 'SABTU', 'MINGGU'];
    final monthNames = [
      'JANUARI', 'FEBRUARI', 'MARET', 'APRIL', 'MEI', 'JUNI',
      'JULI', 'AGUSTUS', 'SEPTEMBER', 'OKTOBER', 'NOVEMBER', 'DESEMBER'
    ];
    final todayFormatted = '${dayNames[now.weekday - 1]}, ${now.day} ${monthNames[now.month - 1]}';

    return Scaffold(
      backgroundColor: AppTheme.parchmentBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP HEADER: DATE & NOTIFICATION BELL
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    todayFormatted,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Semua notifikasi pembimbing klinis sudah tersinkron.')),
                      );
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.notifications_none, size: 22, color: AppTheme.textInk),
                        Positioned(
                          right: 1,
                          top: 1,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFC05621),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 2. GREETING & DOCTOR IDENTITY
              Text(
                'Selamat datang kembali,',
                style: GoogleFonts.newsreader(
                  fontSize: 16,
                  color: AppTheme.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _profile.fullName.isNotEmpty ? _profile.fullName : 'dr. Mahasiswa Kedokteran',
                style: GoogleFonts.newsreader(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textInk,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${_profile.currentDepartment.toUpperCase()} · ${_profile.university.toUpperCase()} · ${_profile.studentId}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppTheme.primaryTeal,
                ),
              ),
              const SizedBox(height: 20),

              // 3. STATS ROW (REFLEKSI | STREAK | SIKLUS PENUH | RATA SKOR)
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
                    _buildStatCol(
                      _reflections.isNotEmpty
                          ? (_reflections.length < 10 ? '0${_reflections.length}' : '${_reflections.length}')
                          : '00',
                      'REFLEKSI',
                    ),
                    Container(width: 1, height: 36, color: const Color(0xFFE5DDD1)),
                    _buildStatCol('07', 'STREAK HARI'),
                    Container(width: 1, height: 36, color: const Color(0xFFE5DDD1)),
                    _buildStatCol(
                      completeCycles < 10 ? '0$completeCycles' : '$completeCycles',
                      'SIKLUS LENGKAP',
                    ),
                    Container(width: 1, height: 36, color: const Color(0xFFE5DDD1)),
                    _buildStatCol('$avgScore', 'RATA SKOR'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. FEATURED AI CARD (Deep Teal rounded card)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryTeal.withOpacity(0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, size: 16, color: Color(0xFF80CBC4)),
                        const SizedBox(width: 8),
                        Text(
                          'CATATAN REFLECTMED AI',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                            color: const Color(0xFFB2DFDB),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Fokuskan sesi berikutnya pada tahap ${lowestStage['name']} — kelengkapanmu masih ${lowestStage['score']}%.',
                      style: GoogleFonts.newsreader(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () {
                        // Buka chat mentor interaktif (tab index 1)
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MainNavigationScaffold(initialIndex: 1),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'KONSULTASI AI MENTOR',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward, size: 14, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. QUICK ACTIONS GRID
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Dialog AI\nMentor',
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MainNavigationScaffold(initialIndex: 1),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.draw_outlined,
                      title: 'Formulir\nGibbs 6 Fase',
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MainNavigationScaffold(initialIndex: 2),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.show_chart,
                      title: 'Analitik\nKompetensi',
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MainNavigationScaffold(initialIndex: 3),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // 6. PROGRES SIKLUS GIBBS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PROGRES SIKLUS GIBBS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MainNavigationScaffold(initialIndex: 3),
                        ),
                      );
                    },
                    child: Text(
                      'DETAIL LENGKAP →',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: AppTheme.primaryTeal,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 6 Baris Kemajuan Siklus
              Column(
                children: gibbsStages.map((stage) {
                  final score = stage['score'] as int;
                  final color = stage['color'] as Color;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        Text(
                          stage['num'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                            color: AppTheme.textLight,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 90,
                          child: Text(
                            stage['name'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textInk,
                            ),
                          ),
                        ),
                        Expanded(
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

              // 7. REFLEKSI TERBARU (SINKRON DENGAN DATA NYATA)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'REFLEKSI TERBARU',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MainNavigationScaffold(initialIndex: 4),
                        ),
                      );
                    },
                    child: Text(
                      'SEMUA ARSIP →',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: AppTheme.primaryTeal,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // List Refleksi Nyata
              if (_reflections.isNotEmpty)
                Column(
                  children: _reflections.take(4).map((item) {
                    final colors = [
                      AppTheme.catKardiologi,
                      AppTheme.primaryTeal,
                      AppTheme.catKomunikasi,
                      AppTheme.stageKesimpulan,
                    ];
                    final color = colors[_reflections.indexOf(item) % colors.length];
                    final dateStr = '${item.createdAt.day} ${_shortMonth(item.createdAt.month)}';

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GibbsReportScreen(reflection: item),
                          ),
                        );
                      },
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFEAE3D9), width: 1),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '00${_reflections.indexOf(item) + 1}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textLight,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 3.5,
                              height: 38,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textInk,
                                      height: 1.25,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.department.toUpperCase()} · $dateStr · ${item.depthLabel}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.6,
                                      color: AppTheme.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${item.completionPercentage}%',
                                  style: GoogleFonts.newsreader(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                                Text(
                                  'Lengkap',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    color: AppTheme.textLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                )
              else
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWarm,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.lightBorder),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.draw_outlined, size: 36, color: AppTheme.primaryTeal),
                      const SizedBox(height: 10),
                      Text(
                        'Belum Ada Refleksi Tersimpan',
                        style: GoogleFonts.newsreader(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textInk,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Mulai bedah kasus klinis pertama Anda dengan panduan Sokratik dr. Mentor AI untuk mengasah kematangan klinis.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryTeal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                        label: Text(
                          'Mulai Refleksi Sekarang',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MainNavigationScaffold(initialIndex: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _shortMonth(int month) {
    const m = ['JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN', 'JUL', 'AGT', 'SEP', 'OKT', 'NOV', 'DES'];
    return m[(month - 1).clamp(0, 11)];
  }

  Widget _buildStatCol(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.newsreader(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textInk,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppTheme.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWarm,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.lightBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 22, color: AppTheme.primaryTeal),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textInk,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
