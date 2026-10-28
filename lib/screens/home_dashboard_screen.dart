import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    setState(() {
      _profile = profile;
      _reflections = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.parchmentBg,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal)),
      );
    }

    final gibbsStages = [
      {'num': '01', 'name': 'Deskripsi', 'score': 95, 'color': AppTheme.stageDeskripsi},
      {'num': '02', 'name': 'Perasaan', 'score': 88, 'color': AppTheme.stagePerasaan},
      {'num': '03', 'name': 'Evaluasi', 'score': 72, 'color': AppTheme.stageEvaluasi},
      {'num': '04', 'name': 'Analisis', 'score': 65, 'color': AppTheme.stageAnalisis},
      {'num': '05', 'name': 'Kesimpulan', 'score': 80, 'color': AppTheme.stageKesimpulan},
      {'num': '06', 'name': 'Rencana Aksi', 'score': 58, 'color': AppTheme.stageRencana},
    ];

    final recentCases = [
      {
        'id': '012',
        'title': 'Penanganan Pasien Hipertensi Krisis',
        'dept': 'KARDIOLOGI',
        'date': '15 SEP',
        'score': 82,
        'color': AppTheme.catKardiologi,
      },
      {
        'id': '011',
        'title': 'Kesalahan Dosis Obat pada Pediatri',
        'dept': 'FARMAKOLOGI',
        'date': '12 SEP',
        'score': 91,
        'color': AppTheme.primaryTeal,
      },
      {
        'id': '010',
        'title': 'Komunikasi dengan Keluarga Pasien',
        'dept': 'KOMUNIKASI',
        'date': '09 SEP',
        'score': 76,
        'color': AppTheme.catKomunikasi,
      },
    ];

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
                    'SELASA, 22 SEPTEMBER',
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
                        const SnackBar(content: Text('Semua notifikasi pembimbing sudah dibaca.')),
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
                _profile.fullName.isNotEmpty ? _profile.fullName : 'dr. Ahmad Fauzi',
                style: GoogleFonts.newsreader(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textInk,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'PPDS INTERNA · FKUI · TAHUN II',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: AppTheme.primaryTeal,
                ),
              ),
              const SizedBox(height: 20),

              // 3. STATS ROW (12 REFLEKSI | 07 STREAK | 04 SIKLUS | 87 SKOR)
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
                    _buildStatCol(_reflections.isNotEmpty ? (_reflections.length < 10 ? '0${_reflections.length}' : '${_reflections.length}') : '12', 'REFLEKSI'),
                    Container(width: 1, height: 36, color: const Color(0xFFE5DDD1)),
                    _buildStatCol('07', 'STREAK'),
                    Container(width: 1, height: 36, color: const Color(0xFFE5DDD1)),
                    _buildStatCol('04', 'SIKLUS'),
                    Container(width: 1, height: 36, color: const Color(0xFFE5DDD1)),
                    _buildStatCol('87', 'SKOR'),
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
                      color: AppTheme.primaryTeal.withValues(alpha: 0.18),
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
                      'Fokuskan sesi berikutnya pada tahap Rencana Aksi — skormu masih 58%.',
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
                        // Switch to reflection form tab (index 2)
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MainNavigationScaffold(initialIndex: 2),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'MULAI REFLEKSI',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: const Color(0xFF80CBC4),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward, size: 14, color: Color(0xFF80CBC4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. AKSI CEPAT (3 Cards)
              Text(
                'AKSI CEPAT',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.edit_outlined,
                      title: 'Refleksi\nBaru',
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
                      icon: Icons.headphones_outlined,
                      title: 'Tanya\nReflectMed\nAI',
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
                      icon: Icons.show_chart,
                      title: 'Progres\n',
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
                      'LIHAT SEMUA →',
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

              // 6 Progress rows
              Column(
                children: gibbsStages.map((stage) {
                  final score = stage['score'] as int;
                  final color = stage['color'] as Color;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
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
                          width: 86,
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

              // 7. REFLEKSI TERBARU
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
                      'ARSIP →',
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

              // 3 Recent Cases
              Column(
                children: recentCases.map((item) {
                  final color = item['color'] as Color;
                  return InkWell(
                    onTap: () {
                      final dummy = GibbsReflection(
                        id: item['id'] as String,
                        createdAt: DateTime.now(),
                        title: item['title'] as String,
                        department: item['dept'] as String,
                        description: 'Ringkasan refleksi klinis kasus.',
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GibbsReportScreen(reflection: dummy),
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
                            item['id'] as String,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textLight,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 3,
                            height: 36,
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
                                  item['title'] as String,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textInk,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item['dept']} · ${item['date']}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                    color: AppTheme.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${item['score']}',
                            style: GoogleFonts.newsreader(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCol(String value, String label) {
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
            label,
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
        height: 104,
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
                fontSize: 12,
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
