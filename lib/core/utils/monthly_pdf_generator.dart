import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/kids/data/models/monthly_attendance_models.dart';

class MonthlyPdfGenerator {
  static Future<void> generateAndSharePdf(MonthlyReportData report) async {
    final fontBase = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: fontBase, bold: fontBold),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Reporte Mensual de Asistencia Kids',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF6366F1),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Clase: ${report.selectedClass} | Mes: ${report.selectedMonth} ${report.year}',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColor.fromInt(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                pw.Text(
                  'IBBAC',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFF4F46E5),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Divider(color: const PdfColor.fromInt(0xFFCBD5E1)),
            pw.SizedBox(height: 16),

            // Summary Stats Cards
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildPdfStatBox(
                  'Total Asistencia',
                  '${report.totalAttendance}',
                  const PdfColor.fromInt(0xFF6366F1),
                ),
                _buildPdfStatBox(
                  'Promedio por Domingo',
                  report.averagePerSunday.toStringAsFixed(1),
                  const PdfColor.fromInt(0xFFF59E0B),
                ),
                _buildPdfStatBox(
                  'Total Domingos',
                  '${report.totalSundays}',
                  const PdfColor.fromInt(0xFF10B981),
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            // Weekly Stats Table
            pw.Text(
              'Desglose por Domingo',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: const PdfColor.fromInt(0xFF1E293B),
              ),
            ),
            pw.SizedBox(height: 8),

            pw.TableHelper.fromTextArray(
              headers: ['Fecha', 'Mañana (AM)', 'Tarde (PM)', 'Total Domingo'],
              data: report.weeklyStats.map((s) {
                return [
                  s.dateStr,
                  '${s.amCount}',
                  '${s.pmCount}',
                  '${s.totalCount}',
                ];
              }).toList(),
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
                horizontal: 10,
                vertical: 6,
              ),
            ),

            pw.SizedBox(height: 24),

