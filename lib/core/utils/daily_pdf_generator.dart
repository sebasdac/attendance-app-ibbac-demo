import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DailyReportData {
  final DateTime date;
  final int amKids;
  final int amAdults;
  final int pmKids;
  final int pmAdults;

  int get totalAM => amKids + amAdults;
  int get totalPM => pmKids + pmAdults;
  int get totalDay => totalAM + totalPM;

  DailyReportData({
    required this.date,
    required this.amKids,
    required this.amAdults,
    required this.pmKids,
    required this.pmAdults,
  });
}

class DailyPdfGenerator {
  static Future<void> generateAndSharePdf(DailyReportData data) async {
    final fontBase = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    pw.ImageProvider? logoImage;
    try {
      final logoData = await rootBundle.load('assets/icon.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {
      logoImage = null;
    }

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: fontBase, bold: fontBold),
    );

    final dateStr =
        '${data.date.day.toString().padLeft(2, '0')}/${data.date.month.toString().padLeft(2, '0')}/${data.date.year}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Reporte Diario de Asistencia',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF4F46E5),
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Iglesia Bíblica Bautista Agua Caliente',
                        style: const pw.TextStyle(
                          fontSize: 11,
                          color: PdfColor.fromInt(0xFF64748B),
                        ),
                      ),
                      pw.Text(
                        'Fecha: $dateStr',
                        style: const pw.TextStyle(
                          fontSize: 11,
                          color: PdfColor.fromInt(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  if (logoImage != null)
                    pw.Container(
                      width: 50,
                      height: 50,
                      child: pw.Image(logoImage),
                    ),
                ],
              ),
              pw.SizedBox(height: 24),

              // Total Summary Banner
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFEEF2FF),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'TOTAL DEL DÍA',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF4338CA),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '${data.totalDay}',
                      style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF4F46E5),
                      ),
                    ),
                    pw.Text(
                      'personas asistieron en total',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColor.fromInt(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Table Summary
              pw.TableHelper.fromTextArray(
                headers: ['Sesión', 'Niños', 'Adultos', 'Total Sesión'],
                data: [
                  [
                    '🌅 Mañana (AM)',
                    '${data.amKids}',
                    '${data.amAdults}',
                    '${data.totalAM}',
                  ],
                  [
                    '🌆 Tarde (PM)',
                    '${data.pmKids}',
                    '${data.pmAdults}',
                    '${data.totalPM}',
                  ],
                  [
                    'TOTAL GENERAL',
                    '${data.amKids + data.pmKids}',
                    '${data.amAdults + data.pmAdults}',
                    '${data.totalDay}',
                  ],
                ],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 10,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF6366F1),
                ),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(
                      color: PdfColor.fromInt(0xFFE2E8F0),
                      width: 0.5,
                    ),
                  ),
                ),
                oddRowDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFF8FAFC),
                ),
              ),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    final sanitizedDate = dateStr.replaceAll('/', '-');
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'asistencia-diaria-$sanitizedDate.pdf',
    );
  }
}
