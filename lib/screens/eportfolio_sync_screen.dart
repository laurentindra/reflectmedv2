import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final Set<String> _expandedIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final list = await StorageService.loadReflections();
    if (mounted) {
      setState(() {
        _savedReflections = list;
        _isLoading = false;
        if (list.isNotEmpty) {
          _expandedIds.add(list.first.id);
        }
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

    final List<Map<String, dynamic>> items = [];

    if (_savedReflections.isNotEmpty) {
      for (int i = 0; i < _savedReflections.length; i++) {
        final r = _savedReflections[i];
        int filled = 0;
        if (r.description.trim().isNotEmpty) filled++;
        if (r.feelings.trim().isNotEmpty) filled++;
        if (r.evaluation.trim().isNotEmpty) filled++;
        if (r.analysis.trim().isNotEmpty) filled++;
        if (r.conclusion.trim().isNotEmpty) filled++;
        if (r.actionPlan.trim().isNotEmpty) filled++;

        final isVerif = filled >= 5;
        final status = isVerif ? 'TERVERIFIKASI' : (filled > 2 ? 'MENUNGGU' : 'DRAFT');
        final statusColor = isVerif
            ? AppTheme.stageKesimpulan
            : (filled > 2 ? AppTheme.stageEvaluasi : AppTheme.textMuted);

        final colors = [
          AppTheme.catKardiologi,
          AppTheme.primaryTeal,
          AppTheme.catKomunikasi,
          AppTheme.catRespirasi,
        ];

        items.add({
          'id': '00${i + 1}',
          'reflectionId': r.id,
          'title': r.title,
          'department': r.department.toUpperCase(),
          'date': '${r.createdAt.day} ${_monthName(r.createdAt.month)} ${r.createdAt.year}',
          'score': r.completionPercentage,
          'status': status,
          'statusColor': statusColor,
          'accentColor': colors[i % colors.length],
          'supervisor': r.supervisorName.isNotEmpty ? r.supervisorName : 'dr. DPJP Pembimbing',
          'progress': '$filled/6',
          'reflection': r,
        });
      }
    } else {
      // Data starter jika belum ada refleksi tersimpan
      items.addAll([
        {
          'id': '012',
          'reflectionId': 'sample-1',
          'title': 'Penanganan Pasien Hipertensi Krisis',
          'department': 'KARDIOLOGI',
          'date': '15 SEP 2026',
          'score': 82,
          'status': 'TERVERIFIKASI',
          'statusColor': AppTheme.stageKesimpulan,
          'accentColor': AppTheme.catKardiologi,
          'supervisor': 'Prof. Dr. Siti Rahayu, SpPD-KKV',
          'progress': '6/6',
          'reflection': GibbsReflection(
            id: 'sample-1',
            createdAt: DateTime.now(),
            title: 'Penanganan Pasien Hipertensi Krisis',
            department: 'KARDIOLOGI',
            supervisorName: 'Prof. Dr. Siti Rahayu, SpPD-KKV',
            description: 'Menerima pasien laki-laki 58 tahun dengan TD 210/120 mmHg di IGD.',
            feelings: 'Khawatir terjadi target organ damage namun fokus melakukan stabilisasi.',
            evaluation: 'Penurunan MAP bertahap berhasil, namun komunikasi ke keluarga terlambat.',
            analysis: 'Emergensi hipertensi memerlukan penanganan cepat sesuai pedoman JNC/PERKI.',
            conclusion: 'Kombinasi tim IGD dan pemahaman algoritma sangat krusial.',
            actionPlan: 'Membaca kembali konsensus PERKI dan berlatih simulasi kasus darurat.',
          ),
        },
      ]);
    }

    // Hitung counter status
    int countVerif = 0;
    int countWait = 0;
    int countDraft = 0;
    for (final it in items) {
      final st = it['status'] as String;
      if (st == 'TERVERIFIKASI') countVerif++;
      if (st == 'MENUNGGU') countWait++;
      if (st == 'DRAFT') countDraft++;
    }

    final filteredItems = items.where((it) {
      if (_selectedTab == 'SEMUA') return true;
      return it['status'] == _selectedTab;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.parchmentBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP HEADER (PORTFOLIO & Sync Status)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'E-PORTOFOLIO KLINIS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      _loadData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppTheme.primaryTeal,
                          content: Text('Portofolio berhasil disinkronkan dengan basis data lokal!'),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceWarm,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.lightBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sync, size: 14, color: AppTheme.primaryTeal),
                          const SizedBox(width: 5),
                          Text(
                            'SINKRONKAN',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
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
                '${items.length} LAPORAN TERSIMPAN',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 16),

              // 2. STATUS COUNTERS
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
                      countVerif < 10 ? '0$countVerif' : '$countVerif',
                      'TERVERIFIKASI',
                      AppTheme.stageKesimpulan,
                    ),
                    Container(width: 1, height: 38, color: const Color(0xFFE5DDD1)),
                    _buildStatCol(
                      countWait < 10 ? '0$countWait' : '$countWait',
                      'MENUNGGU',
                      AppTheme.stageEvaluasi,
                    ),
                    Container(width: 1, height: 38, color: const Color(0xFFE5DDD1)),
                    _buildStatCol(
                      countDraft < 10 ? '0$countDraft' : '$countDraft',
                      'DRAFT',
                      AppTheme.textMuted,
                    ),
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
                children: filteredItems.map((item) {
                  final refId = item['reflectionId'] as String;
                  final isExpanded = _expandedIds.contains(refId);
                  final ref = item['reflection'] as GibbsReflection;

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
                        // Row: Header
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (isExpanded) {
                                _expandedIds.remove(refId);
                              } else {
                                _expandedIds.add(refId);
                              }
                            });
                          },
                          child: Row(
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
                        ),

                        // Jika Expanded: Tampilkan 6 Fase Gibbs, Pembimbing, dan Tombol Tindakan
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
                                      'SUPERVISOR / DPJP',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.0,
                                        color: AppTheme.textLight,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item['supervisor'] as String,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textInk,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Action Buttons
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
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => GibbsReportScreen(reflection: ref),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'LIHAT LAPORAN',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.6,
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
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PdfExportScreen(reflection: ref),
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
                              SizedBox(
                                height: 38,
                                width: 42,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    backgroundColor: AppTheme.surfaceWarm,
                                    side: const BorderSide(color: AppTheme.lightBorder),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () {
                                    final textToCopy = '''
LAPORAN REFLEKSI KLINIS GIBBS
Judul: ${ref.title}
Stase: ${ref.department} | Mahasiswa: ${ref.studentName} (${ref.studentId})
DPJP: ${ref.supervisorName}
Tanggal: ${ref.createdAt.day}/${ref.createdAt.month}/${ref.createdAt.year}

1. DESKRIPSI:
${ref.description}

2. PERASAAN:
${ref.feelings}

3. EVALUASI:
${ref.evaluation}

4. ANALISIS:
${ref.analysis}

5. KESIMPULAN:
${ref.conclusion}

6. RENCANA AKSI (SMART PLAN):
${ref.actionPlan}
Specific: ${ref.smartAction.specific}
Measurable: ${ref.smartAction.measurable}
Time-Bound: ${ref.smartAction.timeBound}

Tingkat Kedalaman: ${ref.depthLabel}
Key Takeaway: ${ref.keyTakeaway}
''';
                                    Clipboard.setData(ClipboardData(text: textToCopy));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        backgroundColor: AppTheme.primaryTeal,
                                        behavior: SnackBarBehavior.floating,
                                        content: Text('Teks refleksi Gibbs berhasil disalin untuk di-upload ke LMS Kampus!'),
                                      ),
                                    );
                                  },
                                  child: const Icon(Icons.copy_rounded, size: 17, color: AppTheme.textInk),
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
