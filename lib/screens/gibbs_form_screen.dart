import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../models/gibbs_reflection.dart';
import '../models/student_profile.dart';
import '../services/gibbs_extractor_service.dart';
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

  StudentProfile _profile = StudentProfile();
  bool _isAiReviewing = false;
  String? _currentStageAiFeedback;

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
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final p = await StorageService.loadProfile();
    if (mounted) setState(() => _profile = p);
  }

  void _switchStep(int step) {
    _stageTexts[_currentStep] = _stageTextController.text.trim();
    setState(() {
      _currentStep = step;
      _currentStageAiFeedback = null;
      _isAiReviewing = false;
      _stageTextController.text = _stageTexts[step] ?? '';
    });
  }

  Future<void> _requestAiFeedback() async {
    final currentText = _stageTextController.text.trim();
    if (currentText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.primaryTeal,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Tuliskan draf pemikiran Anda terlebih dahulu agar AI Mentor dapat memberikan masukan.',
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isAiReviewing = true;
      _currentStageAiFeedback = null;
    });

    try {
      final currentMeta = _stepMeta[_currentStep - 1];
      final extractor = GibbsExtractorService(
        apiKey: _profile.geminiApiKey,
        baseUrl: _profile.apiBaseUrl,
        modelName: _profile.geminiModelName,
      );

      final feedback = await extractor.getStageFeedback(
        stageIndex: _currentStep,
        stageTitle: currentMeta['tag'] as String,
        currentText: currentText,
        profile: _profile,
      );

      if (mounted) {
        setState(() {
          _currentStageAiFeedback = feedback;
          _isAiReviewing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAiReviewing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Umpan balik AI: $e')),
        );
      }
    }
  }

  void _nextStep() async {
    _stageTexts[_currentStep] = _stageTextController.text.trim();
    if (_currentStep < 6) {
      _switchStep(_currentStep + 1);
    } else {
      // Save and enrich report with AI
      final profile = await StorageService.loadProfile();
      final reflection = GibbsReflection(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        title: _titleController.text.trim().isNotEmpty
            ? _titleController.text.trim()
            : 'Refleksi Kasus: ${profile.currentDepartment}',
        studentName: profile.fullName.isNotEmpty ? profile.fullName : 'dr. Mahasiswa Kedokteran',
        studentId: profile.studentId,
        department: profile.currentDepartment,
        hospital: profile.teachingHospital,
        supervisorName: profile.supervisorName.isNotEmpty ? profile.supervisorName : 'dr. DPJP, Sp.PD',
        description: _stageTexts[1] ?? '',
        feelings: _stageTexts[2] ?? '',
        evaluation: _stageTexts[3] ?? '',
        analysis: _stageTexts[4] ?? '',
        conclusion: _stageTexts[5] ?? '',
        actionPlan: _stageTexts[6] ?? '',
      );

      // Tampilkan progress dialog bahwa AI sedang menganalisis
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: AppTheme.surfaceWarm,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryTeal,
                      strokeWidth: 3.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Menilai Refleksi Klinis',
                    style: GoogleFonts.newsreader(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textInk,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI sedang menganalisis kedalaman refleksi (Depth Meter) dan merumuskan SMART Action Plan...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      height: 1.45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final extractor = GibbsExtractorService(
        apiKey: profile.geminiApiKey,
        baseUrl: profile.apiBaseUrl,
        modelName: profile.geminiModelName,
      );

      final enriched = await extractor.analyzeAndEnrichReflection(
        reflection: reflection,
        profile: profile,
      );

      await StorageService.saveReflection(enriched);

      if (!mounted) return;
      Navigator.pop(context); // Tutup dialog

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GibbsReportScreen(reflection: enriched),
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

              // 7. ACTION STRIP & AI FEEDBACK
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: _isAiReviewing ? null : _requestAiFeedback,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isAiReviewing)
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryTeal),
                            )
                          else
                            const Icon(Icons.auto_awesome, size: 14, color: AppTheme.primaryTeal),
                          const SizedBox(width: 6),
                          Text(
                            _isAiReviewing ? 'MENILAI DRAF...' : 'TINJAU DENGAN AI MENTOR',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: AppTheme.primaryTeal,
                            ),
                          ),
                        ],
                      ),
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
              const SizedBox(height: 12),

              // Kotak Umpan Balik AI jika ada masukan
              if (_currentStageAiFeedback != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EFE6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD6C8B5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.psychology_outlined, color: AppTheme.primaryTeal, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Masukan dr. Mentor (AMEE Guide 44)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryTeal,
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () => setState(() => _currentStageAiFeedback = null),
                            child: const Icon(Icons.close, size: 16, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentStageAiFeedback!,
                        style: GoogleFonts.newsreader(
                          fontSize: 13.5,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.textInk,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Opsi beralih ke Chatbot interaktif
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppTheme.textMuted),
                  label: Text(
                    'Ingin berdialog langsung? Buka Chatbot dr. Mentor',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
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
              ),
              const SizedBox(height: 12),

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