            // Top Attendees Table
            pw.Text(
              'Top Asistencia de Niños',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: const PdfColor.fromInt(0xFF1E293B),
              ),
            ),
            pw.SizedBox(height: 8),

            pw.TableHelper.fromTextArray(
              headers: [
                'Nombre del Niño',
                'Domingos Asistidos',
                'Porcentaje %',
              ],
              data: report.topAttendees.map((k) {
                return [
                  k.kidName,
                  '${k.attendedSundays} de ${k.totalSundays}',
                  '${k.percentage.toStringAsFixed(0)}%',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 10,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF10B981),
              ),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'reporte-mensual-${report.selectedClass.replaceAll(" ", "_")}-${report.selectedMonth}.pdf',
    );
  }

  static pw.Widget _buildPdfStatBox(
    String title,
    String value,
    PdfColor color,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF8FAFC),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE2E8F0)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            title,
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromInt(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class SundayTemplatePdfGenerator {
  static List<DateTime> _getSundaysInMonth(String monthName, int year) {
    const monthsMap = {
      'Enero': 1,
      'Febrero': 2,
      'Marzo': 3,
      'Abril': 4,
      'Mayo': 5,
      'Junio': 6,
      'Julio': 7,
      'Agosto': 8,
      'Septiembre': 9,
      'Octubre': 10,
      'Noviembre': 11,
      'Diciembre': 12,
    };

    final monthInt = monthsMap[monthName] ?? DateTime.now().month;
    final totalDaysInMonth = DateTime(year, monthInt + 1, 0).day;
    final List<DateTime> sundays = [];

    for (int day = 1; day <= totalDaysInMonth; day++) {
      final date = DateTime(year, monthInt, day);
      if (date.weekday == DateTime.sunday) {
        sundays.add(date);
      }
    }

    return sundays;
  }

  // Load Bible PNG Image Asset safely
  static Future<pw.MemoryImage?> _loadBibleAssetImage() async {
    try {
      final data = await rootBundle.load('assets/bible_postal.jpg');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  // Cell Placeholder for Wall Poster Table (Page 1) - Spacious Receiving Box
  static pw.Widget _buildPosterCellPlaceholder(pw.MemoryImage? bibleImage) {
    return pw.Container(
      width: 74,
      height: 48,
      padding: const pw.EdgeInsets.all(2),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF0FDF4), // Soft Mint Green
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(
          color: const PdfColor.fromInt(0xFF86EFAC), // Mint Border
          width: 1,
          style: pw.BorderStyle.dashed,
        ),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          if (bibleImage != null)
            pw.Image(bibleImage, width: 22, height: 22)
          else
            pw.Text('📖', style: const pw.TextStyle(fontSize: 12)),
          pw.SizedBox(height: 1),
          pw.Text(
            'PEGAR AQUÍ',
            style: pw.TextStyle(
              fontSize: 5.5,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF166534),
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Cheerful Tightly-Cropped Cut-Out Postal Card (Page 2)
  // Compact 62x42 pt card that fits easily inside the 74x48 pt table cell box on Page 1
  static pw.Widget _buildCutOutBiblePostalCard({
    required pw.MemoryImage? bibleImage,
    required String kidName,
    required String dateStr,
  }) {
    return pw.Container(
      width: 62,
      height: 42,
      padding: const pw.EdgeInsets.all(1.5),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFFFDF5), // Warm Soft Cream
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(
          color: const PdfColor.fromInt(0xFFF59E0B), // Amber Scissor Line
          width: 0.8,
          style: pw.BorderStyle.dashed,
        ),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            '- RECORTAR -',
            style: const pw.TextStyle(
              fontSize: 4.5,
              color: PdfColor.fromInt(0xFF94A3B8),
            ),
          ),
          if (bibleImage != null)
            pw.Image(bibleImage, width: 26, height: 26)
          else
            pw.Container(
              width: 24,
              height: 24,
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFF0284C7),
                borderRadius: pw.BorderRadius.circular(3),
              ),
              child: pw.Center(
                child: pw.Text(
                  'BIBLIA',
                  style: pw.TextStyle(
                    fontSize: 6,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Flexible(
                child: pw.Text(
                  kidName,
                  style: pw.TextStyle(
                    fontSize: 5.5,
                    fontWeight: pw.FontWeight.bold,
                    color: const PdfColor.fromInt(0xFF1E1B4B),
                  ),
                  maxLines: 1,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Text(
                ' • $dateStr',
                style: const pw.TextStyle(
                  fontSize: 4.5,
                  color: PdfColor.fromInt(0xFFD97706),
                ),
                maxLines: 1,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<void> generateAndShareTemplate({
    required String className,
    required String monthName,
    required int year,
    required String session, // 'AM' or 'PM'
    required List<String> studentNames,
  }) async {
    final fontBase = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final bibleImage = await _loadBibleAssetImage();

    final sundays = _getSundaysInMonth(monthName, year);
    final sessionLabel = session.toUpperCase() == 'AM'
        ? 'Mañana (AM)'
        : 'Tarde (PM)';
    final totalKids = studentNames.length;
    final totalSundays = sundays.length;
    final totalPostales = totalKids * totalSundays;

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: fontBase, bold: fontBold),
    );

    // ================= PAGE 1: CHEERFUL WALL POSTER FOR CLASSROOM =================
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            // Cheerful Sky Blue Wall Poster Title Banner
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFF0284C7), // Vibrant Sky Blue
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'TABLA DE ASISTENCIA Y BIBLIAS - IBBAC KIDS',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Clase: $className  •  Mes: $monthName $year  •  Sesión: $sessionLabel',
                        style: const pw.TextStyle(
                          fontSize: 10.5,
                          color: PdfColor.fromInt(0xFFE0F2FE),
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFFEF08A), // Sun Yellow
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      'PÓSTER DE PARED',
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF854D0E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // Custom Table with Cute Bible Placeholders
            pw.Table(
              border: pw.TableBorder.all(
                color: const PdfColor.fromInt(0xFFBAE6FD), // Soft Sky Border
                width: 1,
              ),
              columnWidths: {
                0: const pw.FixedColumnWidth(24),
                1: const pw.FlexColumnWidth(2.5),
                ...Map.fromEntries(
                  List.generate(
                    sundays.length,
                    (i) => MapEntry(i + 2, const pw.FlexColumnWidth(1.8)),
                  ),
                ),
                sundays.length + 2: const pw.FixedColumnWidth(58),
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF4F46E5), // Indigo Header
                  ),
                  children: [
                    _buildHeaderCell('#'),
                    _buildHeaderCell('Nombre del Niño / Niña', alignLeft: true),
                    ...sundays.map(
                      (s) => _buildHeaderCell('Dom ${s.day}\n($sessionLabel)'),
                    ),
                    _buildHeaderCell('Total Biblias'),
                  ],
                ),
                // Data Rows
                ...List.generate(studentNames.length, (index) {
                  final isEven = index % 2 == 0;
                  final rowColor = isEven
                      ? const PdfColor.fromInt(0xFFFFFFFF)
                      : const PdfColor.fromInt(0xFFF8FAFC);

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: rowColor),
                    children: [
                      _buildTableCell(
                        pw.Text(
                          '${index + 1}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ),
                      _buildTableCell(
                        pw.Text(
                          studentNames[index],
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF1E1B4B),
                          ),
                        ),
                        alignLeft: true,
                      ),
                      ...List.generate(sundays.length, (_) {
                        return pw.Container(
                          alignment: pw.Alignment.center,
                          padding: const pw.EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 2,
                          ),
                          child: _buildPosterCellPlaceholder(bibleImage),
                        );
                      }),
                      _buildTableCell(
                        pw.Text(
                          '___ / $totalSundays',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF0284C7),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    // ================= PAGE 2: CHEERFUL CUT-OUT BIBLE POSTALES PAGE =================
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          // Generate All Cut-Out Bible Postal Cards
          final List<pw.Widget> biblePostalCards = [];
          for (int k = 0; k < studentNames.length; k++) {
            for (int s = 0; s < sundays.length; s++) {
              biblePostalCards.add(
                _buildCutOutBiblePostalCard(
                  bibleImage: bibleImage,
                  kidName: studentNames[k],
                  dateStr: 'Dom ${sundays[s].day} $monthName',
                ),
              );
            }
          }

          return [
            // Title Header Banner for Page 2
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(
                  0xFF10B981,
                ), // Cheerful Mint Green
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'HOJA DE BIBLIAS RECORTABLES PARA NIÑOS',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Clase: $className  •  Mes: $monthName $year  •  Sesión: $sessionLabel',
                        style: const pw.TextStyle(
                          fontSize: 10.5,
                          color: PdfColor.fromInt(0xFFD1FAE5),
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: const PdfColor.fromInt(0xFFFEF08A),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Text(
                      'MATERIAL PARA RECORTAR',
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF854D0E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),

            // Cheerful Instruction Banner
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFECFDF5),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(
                  color: const PdfColor.fromInt(0xFFA7F3D0),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      pw.Text(
                        'Total a recortar: ',
                        style: const pw.TextStyle(
                          fontSize: 9.5,
                          color: PdfColor.fromInt(0xFF065F46),
                        ),
                      ),
                      pw.Text(
                        '$totalPostales biblias ',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF047857),
                        ),
                      ),
                      pw.Text(
                        '($totalKids niños x $totalSundays domingos)',
                        style: const pw.TextStyle(
                          fontSize: 9.5,
                          color: PdfColor.fromInt(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Instrucciones: Recorta cada biblia e incentiva a los niños a pegarla en el póster de la pared.',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: const PdfColor.fromInt(0xFF065F46),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // Cut-Out Postales Grid
            pw.Wrap(spacing: 6, runSpacing: 6, children: biblePostalCards),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'plantilla-asistencia-${className.replaceAll(" ", "_")}-$monthName-$year-${session.toUpperCase()}.pdf',
    );
  }

  static pw.Widget _buildHeaderCell(String text, {bool alignLeft = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      alignment: alignLeft ? pw.Alignment.centerLeft : pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
          fontSize: 9.5,
        ),
        textAlign: alignLeft ? pw.TextAlign.left : pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTableCell(pw.Widget child, {bool alignLeft = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      alignment: alignLeft ? pw.Alignment.centerLeft : pw.Alignment.center,
      child: child,
    );
  }
}
