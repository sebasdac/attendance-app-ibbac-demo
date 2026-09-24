import 'package:flutter/material.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_header_banner.dart';
import 'kids_attendance_screen.dart';
import 'kids_controller.dart';
import 'monthly_attendance_screen.dart';
import 'register_kid_screen.dart';

class KidsScreen extends StatefulWidget {
  const KidsScreen({super.key});

  @override
  State<KidsScreen> createState() => _KidsScreenState();
}

class _KidsScreenState extends State<KidsScreen> {
  late final KidsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = KidsController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showClassPickerModal(BuildContext context, KidsController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Handle indicator bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
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
                  const SizedBox(height: 4),
                  const Text(
                    'Elige la clase para registrar asistencia',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: controller.classes.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  '🏫',
                                  style: TextStyle(fontSize: 48),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No hay clases registradas',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Agrega clases para poder registrar asistencia',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    controller.fetchClasses();
                                  },
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: const Text('Recargar clases'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4F46E5),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: controller.classes.length,
                            separatorBuilder: (_, index) => const Divider(
                              height: 1,
                              color: Color(0xFFF1F5F9),
                            ),
                            itemBuilder: (context, index) {
                              final kidsClass = controller.classes[index];
                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.school,
                                    color: Color(0xFF4F46E5),
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  kidsClass.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right,
                                  color: Color(0xFF94A3B8),
                                ),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => KidsAttendanceScreen(
                                        classRoom: kidsClass.name,
                                      ),
                                    ),
                                  );
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

  @override
  Widget build(BuildContext context) {
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
                  Text('👶', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 16),
                  Text(
                    'Cargando clases...',
                    style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                  ),
                  SizedBox(height: 16),
                  CircularProgressIndicator(color: Color(0xFF4F46E5)),
                ],
              ),
            );
          }

          final classes = _controller.classes;

          return RefreshIndicator(
            onRefresh: () => _controller.fetchClasses(),
            color: const Color(0xFF4F46E5),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header with Gradient
                  const AppHeaderBanner(
                    title: '👶 Kids',
                    subtitle: 'Gestión de niños y clases',
                  ),

                  // 2. Stats Section
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: AppCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            '${classes.length}',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4F46E5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Clases registradas',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. Main Actions Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🎯 Acciones principales',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildActionCard(
                          context: context,
                          icon: Icons.person_add_rounded,
                          iconBgColor: const Color(0xFF4F46E5),
                          title: 'Registrar Niño',
                          subtitle: 'Agrega nuevos niños a la base de datos',
                          arrowColor: const Color(0xFF4F46E5),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterKidScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildActionCard(
                          context: context,
                          icon: Icons.format_list_bulleted_rounded,
                          iconBgColor: const Color(0xFFF59E0B),
                          title: 'Pasar Lista',
                          subtitle:
                              'Marca la asistencia de los niños por clase',
                          arrowColor: const Color(0xFFF59E0B),
                          onTap: () =>
                              _showClassPickerModal(context, _controller),
                        ),
                        const SizedBox(height: 16),
                        _buildActionCard(
                          context: context,
                          icon: Icons.calendar_month_rounded,
                          iconBgColor: const Color(0xFF10B981),
                          title: 'Asistencia Mensual',
                          subtitle: 'Revisa la asistencia de los niños por mes',
                          arrowColor: const Color(0xFF10B981),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MonthlyAttendanceScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // 4. Registered Classes Chips Section
                  if (classes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🏫 Clases registradas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: classes.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              final isEven = index % 2 == 0;
                              final bgColor = isEven
                                  ? const Color(0xFFEEF2FF)
                                  : const Color(0xFFFEF3C7);
                              final borderColor = isEven
                                  ? const Color(0xFFC7D2FE)
                                  : const Color(0xFFFCD34D);
                              final textColor = isEven
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFFD97706);

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.school,
                                      size: 16,
                                      color: textColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      item.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
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

                  // 5. Empty State Section
                  if (classes.isEmpty && !_controller.isLoading)
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          const Text('🏫', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          const Text(
                            'No hay clases registradas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Necesitas registrar clases antes de poder gestionar niños',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            onPressed: () => _controller.fetchClasses(),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Recargar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF4F46E5),
                              side: const BorderSide(color: Color(0xFF4F46E5)),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required Color arrowColor,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: arrowColor,
            ),
          ),
        ],
      ),
    );
  }
}
