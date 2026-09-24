import 'package:flutter/material.dart';
import '../../../core/widgets/app_card.dart';
import '../data/models/dashboard_models.dart';
import 'dashboard_controller.dart';
import 'widgets/monthly_chart_widget.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToReportes;
  final VoidCallback? onNavigateToAsistencia;

  const DashboardScreen({
    super.key,
    this.onNavigateToReportes,
    this.onNavigateToAsistencia,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DashboardController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Parse YYYY-MM-DD string to Spanish formatted string safely
  String _formatDate(String dateString) {
    try {
      final parts = dateString.split('-').map(int.parse).toList();
      if (parts.length < 3) return dateString;

      final date = DateTime(parts[0], parts[1], parts[2]);
      const weekdays = [
        'lunes',
        'martes',
        'miércoles',
        'jueves',
        'viernes',
        'sábado',
        'domingo',
      ];
      const months = [
        'enero',
        'febrero',
        'marzo',
        'abril',
        'mayo',
        'junio',
        'julio',
        'agosto',
        'septiembre',
        'octubre',
        'noviembre',
        'diciembre',
      ];

      final weekdayName = weekdays[date.weekday - 1];
      final monthName = months[date.month - 1];

      return '$weekdayName, ${date.day} de $monthName de ${date.year}';
    } catch (_) {
      return dateString;
    }
  }

  String _getSessionEmoji(String session) {
    return session.toUpperCase() == 'AM' ? '🌅' : '🌆';
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🏠', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 16),
                  Text(
                    'Cargando dashboard...',
                    style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                  ),
                  SizedBox(height: 16),
                  CircularProgressIndicator(color: Color(0xFF4F46E5)),
                ],
              ),
            );
          }

          final top3 = _controller.top3Attendees;
          final lastSession = _controller.lastSession;

          return RefreshIndicator(
            onRefresh: () => _controller.loadDashboardData(forceRefresh: true),
            color: const Color(0xFF4F46E5),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header with Gradient
                  Container(
                    padding: const EdgeInsets.only(
                      top: 52,
                      bottom: 28,
                      left: 24,
                      right: 24,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF3730A3)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '¡Hola! 👋',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    color: Colors.amberAccent,
                                    size: 14,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'IBBAC App',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Resumen general y estadísticas de asistencia',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFE0E7FF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 1.5 Quick Action Shortcut Card
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 20,
                    ),
                    child: AppCard(
                      onTap: () {
                        if (widget.onNavigateToAsistencia != null) {
                          widget.onNavigateToAsistencia!();
                        }
                      },
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.white,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              '⚡',
                              style: TextStyle(fontSize: 24),
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tomar Asistencia de Hoy',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Acceso directo rápido a la toma de lista',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF4F46E5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Cards Section
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 600;
                        return Flex(
                          direction: isWide ? Axis.horizontal : Axis.vertical,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Top 3 Card
                            Expanded(
                              flex: isWide ? 1 : 0,
                              child: _buildTop3Card(top3),
                            ),
                            SizedBox(
                              height: isWide ? 0 : 16,
                              width: isWide ? 16 : 0,
                            ),
                            // Last Session Card
                            Expanded(
                              flex: isWide ? 1 : 0,
                              child: _buildLastSessionCard(lastSession),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // 3. Annual Attendance Chart Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📈 Asistencia anual $currentYear',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x05000000),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Quick Stats
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            '${_controller.totalYearAttendance}',
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF4F46E5),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Total del año',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 40,
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            '${_controller.monthlyAverage}',
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF4F46E5),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Promedio mensual',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Monthly Chart
                              MonthlyChartWidget(
                                monthlyAttendance:
                                    _controller.monthlyAttendance,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 4. Quick Actions Section
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '⚡ Acciones rápidas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionCard(
                                icon: '📊',
                                title: 'Estadísticas',
                                subtitle: 'Ver más detalles',
                                onTap: widget.onNavigateToReportes ?? () {},
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildActionCard(
                                icon: _controller.isGeneratingReport
                                    ? '⏳'
                                    : '🎂',
                                title: _controller.isGeneratingReport
                                    ? 'Generando...'
                                    : 'Cumpleaños',
                                subtitle: _controller.isGeneratingReport
                                    ? 'Creando reporte...'
                                    : 'Cumpleañeros del mes',
                                isLoading: _controller.isGeneratingReport,
                                onTap: () async {
                                  final ok = await _controller
                                      .generateBirthdayReport();
                                  if (context.mounted) {
                                    if (ok) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Reporte de cumpleaños generado correctamente.',
                                          ),
                                          backgroundColor: Color(0xFF4F46E5),
                                        ),
                                      );
                                    } else {
                                      final errorMsg =
                                          _controller.errorMessage ??
                                          'No se pudo generar el reporte de cumpleaños.';
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(errorMsg),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTop3Card(List<TopAttendee> top3) {
    final first = top3.isNotEmpty ? top3[0] : null;
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🏆', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text(
                'Top 3 Asistentes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Líderes de asistencia este año',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          if (top3.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 2nd Place
                Expanded(
                  child: _buildPodiumColumn(
                    attendee: second,
                    rank: '🥈 2°',
                    height: 70,
                    color: const Color(0xFFF1F5F9),
                    accentColor: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 8),
                // 1st Place (Center - Elevated)
                Expanded(
                  child: _buildPodiumColumn(
                    attendee: first,
                    rank: '👑 1°',
                    height: 96,
                    color: const Color(0xFFFEF3C7),
                    accentColor: const Color(0xFFD97706),
                    isFirst: true,
                  ),
                ),
                const SizedBox(width: 8),
                // 3rd Place
                Expanded(
                  child: _buildPodiumColumn(
                    attendee: third,
                    rank: '🥉 3°',
                    height: 56,
                    color: const Color(0xFFFFEDD5),
                    accentColor: const Color(0xFFC2410C),
                  ),
                ),
              ],
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  'Sin datos registrados',
                  style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn({
    required TopAttendee? attendee,
    required String rank,
    required double height,
    required Color color,
    required Color accentColor,
    bool isFirst = false,
  }) {
    if (attendee == null) {
      return const SizedBox.shrink();
    }

    final initial = attendee.name.isNotEmpty
        ? attendee.name[0].toUpperCase()
        : '?';

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Badge Circle
        CircleAvatar(
          radius: isFirst ? 22 : 18,
          backgroundColor: accentColor,
          child: Text(
            initial,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isFirst ? 16 : 14,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          attendee.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isFirst ? 13 : 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${attendee.count} asis.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 6),
        // Podium Pillar
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: accentColor.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text(
              rank,
              style: TextStyle(
                fontSize: isFirst ? 14 : 12,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLastSessionCard(LastSessionInfo? lastSession) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            lastSession != null ? _getSessionEmoji(lastSession.session) : '📅',
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          if (lastSession != null) ...[
            Text(
              '${lastSession.attended}',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4F46E5),
              ),
            ),
            const Text(
              'personas asistieron',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            Text(
              lastSession.session.toUpperCase() == 'AM' ? 'Mañana' : 'Tarde',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatDate(lastSession.date),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ] else ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Sin datos recientes',
                style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
