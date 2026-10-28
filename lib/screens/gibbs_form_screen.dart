import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../models/gibbs_reflection.dart';
import '../services/storage_service.dart';
import 'gibbs_report_screen.dart';
import 'main_navigation_scaffold.dart';

class GibbsFormScreen extends StatefulWidget {
  const GibbsFormScreen({Key? key}) : super(key: key);

  @override
  State<GibbsFormScreen> createState() => _GibbsFormScreenState();
}

class _GibbsFormScreenState extends State<GibbsFormScreen> {
  int _currentStep = 1; // 1 to 6
  final TextEditingController _titleController = TextEditingController(text: 'Penanganan STEMI Pertama di IGD');
  final TextEditingController _stageTextController = TextEditingController();

  final Map<int, String> _stageTexts = {
    1: 'Pada 14 September 2026, saya bertugas di IGD dan menerima pasien laki-laki 62 tahun dengan keluhan nyeri dada akut tipikal sejak 2 jam SMRS. EKG 12 sandapan menunjukkan elevasi segmen ST di sandapan V1-V4.',
    2: 'Saya merasakan campuran antara tegang, khawatir salah mendiagnosis, dan dorongan kuat untuk segera memulai reperfusi secepat mungkin demi keselamatan miokard pasien.',
    3: 'Hal yang berjalan baik adalah waktu door-to-ECG tercapai di bawah 8 menit dan loading dual antiplatelet langsung diberikan. Kekurangannya adalah keterlambatan dalam persiapan transfer kateterisasi.',
    4: 'Situasi ini membutuhkan koordinasi lintas tim gawat darurat yang sangat padat. Keterlambatan terjadi karena komunikasi telepon antar-ruangan yang tidak langsung terhubung.',
    5: 'Saya belajar bahwa protokol STEMI memerlukan kesiapan mental dan alur komunikasi standar SBAR yang rigid agar time-to-treatment tidak terbuang.',
    6: 'Saya akan meninjau ulang algoritma ACLS sindrom koroner akut dan berlatih simulasi eskalasi kasus darurat sebelum dinas jaga pekan depan.',
  };

  final List<Map<String, dynamic>> _stepMeta = [
    {
      'tag': 'Deskripsi',
      'q': 'Apa yang terjadi?',
      'guide': 'Jelaskan situasi secara objektif: apa yang terjadi, siapa yang terlibat, kapan dan di mana, serta konteks klinisnya.',
      'color': AppTheme.stageDeskripsi,
    },
    {
      'tag': 'Perasaan',
      'q': 'Apa yang Anda rasakan?',
      'guide': 'Gali respon emosional dan pikiran Anda saat peristiwa terjadi maupun sesudahnya secara jujur dan terbuka.',
      'color': AppTheme.stagePerasaan,
    },
    {
      'tag': 'Evaluasi',
      'q': 'Apa yang baik dan buruk?',
      'guide': 'Evaluasi apa yang berjalan lancar dalam penanganan, dan apa aspek yang dirasa kurang berhasil atau menantang.',
      'color': AppTheme.stageEvaluasi,
    },
    {
      'tag': 'Analisis',
      'q': 'Mengapa hal itu terjadi?',
      'guide': 'Analisis situasi lebih dalam: kaitkan dengan literatur kedokteran berbasis bukti, kerja tim, dan faktor pendukung.',
      'color': AppTheme.stageAnalisis,
    },
    {
      'tag': 'Kesimpulan',
      'q': 'Apa pelajaran bagi Anda?',
      'guide': 'Simpulkan apa yang seharusnya bisa dilakukan secara berbeda dan pelajaran penting bagi pertumbuhan profesional Anda.',
      'color': AppTheme.stageKesimpulan,
    },
    {
      'tag': 'Rencana Aksi',
      'q': 'Apa rencana tindak lanjut?',
      'guide': 'Rumuskan komitmen tindakan nyata terstruktur (SMART) jika Anda menghadapi skenario klinis serupa di masa depan.',
      'color': AppTheme.stageRencana,
    },
  ];

