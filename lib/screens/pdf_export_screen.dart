import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/gibbs_reflection.dart';
import '../services/pdf_generator_service.dart';

class PdfExportScreen extends StatelessWidget {
  final GibbsReflection reflection;

  const PdfExportScreen({Key? key, required this.reflection}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pratinjau PDF Laporan', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
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
        pdfFileName: 'Refleksi_Klinis_${reflection.studentId}_${reflection.department}.pdf',
      ),
    );
  }
}
