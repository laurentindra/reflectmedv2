import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../models/gibbs_reflection.dart';
import '../services/gibbs_extractor_service.dart';
import '../services/storage_service.dart';
import '../widgets/depth_meter_widget.dart';
import '../widgets/smart_action_card.dart';
import 'pdf_export_screen.dart';
import 'eportfolio_sync_screen.dart';

class GibbsReportScreen extends StatefulWidget {
  final GibbsReflection reflection;

  const GibbsReportScreen({Key? key, required this.reflection}) : super(key: key);

  @override
  State<GibbsReportScreen> createState() => _GibbsReportScreenState();
}

class _GibbsReportScreenState extends State<GibbsReportScreen> {
  late GibbsReflection _reflection;

  @override
  void initState() {
    super.initState();
    _reflection = widget.reflection;
  }

  Future<void> _reanalyzeWithAi() async {
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
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryTeal,
                    strokeWidth: 3.5,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Menilai Ulang Refleksi (AI)',
                  style: GoogleFonts.newsreader(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textInk,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'AI sedang memperbarui skor kedalaman dan merevisi rekomendasi SMART Action Plan...',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final profile = await StorageService.loadProfile();
      final extractor = GibbsExtractorService(
        apiKey: profile.geminiApiKey,
        baseUrl: profile.apiBaseUrl,
        modelName: profile.geminiModelName,
      );

      final updated = await extractor.analyzeAndEnrichReflection(
        reflection: _reflection,
        profile: profile,
      );

      await StorageService.saveReflection(updated);

      if (mounted) {
        Navigator.pop(context); // Tutup dialog
        setState(() => _reflection = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.primaryTeal,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Skor kedalaman dan SMART Plan berhasil diperbarui oleh AI!',
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal evaluasi ulang: $e')),
        );
      }
    }
  }

  void _editSection(String title, String currentText, Function(String newText) onSave) {
    final controller = TextEditingController(text: currentText);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $title', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                onSave(controller.text);
              });
              await StorageService.saveReflection(_reflection);
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Refleksi Gibbs', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: AppTheme.accentAmber),
            tooltip: 'Evaluasi Ulang dengan AI',
            onPressed: _reanalyzeWithAi,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: AppTheme.primaryTeal),
            tooltip: 'Ekspor PDF',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PdfExportScreen(reflection: _reflection)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy_all_rounded, color: AppTheme.primaryTeal),
            tooltip: 'e-Portofolio 1-Click Sync',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EPortfolioSyncScreen(reflection: _reflection)),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KARTU HEADER REFLEKSI
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTeal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _reflection.department,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                        ),
                      ),
                      Text(
                        'Kelengkapan: ${_reflection.completionPercentage}%',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _reflection.title,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mahasiswa: ${_reflection.studentName} (${_reflection.studentId})',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  Text(
                    'DPJP / Pembimbing: ${_reflection.supervisorName}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // DEPTH METER WIDGET
            DepthMeterWidget(
              depth: _reflection.depthLevel,
              rationale: _reflection.depthRationale,
            ),
            const SizedBox(height: 16),

            // KEY TAKEAWAY CARD
            if (_reflection.keyTakeaway.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb, color: Color(0xFFD97706), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _reflection.keyTakeaway,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 18),

            const Text(
              'Enam Fase Siklus Gibbs (1988)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),

            // 6 GIBBS STAGES
            _buildGibbsTile(
              stepNumber: 1,
              title: '1. Description (Deskripsi Kejadian)',
              subtitle: 'Apa yang sebenarnya terjadi secara objektif?',
              content: _reflection.description,
              onEdit: () => _editSection('Deskripsi', _reflection.description, (val) => _reflection.description = val),
            ),
            _buildGibbsTile(
              stepNumber: 2,
              title: '2. Feelings (Perasaan & Reaksi Emosional)',
              subtitle: 'Apa yang kamu rasakan saat kejadian dan sesudahnya?',
              content: _reflection.feelings,
              onEdit: () => _editSection('Perasaan', _reflection.feelings, (val) => _reflection.feelings = val),
            ),
            _buildGibbsTile(
              stepNumber: 3,
              title: '3. Evaluation (Evaluasi)',
              subtitle: 'Apa aspek yang berjalan baik dan apa yang kurang baik?',
              content: _reflection.evaluation,
              onEdit: () => _editSection('Evaluasi', _reflection.evaluation, (val) => _reflection.evaluation = val),
            ),
            _buildGibbsTile(
              stepNumber: 4,
              title: '4. Analysis (Analisis Kritis)',
              subtitle: 'Mengapa hal itu terjadi? Apa keterkaitan faktor medis & manusia?',
              content: _reflection.analysis,
              onEdit: () => _editSection('Analisis', _reflection.analysis, (val) => _reflection.analysis = val),
            ),
            _buildGibbsTile(
              stepNumber: 5,
              title: '5. Conclusion (Kesimpulan)',
              subtitle: 'Apa pemahaman baru tentang dirimu dan situasi klinis?',
              content: _reflection.conclusion,
              onEdit: () => _editSection('Kesimpulan', _reflection.conclusion, (val) => _reflection.conclusion = val),
            ),
            _buildGibbsTile(
              stepNumber: 6,
              title: '6. Action Plan (Rencana Tindakan)',
              subtitle: 'Apa yang akan kamu lakukan berbeda di masa mendatang?',
              content: _reflection.actionPlan,
              onEdit: () => _editSection('Rencana Tindakan', _reflection.actionPlan, (val) => _reflection.actionPlan = val),
            ),

            const SizedBox(height: 16),

            // SMART ACTION CARD
            SmartActionCard(plan: _reflection.smartAction),

            const SizedBox(height: 24),

            // BOTTOM ACTION BUTTONS
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                    label: const Text('Ekspor PDF Laporan', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PdfExportScreen(reflection: _reflection)),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.darkSurface,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.copy_rounded, color: AppTheme.accentAmber),
                    label: const Text('Salin e-Portofolio', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EPortfolioSyncScreen(reflection: _reflection)),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGibbsTile({
    required int stepNumber,
    required String title,
    required String subtitle,
    required String content,
    required VoidCallback onEdit,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: CircleAvatar(
          radius: 14,
          backgroundColor: AppTheme.primaryTeal.withOpacity(0.12),
          child: Text(
            '$stepNumber',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
          ),
        ),
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
          onPressed: onEdit,
          tooltip: 'Edit Bagian Ini',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                content.isNotEmpty ? content : 'Belum terisi.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: content.isNotEmpty ? const Color(0xFF334155) : Colors.grey[400],
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
