import 'package:flutter/material.dart';
import '../../auth/data/models/user_model.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../kids/data/models/kids_class_model.dart';
import 'settings_controller.dart';
import 'widgets/merge_duplicates_modal.dart';

class SettingsScreen extends StatefulWidget {
  final AuthController authController;

  const SettingsScreen({super.key, required this.authController});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SettingsController(authController: widget.authController);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getUserInitial(UserModel? user) {
    if (user == null) return 'U';
    final name = user.name?.trim();
    if (name != null && name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    final email = user.email.trim();
    if (email.isNotEmpty) {
      return email[0].toUpperCase();
    }
    return 'U';
  }

  Future<void> _showAddClassDialog() async {
    final textController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.add_location_alt_rounded, color: Color(0xFF4F46E5)),
              SizedBox(width: 8),
              Text('Nueva Clase'),
            ],
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: textController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Nombre de la Clase',
                hintText: 'Ej: Semillitas, Párvulos...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Ingresa un nombre para la clase';
                }
                if (_controller.classes.any(
                  (c) => c.name.toLowerCase() == val.trim().toLowerCase(),
                )) {
                  return 'Ya existe una clase con este nombre';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() == true) {
                  final className = textController.text.trim();
                  Navigator.pop(ctx);

                  final success = await _controller.addClass(className);
                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Clase "$className" agregada con éxito.'),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteClass(KidsClass kidsClass) async {
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Eliminar Clase'),
            ],
          ),
          content: Text(
            '¿Estás seguro de eliminar la clase "${kidsClass.name}"?',
            style: const TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await _controller.deleteClass(kidsClass.id);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Clase "${kidsClass.name}" eliminada.'),
                      backgroundColor: const Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          '⚙️ Configuración',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF4F46E5)),
                  SizedBox(height: 16),
                  Text(
                    'Cargando ajustes...',
                    style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            );
          }

          final user = _controller.currentUser;
          final isTeacher = _controller.isTeacher;
          final todayBirthdays = _controller.todayBirthdayMembers;
          final classes = _controller.classes;

          return RefreshIndicator(
            onRefresh: () => _controller.loadData(),
            color: const Color(0xFF4F46E5),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                // 1. User Profile Card
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFF4F46E5),
                          child: Text(
                            _getUserInitial(user),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (user?.name != null && user!.name!.trim().isNotEmpty)
                                    ? user.name!
                                    : 'Usuario',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                (user?.email != null && user!.email.trim().isNotEmpty)
                                    ? user.email
                                    : 'Sin correo',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFC7D2FE),
                                  ),
                                ),
                                child: Text(
                                  isTeacher ? 'Maestro / Kids' : 'Administrador',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4F46E5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Birthday Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '🎂 Cumpleañeros de Hoy',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    Text(
                      isTeacher ? 'Solo Niños' : 'Niños y Adultos',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (todayBirthdays.isEmpty)
                  Card(
                    elevation: 0.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    color: Colors.white,
                    child: const ListTile(
                      leading: Text('🎈', style: TextStyle(fontSize: 24)),
                      title: Text(
                        'No hay cumpleañeros hoy',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Ningún miembro cumple años el día de hoy',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  )
                else
                  for (final member in todayBirthdays)
                    Card(
                      elevation: 0.5,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      color: Colors.white,
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: member.type == 'kid'
                                ? const Color(0xFFEEF2FF)
                                : const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            member.type == 'kid' ? '👶' : '👤',
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        title: Text(
                          member.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          member.type == 'kid' ? 'Niño/a' : 'Adulto',
                          style: TextStyle(
                            fontSize: 12,
                            color: member.type == 'kid'
                                ? const Color(0xFF4F46E5)
                                : const Color(0xFF059669),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: const Text(
                          '🎉 ¡Hoy!',
                          style: TextStyle(
                            color: Color(0xFFD97706),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),

                const SizedBox(height: 20),

                // 3. Admin-Only Section (Classes & Duplicates)
                if (!isTeacher) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '🏫 Gestión de Clases',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showAddClassDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Nueva Clase'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF4F46E5),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (classes.isEmpty)
                    Card(
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      color: Colors.white,
                      child: ListTile(
                        leading: const Icon(Icons.school_outlined, color: Color(0xFF4F46E5)),
                        title: const Text(
                          'No hay clases registradas',
                          style: TextStyle(fontSize: 14),
                        ),
                        trailing: TextButton(
                          onPressed: _showAddClassDialog,
                          child: const Text('Agregar'),
                        ),
                      ),
                    )
                  else
                    Card(
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      color: Colors.white,
                      child: Column(
                        children: [
                          for (int i = 0; i < classes.length; i++) ...[
                            if (i > 0) const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            ListTile(
                              leading: const Icon(Icons.school, color: Color(0xFF4F46E5), size: 22),
                              title: Text(
                                classes[i].name,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                onPressed: () => _confirmDeleteClass(classes[i]),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Duplicates
                  const Text(
                    '🔗 Miembros Duplicados',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    color: Colors.white,
                    child: ListTile(
                      leading: const Icon(Icons.link_rounded, color: Color(0xFF4F46E5), size: 24),
                      title: const Text(
                        'Unificar Registros Duplicados',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: const Text(
                        'Detecta y une miembros duplicados entre Personas y Kids',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Color(0xFF4F46E5)),
                      onTap: () {
                        MergeDuplicatesModal.show(
                          context,
                          onMerged: () => _controller.syncBirthdays(),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),
                ],

                // 4. Logout Section
                const Text(
                  '🔒 Sesión',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  color: Colors.white,
                  child: ListTile(
                    leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                    title: const Text(
                      'Cerrar Sesión',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: Colors.redAccent),
                    onTap: () => _controller.logout(),
                  ),
                ),

                const SizedBox(height: 36),

                // 5. App Info Footer
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.church_rounded, size: 32, color: Color(0xFF4F46E5)),
                      SizedBox(height: 6),
                      Text(
                        'IBBAC Asistencia by Sebastian C',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Versión 1.0.0 (Build 1)',
                        style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
