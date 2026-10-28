import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../models/gibbs_reflection.dart';
import '../services/storage_service.dart';
import 'gibbs_report_screen.dart';
import 'pdf_export_screen.dart';

class EPortfolioSyncScreen extends StatefulWidget {
  final GibbsReflection? reflection;

  const EPortfolioSyncScreen({Key? key, this.reflection}) : super(key: key);

  @override
  State<EPortfolioSyncScreen> createState() => _EPortfolioSyncScreenState();
}

class _EPortfolioSyncScreenState extends State<EPortfolioSyncScreen> {
  String _selectedTab = 'SEMUA';
  List<GibbsReflection> _savedReflections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await StorageService.loadReflections();
    setState(() {
      _savedReflections = list;
      _isLoading = false;
    });
  }

  // Sample static archive items matching screenshot 6
  final List<Map<String, dynamic>> _portfolioItems = [
    {
      'id': '012',
      'title': 'Penanganan Pasien Hipertensi Krisis',
      'department': 'KARDIOLOGI',
      'date': '15 SEP 2026',
      'score': 82,
      'status': 'TERVERIFIKASI',
      'statusColor': AppTheme.stageKesimpulan,
      'accentColor': AppTheme.catKardiologi,
      'supervisor': 'Prof. Dr. Siti Rahayu, SpPD-KKV',
      'progress': '6/6',
      'expanded': true,
    },
    {
      'id': '011',
      'title': 'Kesalahan Dosis Obat pada Pasien Pediatri',
      'department': 'FARMAKOLOGI',
      'date': '12 SEP 2026',
      'score': 91,
      'status': 'TERVERIFIKASI',
      'statusColor': AppTheme.stageKesimpulan,
      'accentColor': AppTheme.primaryTeal,
      'supervisor': 'dr. Bambang Irawan, Sp.A(K)',
      'progress': '6/6',
      'expanded': false,
    },
    {
      'id': '010',
      'title': 'Komunikasi dengan Keluarga Pasien Terminal',
      'department': 'KOMUNIKASI',
      'date': '09 SEP 2026',
      'score': 76,
      'status': 'MENUNGGU',
      'statusColor': AppTheme.stageEvaluasi,
      'accentColor': AppTheme.catKomunikasi,
      'supervisor': 'dr. Maria Angela, Sp.PD',
      'progress': '5/6',
      'expanded': false,
    },
    {
      'id': '009',
      'title': 'Tindakan Lumbal Pungsi Pertama',
      'department': 'NEUROLOGI',
      'date': '03 SEP 2026',
      'score': 88,
      'status': 'TERVERIFIKASI',
      'statusColor': AppTheme.stageKesimpulan,
      'accentColor': AppTheme.stageRencana,
      'supervisor': 'dr. Hendra Setiawan, Sp.N',
      'progress': '6/6',
      'expanded': false,
    },
    {
      'id': '008',
      'title': 'Manajemen Jalan Napas Pasien Obesitas',
      'department': 'ANESTESI',
      'date': '28 AGU 2026',
      'score': 79,
      'status': 'DRAFT',
      'statusColor': AppTheme.textMuted,
      'accentColor': AppTheme.stageEvaluasi,
      'supervisor': 'dr. Diana Putri, Sp.An',
      'progress': '4/6',
      'expanded': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.parchmentBg,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal)),
      );
    }

    final allItems = [
      ..._portfolioItems,
      ..._savedReflections.map((r) => {
        'id': r.id.length > 3 ? r.id.substring(r.id.length - 3) : r.id,
        'title': r.title,
        'department': r.department.toUpperCase(),
        'date': '${r.createdAt.day} ${_monthName(r.createdAt.month)} ${r.createdAt.year}',
        'score': 85,
        'status': 'TERVERIFIKASI',
        'statusColor': AppTheme.stageKesimpulan,
        'accentColor': AppTheme.primaryTeal,
        'supervisor': r.supervisorName.isNotEmpty ? r.supervisorName : 'Prof. Dr. Siti Rahayu, SpPD-KKV',
        'progress': '6/6',
        'expanded': false,
      }),
    ];

    // Filter items according to tab
    final displayedItems = allItems.where((item) {
      if (_selectedTab == 'SEMUA') return true;
      return item['status'] == _selectedTab;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.parchmentBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP HEADER (ARSIP REFLEKSI & SINKRON BUTTON)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ARSIP REFLEKSI',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'E-Portfolio',
                        style: GoogleFonts.newsreader(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textInk,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Menyinkronkan data dengan e-Portofolio Kampus... Selesai!')),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceWarm,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.lightBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.sync, size: 14, color: AppTheme.textInk),
                          const SizedBox(width: 6),
                          Text(
                            'SINKRON',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: AppTheme.textInk,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '12 LAPORAN TERSIMPAN',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 16),

              // 2. STATUS COUNTERS (03 TERVERIFIKASI | 01 MENUNGGU | 01 DRAFT)
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
                    _buildStatCol('03', 'TERVERIFIKASI', AppTheme.stageKesimpulan),
                    Container(width: 1, height: 38, color: const Color(0xFFE5DDD1)),
                    _buildStatCol('01', 'MENUNGGU', AppTheme.stageEvaluasi),
                    Container(width: 1, height: 38, color: const Color(0xFFE5DDD1)),
                    _buildStatCol('01', 'DRAFT', AppTheme.textMuted),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 3. FILTER TABS (SEMUA | TERVERIFIKASI | MENUNGGU | DRAFT)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['SEMUA', 'TERVERIFIKASI', 'MENUNGGU', 'DRAFT'].map((tab) {
                    final isActive = _selectedTab == tab;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTab = tab),
                      child: Container(
                        margin: const EdgeInsets.only(right: 18),
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
                          tab,
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
              ),
              const SizedBox(height: 20),

              // 4. LIST ITEMS
              Column(
                children: displayedItems.map((item) {
                  final isExpanded = item['expanded'] == true;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isExpanded ? AppTheme.surfaceWarm : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isExpanded ? Border.all(color: AppTheme.lightBorder) : null,
                    ),
                    padding: isExpanded ? const EdgeInsets.all(16) : const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row: Index, Title, Score, Status
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['id'] as String,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textLight,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Vertical accent bar
                            Container(
                              width: 3.5,
                              height: 38,
                              decoration: BoxDecoration(
                                color: item['accentColor'] as Color,
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
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textInk,
                                      height: 1.25,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item['department']} · ${item['date']}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.8,
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
                                  '${item['score']}',
                                  style: GoogleFonts.newsreader(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: item['accentColor'] as Color,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: item['statusColor'] as Color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      item['status'] as String,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                        color: item['statusColor'] as Color,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),

                        // If expanded, show progress bars, supervisor card, and action buttons
                        if (isExpanded) ...[
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Text(
                                'TAHAP GIBBS',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                  color: AppTheme.textLight,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Row(
                                  children: List.generate(6, (i) {
                                    return Expanded(
                                      child: Container(
                                        height: 5,
                                        margin: const EdgeInsets.symmetric(horizontal: 2),
                                        decoration: BoxDecoration(
                                          color: item['accentColor'] as Color,
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                item['progress'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textInk,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Supervisor Card
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.lightSurface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.lightBorder),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppTheme.parchmentBg,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.lightBorder),
                                  ),
                                  child: const Icon(Icons.person_outline, size: 18, color: AppTheme.primaryTeal),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SUPERVISOR',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.0,
                                        color: AppTheme.textLight,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item['supervisor'] as String,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textInk,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Action Buttons Row (LIHAT | EKSPOR PDF | SUNTING)
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 38,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryTeal,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                      final dummy = GibbsReflection(
                                        id: item['id'] as String,
                                        createdAt: DateTime.now(),
                                        title: item['title'] as String,
                                        department: item['department'] as String,
                                        supervisorName: item['supervisor'] as String,
                                        description: 'Pasien datang dengan tensi 190/110 mmHg di IGD.',
                                        feelings: 'Sempat merasa cemas namun berusaha tetap tenang sesuai protokol.',
                                        evaluation: 'Respon cepat pemberian antihipertensi parenteral berhasil menurunkan MAP secara aman.',
                                        analysis: 'Pentingnya monitoring ketat organ target pada krisis hipertensi.',
                                        conclusion: 'Kombinasi tim IGD dan pemahaman algoritma sangat krusial.',
                                        actionPlan: 'Akan membaca kembali konsensus PERKI tentang emergensi hipertensi.',
                                      );
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => GibbsReportScreen(reflection: dummy),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'LIHAT',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SizedBox(
                                  height: 38,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: AppTheme.surfaceWarm,
                                      side: const BorderSide(color: AppTheme.lightBorder),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                      final dummy = GibbsReflection(
                                        id: item['id'] as String,
                                        createdAt: DateTime.now(),
                                        title: item['title'] as String,
                                        department: item['department'] as String,
                                        supervisorName: item['supervisor'] as String,
                                      );
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PdfExportScreen(reflection: dummy),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'EKSPOR PDF',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                        color: AppTheme.textInk,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SizedBox(
                                  height: 38,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: AppTheme.surfaceWarm,
                                      side: const BorderSide(color: AppTheme.lightBorder),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Membuka mode sunting untuk ${item['title']}...')),
                                      );
                                    },
                                    child: Text(
                                      'SUNTING',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
                                        color: AppTheme.textInk,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCol(String count, String label, Color countColor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count,
            style: GoogleFonts.newsreader(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: countColor,
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

  String _monthName(int month) {
    const names = ['JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN', 'JUL', 'AGU', 'SEP', 'OKT', 'NOV', 'DES'];
    if (month >= 1 && month <= 12) return names[month - 1];
    return '';
  }
}