  @override
  void initState() {
    super.initState();
    _stageTextController.text = _stageTexts[_currentStep] ?? '';
  }

  void _switchStep(int step) {
    _stageTexts[_currentStep] = _stageTextController.text.trim();
    setState(() {
      _currentStep = step;
      _stageTextController.text = _stageTexts[step] ?? '';
    });
  }

  void _nextStep() async {
    _stageTexts[_currentStep] = _stageTextController.text.trim();
    if (_currentStep < 6) {
      _switchStep(_currentStep + 1);
    } else {
      // Save and generate report
      final profile = await StorageService.loadProfile();
      final reflection = GibbsReflection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        title: _titleController.text.trim(),
        studentName: profile.fullName.isNotEmpty ? profile.fullName : 'dr. Ahmad Fauzi',
        studentId: profile.studentId,
        department: profile.currentDepartment,
        hospital: profile.teachingHospital,
        supervisorName: profile.supervisorName.isNotEmpty ? profile.supervisorName : 'Prof. Dr. Siti Rahayu, SpPD-KKV',
        description: _stageTexts[1] ?? '',
        feelings: _stageTexts[2] ?? '',
        evaluation: _stageTexts[3] ?? '',
        analysis: _stageTexts[4] ?? '',
        conclusion: _stageTexts[5] ?? '',
        actionPlan: _stageTexts[6] ?? '',
      );

      await StorageService.saveReflection(reflection);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GibbsReportScreen(reflection: reflection),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMeta = _stepMeta[_currentStep - 1];
    final charCount = _stageTextController.text.length;

    return Scaffold(
      backgroundColor: AppTheme.parchmentBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP HEADER (FORMULIR REFLEKSI GIBBS & 01 / 06)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FORMULIR REFLEKSI GIBBS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  Text(
                    '0$_currentStep / 06',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: AppTheme.textInk,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 2. SIX CAPSULE DASHES PROGRESS BAR
              Row(
                children: List.generate(6, (index) {
                  final isActive = (index + 1) <= _currentStep;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _switchStep(index + 1),
                      child: Container(
                        height: 4.5,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.primaryTeal : const Color(0xFFDDD6CA),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 26),

              // 3. STEP EYEBROW & TITLE (Apa yang terjadi?)
              Text(
                'TAHAP $_currentStep · ${(currentMeta['tag'] as String).toUpperCase()}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: AppTheme.primaryTeal,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                currentMeta['q'] as String,
                style: GoogleFonts.newsreader(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textInk,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 24),

              // 4. JUDUL KEJADIAN KLINIS (Step 1 or persistent)
              if (_currentStep == 1) ...[
                Text(
                  'JUDUL KEJADIAN KLINIS',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWarm,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.lightBorder),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: TextField(
                    controller: _titleController,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textInk,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 5. EDITORIAL GUIDANCE CALLOUT (Left vertical teal line & italic serif)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      currentMeta['guide'] as String,
                      style: GoogleFonts.newsreader(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF33423F),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 6. TEXTAREA CONTAINER
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWarm,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.lightBorder),
                ),
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _stageTextController,
                  maxLines: 8,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    color: AppTheme.textInk,
                    height: 1.5,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Tuliskan refleksi Anda di sini...',
                    hintStyle: GoogleFonts.newsreader(
                      fontSize: 14.5,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textLight,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 14),

              // 7. ACTION STRIP (MINTA PANDUAN AI & 0 KARAKTER)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
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
                        const Icon(Icons.headphones_outlined, size: 16, color: AppTheme.primaryTeal),
                        const SizedBox(width: 6),
                        Text(
                          'MINTA PANDUAN REFLECTMED AI',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: AppTheme.primaryTeal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$charCount KARAKTER',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 8. NEXT BUTTON (Lanjutkan →)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8DFD3),
                    foregroundColor: AppTheme.textInk,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _nextStep,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentStep < 6 ? 'Lanjutkan' : 'Simpan & Buat Laporan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 16),
                    ],
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
