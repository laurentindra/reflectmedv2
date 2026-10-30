import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import '../core/theme/app_theme.dart';
import '../models/gibbs_reflection.dart';
import '../services/pdf_generator_service.dart';

class PdfExportScreen extends StatelessWidget {
  final GibbsReflection reflection;

  const PdfExportScreen({Key? key, required this.reflection}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cleanId = reflection.studentId.replaceAll(RegExp(r'[^\w]'), '_');
    final cleanDept = reflection.department.replaceAll(RegExp(r'[^\w]'), '_');
    final fileName = 'Refleksi_Klinis_${cleanId.isNotEmpty ? cleanId : "Mhs"}_${cleanDept.isNotEmpty ? cleanDept : "Stase"}.pdf';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pratinjau PDF Laporan',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppTheme.textInk,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppTheme.primaryTeal),
            tooltip: 'Bagikan / Unduh PDF',
            onPressed: () => PdfGeneratorService.printOrSharePdf(reflection),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => PdfGeneratorService.generateReflectionPdf(reflection),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        previewPageMargin: const EdgeInsets.all(12),
        pdfFileName: fileName,
        loadingWidget: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryTeal),
              SizedBox(height: 12),
              Text('Menyiapkan format dokumen AMEE 44...'),
            ],
          ),
        ),
        onError: (context, error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  'Gagal memuat pratinjau PDF',
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
