import 'package:flutter/material.dart';
import '../../../core/utils/monthly_pdf_generator.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header_banner.dart';
import '../data/models/monthly_attendance_models.dart';
import 'monthly_attendance_controller.dart';

class MonthlyAttendanceScreen extends StatefulWidget {
  final String? initialClass;

  const MonthlyAttendanceScreen({super.key, this.initialClass});

  @override
  State<MonthlyAttendanceScreen> createState() =>
      _MonthlyAttendanceScreenState();
}

class _MonthlyAttendanceScreenState extends State<MonthlyAttendanceScreen> {
  late final MonthlyAttendanceController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MonthlyAttendanceController();
    if (widget.initialClass != null && widget.initialClass!.isNotEmpty) {
      _controller.setSelectedClass(widget.initialClass!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showClassSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final classes = _controller.classes;

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Selecciona una Clase',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (classes.isEmpty)
                    const Text('No hay clases registradas')
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: classes.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, index) {
                          final c = classes[index];
                          final isSelected =
                              c.name == _controller.selectedClass;

                          return ListTile(
                            title: Text(
                              c.name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? const Color(0xFF6366F1)
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF6366F1),
                                  )
                                : null,
                            onTap: () {
                              _controller.setSelectedClass(c.name);
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showMonthSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final months = _controller.monthsList;

            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Selecciona un Mes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: months.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, index) {
                        final m = months[index];
                        final isSelected = m == _controller.selectedMonth;

                        return ListTile(
                          title: Text(
                            '$m ${_controller.selectedYear}',
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? const Color(0xFF6366F1)
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF6366F1),
                                )
                              : null,
                          onTap: () {
                            _controller.setSelectedMonth(m);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Template Download Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showSessionSelectionDialogForTemplate();
                      },
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: const Text(
                        'Descargar Plantilla de Asistencia (PDF)',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6366F1),
                        side: const BorderSide(color: Color(0xFF6366F1)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showSessionSelectionDialogForTemplate() async {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF6366F1)),
              SizedBox(width: 10),
              Text(
                'Seleccionar Sesión',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            '¿Para cuál sesión deseas generar la plantilla impresa de asistencia?',
            style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _downloadSundayTemplate('AM');
              },
              icon: const Icon(Icons.wb_sunny_rounded, size: 16),
              label: const Text('Mañana (AM)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _downloadSundayTemplate('PM');
              },
              icon: const Icon(Icons.nights_stay_rounded, size: 16),
              label: const Text('Tarde (PM)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadSundayTemplate(String session) async {
    final report = _controller.monthlyReport;
    final studentNames = report != null && report.attendanceByKid.isNotEmpty
        ? report.attendanceByKid.keys.toList()
        : [
            'Estudiante 1',
            'Estudiante 2',
            'Estudiante 3',
            'Estudiante 4',
            'Estudiante 5',
          ];

    await SundayTemplatePdfGenerator.generateAndShareTemplate(
      className: _controller.selectedClass.isEmpty
          ? 'Clase Kids'
          : _controller.selectedClass,
      monthName: _controller.selectedMonth,
      year: _controller.selectedYear,
      session: session,
      studentNames: studentNames,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return RefreshIndicator(
            onRefresh: () => _controller.generateReport(),
            color: const Color(0xFF6366F1),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Banner
                  AppHeaderBanner(
                    title: '📅 Asistencia Mensual',
                    subtitle: 'Reportes y estadísticas por mes',
                    onBack: () => Navigator.pop(context),
                  ),
                  // 1. Controls Header (Class selector, Month selector, Report Type toggle)
                  _buildControlsSection(),

                  const SizedBox(height: 16),

                  // 2. Report Content
                  if (_controller.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    )
                  else if (_controller.monthlyReport == null)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          'Selecciona una clase y mes para ver el reporte',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      ),
                    )
                  else
                    _controller.reportType == 'overview'
                        ? _buildOverviewReport(_controller.monthlyReport!)
                        : _buildDetailedReport(_controller.monthlyReport!),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildControlsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Selectors Row (Class & Month)
          Row(
            children: [
              // Class selector
              Expanded(
                child: InkWell(
                  onTap: _showClassSelectionBottomSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.school_rounded,
                          size: 18,
                          color: Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _controller.selectedClass.isEmpty
                                ? 'Seleccionar Clase'
                                : _controller.selectedClass,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Month selector
              Expanded(
                child: InkWell(
                  onTap: _showMonthSelectionBottomSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          size: 18,
                          color: Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_controller.selectedMonth} ${_controller.selectedYear}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Report Type Segmented Control (Overview / Detailed)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _controller.setReportType('overview'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _controller.reportType == 'overview'
                            ? const Color(0xFF6366F1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '📊 General',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _controller.reportType == 'overview'
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _controller.setReportType('detailed'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _controller.reportType == 'detailed'
                            ? const Color(0xFF6366F1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '📋 Detallado',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _controller.reportType == 'detailed'
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= OVERVIEW REPORT VIEW =================

  Widget _buildOverviewReport(MonthlyReportData report) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Stats Cards Row
          Row(
            children: [
              Expanded(
                child: _buildOverviewStatCard(
                  title: 'Total Asistencia',
                  value: '${report.totalAttendance}',
                  color: const Color(0xFF6366F1),
                  icon: Icons.groups_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildOverviewStatCard(
                  title: 'Promedio / Dom',
                  value: report.averagePerSunday.toStringAsFixed(1),
                  color: const Color(0xFFF59E0B),
                  icon: Icons.show_chart_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildOverviewStatCard(
                  title: 'Total Domingos',
                  value: '${report.totalSundays}',
                  color: const Color(0xFF10B981),
                  icon: Icons.calendar_today_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 2. Weekly Chart / Sundays Breakdown
          const Text(
            '📈 Desglose por Domingo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),

          if (report.weeklyStats.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                  child: Text(
                    'No hay registros de domingo este mes',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
              ),
            )
          else
            Column(
              children: report.weeklyStats.map((stat) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            color: Color(0xFF6366F1),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stat.dateStr,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '🌅 AM: ${stat.amCount}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '🌆 PM: ${stat.pmCount}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${stat.totalCount} niños',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 24),

          // 3. Top Attendees Section
          const Text(
            '🏆 Niños Destacados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),

          if (report.topAttendees.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                  child: Text(
                    'No hay niños registrados en esta clase',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
              ),
            )
          else
            Column(
              children: report.topAttendees.asMap().entries.map((entry) {
                final idx = entry.key;
                final attendee = entry.value;
                final medal = idx == 0
                    ? '🥇'
                    : idx == 1
                    ? '🥈'
                    : idx == 2
                    ? '🥉'
                    : '🏅';

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Row(
                      children: [
                        Text(medal, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                attendee.kidName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${attendee.attendedSundays} de ${attendee.totalSundays} domingos',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${attendee.percentage.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 24),

          // 4. Export PDF Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => MonthlyPdfGenerator.generateAndSharePdf(report),
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
              label: const Text(
                'Exportar Reporte Mensual (PDF)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  // ================= DETAILED REPORT VIEW =================

  Widget _buildDetailedReport(MonthlyReportData report) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // View Sub-toggle: [📅 Calendario] | [👤 Individual]
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _controller.setDetailedView('calendar'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _controller.detailedView == 'calendar'
                        ? const Color(0xFFEDE9FE)
                        : Colors.white,
                    side: BorderSide(
                      color: _controller.detailedView == 'calendar'
                          ? const Color(0xFF6366F1)
                          : const Color(0xFFCBD5E1),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    '📅 Calendario',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _controller.detailedView == 'calendar'
                          ? const Color(0xFF6366F1)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _controller.setDetailedView('individual'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _controller.detailedView == 'individual'
                        ? const Color(0xFFEDE9FE)
                        : Colors.white,
                    side: BorderSide(
                      color: _controller.detailedView == 'individual'
                          ? const Color(0xFF6366F1)
                          : const Color(0xFFCBD5E1),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    '👤 Individual',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _controller.detailedView == 'individual'
                          ? const Color(0xFF6366F1)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (_controller.detailedView == 'calendar')
            _buildCalendarView(report)
          else
            _buildIndividualView(report),
        ],
      ),
    );
  }

  Widget _buildCalendarView(MonthlyReportData report) {
    if (report.weeklyStats.isEmpty) {
      return const Center(
        child: Text(
          'No hay estadísticas registradas para este mes',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      );
    }

    return Column(
      children: report.weeklyStats.map((sunday) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Domingo ${sunday.dateStr}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Total: ${sunday.totalCount}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),

                // AM Attendees List
                const Text(
                  '🌅 Mañana (AM)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(height: 6),
                if (sunday.amAttendees.isEmpty)
                  const Text(
                    'Ningún niño registrado',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF94A3B8),
                    ),
                  )
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: sunday.amAttendees.map((name) {
                      return Chip(
                        label: Text(name, style: const TextStyle(fontSize: 12)),
                        backgroundColor: const Color(0xFFFEF3C7),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 12),

                // PM Attendees List
                const Text(
                  '🌆 Tarde (PM)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(height: 6),
                if (sunday.pmAttendees.isEmpty)
                  const Text(
                    'Ningún niño registrado',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF94A3B8),
                    ),
                  )
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: sunday.pmAttendees.map((name) {
                      return Chip(
                        label: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: const Color(0xFF6366F1),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIndividualView(MonthlyReportData report) {
    final kidsDetail = report.attendanceByKid.values.toList();
    if (kidsDetail.isEmpty) {
      return const Center(
        child: Text(
          'No hay niños registrados en esta clase',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      );
    }

    return Column(
      children: kidsDetail.map((detail) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      detail.kidName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      '${detail.attendedSundays}/${detail.totalSundays} (${detail.percentage.toStringAsFixed(0)}%)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Linear Progress Indicator
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: detail.totalSundays > 0
                        ? detail.attendedSundays / detail.totalSundays
                        : 0.0,
                    backgroundColor: const Color(0xFFE2E8F0),
                    color: const Color(0xFF6366F1),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 12),

                // Sunday Badges
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: detail.sundayRecords.entries.map((e) {
                    final dateStr = e.key;
                    final isAttended = e.value;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isAttended
                            ? const Color(0xFFD1FAE5)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isAttended
                              ? const Color(0xFF6EE7B7)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAttended
                                ? Icons.check_circle_rounded
                                : Icons.cancel_outlined,
                            size: 12,
                            color: isAttended
                                ? const Color(0xFF065F46)
                                : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateStr.length >= 10
                                ? dateStr.substring(8)
                                : dateStr,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isAttended
                                  ? const Color(0xFF065F46)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
