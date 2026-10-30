import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/gibbs_reflection.dart';

class PdfGeneratorService {
  /// Bersihkan teks dari emoji dan karakter khusus yang tidak didukung font PDF
  static String _sanitize(String? text) {
    if (text == null || text.isEmpty) return '';
    // Hapus karakter emoji & simbol non-BMP yang memicu crash pada engine PDF
    String clean = text.replaceAll(
      RegExp(r'[\u{1F300}-\u{1F9FF}|\u{2600}-\u{27BF}]', unicode: true),
      '',
    );
    // Ganti karakter tipografi non-standar ke bentuk ASCII aman
    clean = clean
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'")
        .replaceAll('•', '-')
        .replaceAll('…', '...');
    return clean.trim();
  }

  /// Menghasilkan berkas PDF Laporan Refleksi Klinis Mahasiswa berstandar akademik AMEE 44
  static Future<Uint8List> generateReflectionPdf(GibbsReflection reflection) async {
    // 1. Inisialisasi locale tanggal Indonesia
    try {
      await initializeDateFormatting('id_ID', null);
    } catch (_) {}

    DateFormat dateFormat;
    try {
      dateFormat = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID');
    } catch (_) {
      dateFormat = DateFormat('dd/MM/yyyy, HH:mm');
    }

    // 2. Load Google Fonts untuk rendering TrueType Unicode yang tajam
    pw.Font? ttfRegular;
    pw.Font? ttfBold;
    try {
      ttfRegular = await PdfGoogleFonts.openSansRegular();
      ttfBold = await PdfGoogleFonts.openSansBold();
    } catch (e) {
      debugPrint('PdfGoogleFonts load fallback to standard font: $e');
    }

    final theme = ttfRegular != null && ttfBold != null
        ? pw.ThemeData.withFont(
            base: ttfRegular,
            bold: ttfBold,
          )
        : null;

    final pdf = pw.Document(theme: theme);

    final primaryColor = PdfColor.fromHex('0D9488'); // Deep Teal
    final darkNavy = PdfColor.fromHex('0F172A');
    final subtleGrey = PdfColor.fromHex('F8FAFC');
    final borderGrey = PdfColor.fromHex('E2E8F0');

    final cleanTitle = _sanitize(reflection.title);
    final cleanStudentName = _sanitize(reflection.studentName);
    final cleanStudentId = _sanitize(reflection.studentId);
    final cleanDept = _sanitize(reflection.department);
    final cleanHospital = _sanitize(reflection.hospital);
    final cleanSupervisor = _sanitize(reflection.supervisorName);
    final cleanDepthLabel = _sanitize(reflection.depthLabel);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // HEADER DOKUMEN RESMI
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 12),
              decoration: pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: primaryColor, width: 2.5)),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'REFLECTMED AI · CLINICAL PORTFOLIO',
                        style: pw.TextStyle(
                          color: primaryColor,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'LAPORAN REFLEKSI KLINIS MAHASISWA',
                        style: pw.TextStyle(
                          color: darkNavy,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Berdasarkan Kerangka Gibbs Reflective Cycle (1988) & AMEE Guide No. 44',
                        style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 8.5),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: subtleGrey,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: borderGrey),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Status: Siap Asesmen',
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                        pw.Text(dateFormat.format(reflection.createdAt),
                            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // TABEL IDENTITAS MAHASISWA & STASE KLINIS
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: subtleGrey,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: borderGrey),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('Nama Mahasiswa', cleanStudentName.isNotEmpty ? cleanStudentName : 'dr. Muda / Mahasiswa'),
                        _buildInfoRow('NIM / Stambuk', cleanStudentId.isNotEmpty ? cleanStudentId : '-'),
                        _buildInfoRow('Departemen / Stase', cleanDept.isNotEmpty ? cleanDept : 'Stase Klinis'),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('RS Pendidikan', cleanHospital.isNotEmpty ? cleanHospital : 'RS Pendidikan'),
                        _buildInfoRow('DPJP / Preseptor', cleanSupervisor.isNotEmpty ? cleanSupervisor : 'Dokter Penanggung Jawab'),
                        _buildInfoRow('Tingkat Kedalaman', cleanDepthLabel.isNotEmpty ? cleanDepthLabel : 'Analytical'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // JUDUL KASUS REFLEKSI
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('F0FDFA'),
                border: pw.Border.all(color: primaryColor, width: 0.8),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                'Topik / Kasus: ${cleanTitle.isNotEmpty ? cleanTitle : "Refleksi Klinis Gibbs"}',
                style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: primaryColor),
              ),
            ),
            pw.SizedBox(height: 12),

            // 6 FASE SIKLUS GIBBS
            _buildGibbsSection(1, 'Description (Apa yang terjadi?)', _sanitize(reflection.description), primaryColor),
            _buildGibbsSection(2, 'Feelings (Apa yang dirasakan?)', _sanitize(reflection.feelings), primaryColor),
            _buildGibbsSection(3, 'Evaluation (Evaluasi: Baik vs Kurang Baik)', _sanitize(reflection.evaluation), primaryColor),
            _buildGibbsSection(4, 'Analysis (Analisis Mendalam: Mengapa terjadi?)', _sanitize(reflection.analysis), primaryColor),
            _buildGibbsSection(5, 'Conclusion (Kesimpulan & Pembelajaran Diri)', _sanitize(reflection.conclusion), primaryColor),
            _buildGibbsSection(6, 'Action Plan (Rencana Tindakan Berkelanjutan)', _sanitize(reflection.actionPlan), primaryColor),

            pw.SizedBox(height: 8),

            // TABEL SMART ACTION PLAN
            pw.Text(
              'KOMITMEN RENCANA AKSI (SMART CRITERIA):',
              style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: darkNavy),
            ),
            pw.SizedBox(height: 5),
            pw.Table(
              border: pw.TableBorder.all(color: borderGrey, width: 0.5),
              children: [
                _buildSmartTableRow('S - Specific (Spesifik)', _sanitize(reflection.smartAction.specific)),
                _buildSmartTableRow('M - Measurable (Terukur)', _sanitize(reflection.smartAction.measurable)),
                _buildSmartTableRow('A - Achievable (Dapat Dicapai)', _sanitize(reflection.smartAction.achievable)),
                _buildSmartTableRow('R - Relevant (Relevan)', _sanitize(reflection.smartAction.relevant)),
                _buildSmartTableRow('T - Time-Bound (Batas Waktu)', _sanitize(reflection.smartAction.timeBound)),
              ],
            ),
            pw.SizedBox(height: 16),

            // LEMBAR PENGESAHAN PRESEPTOR / DPJP
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Mahasiswa Kedokteran,', style: const pw.TextStyle(fontSize: 8.5)),
                    pw.SizedBox(height: 32),
                    pw.Text('(${cleanStudentName.isNotEmpty ? cleanStudentName : "Mahasiswa"})',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                    pw.Text('NIM: ${cleanStudentId.isNotEmpty ? cleanStudentId : "-"}',
                        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Mengetahui / Verifikasi DPJP,', style: const pw.TextStyle(fontSize: 8.5)),
                    pw.SizedBox(height: 32),
                    pw.Text('(${cleanSupervisor.isNotEmpty ? cleanSupervisor : "dr. Pembimbing Klinik"})',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                    pw.Text('NIP/SIP: .......................................',
                        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 95,
            child: pw.Text('$label:', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 8, color: PdfColors.black)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildGibbsSection(int step, String title, String content, PdfColor primaryColor) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 7),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColor.fromHex('E2E8F0')),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 14,
                height: 14,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Text('$step', style: const pw.TextStyle(color: PdfColors.white, fontSize: 8)),
              ),
              pw.SizedBox(width: 6),
              pw.Text(title, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: primaryColor)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            content.isNotEmpty ? content : 'Belum diisi.',
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey900, lineSpacing: 1.3),
          ),
        ],
      ),
    );
  }

  static pw.TableRow _buildSmartTableRow(String criteria, String details) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(4.5),
          child: pw.Text(criteria, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4.5),
          child: pw.Text(details.isNotEmpty ? details : '-', style: const pw.TextStyle(fontSize: 7.5)),
        ),
      ],
    );
  }

  /// Menampilkan lembar cetak / unduh langsung di Flutter
  static Future<void> printOrSharePdf(GibbsReflection reflection) async {
    final pdfBytes = await generateReflectionPdf(reflection);
    final cleanId = _sanitize(reflection.studentId).replaceAll(RegExp(r'[^\w]'), '_');
    final cleanDept = _sanitize(reflection.department).replaceAll(RegExp(r'[^\w]'), '_');
    final fileName = 'Refleksi_Klinis_${cleanId.isNotEmpty ? cleanId : "Mhs"}_${cleanDept.isNotEmpty ? cleanDept : "Stase"}.pdf';

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: fileName,
    );
  }
}
