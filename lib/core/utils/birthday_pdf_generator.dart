import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/dashboard/data/models/dashboard_models.dart';

class BirthdayPdfGenerator {
  static Future<void> generateAndSharePdf(BirthdayReportData data) async {
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
    final todayStr = _formatDate(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Reporte de Cumpleaños',
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
                        'Mes: ${data.monthName}',
                        style: const pw.TextStyle(
                          fontSize: 11,
                          color: PdfColor.fromInt(0xFF64748B),
                        ),
                      ),
                      pw.Text(
                        'Generado: $todayStr',
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
              pw.SizedBox(height: 20),
              if (data.birthdays.isEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 16),
                  child: pw.Text(
                    'No hay cumpleañeros registrados para ${data.monthName}.',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: const PdfColor.fromInt(0xFF334155),
                    ),
                  ),
                )
              else
                pw.TableHelper.fromTextArray(
                  headers: [
                    'Día',
                    'Nombre',
                    'Tipo',
                    'Fecha nacimiento',
                    'Detalle',
                  ],
                  data: data.birthdays.map((person) {
                    final dayStr = person.day != null
                        ? person.day.toString().padLeft(2, '0')
                        : '--';
                    return [
                      dayStr,
                      person.name,
                      person.type,
                      person.birthDay,
                      person.detail.isNotEmpty ? person.detail : '-',
                    ];
                  }).toList(),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 9,
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF6366F1),
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  cellPadding: const pw.EdgeInsets.all(6),
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
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'cumpleanos-${data.monthName.toLowerCase()}.pdf',
    );
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
