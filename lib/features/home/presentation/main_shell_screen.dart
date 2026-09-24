import 'package:flutter/material.dart';

import '../../../core/services/birthday_notification_service.dart';
import '../../attendance/presentation/asistencia_screen.dart';
import '../../attendance/presentation/registro_screen.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../kids/presentation/kids_screen.dart';
import '../../reports/presentation/reportes_screen.dart';
import '../../settings/presentation/settings_screen.dart';

class MainShellScreen extends StatefulWidget {
  final AuthController authController;

  const MainShellScreen({super.key, required this.authController});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkWelcomeMessage();
      BirthdayNotificationService().requestPermissionsWithExplanation(context);
    });
  }

  void _checkWelcomeMessage() {
    final welcomeMsg = widget.authController.welcomeMessage;
    if (welcomeMsg != null && welcomeMsg.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.waving_hand, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  welcomeMsg,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF6366F1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      widget.authController.consumeWelcomeMessage();
    }
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return DashboardScreen(
          onNavigateToReportes: () {
            setState(() {
              _currentIndex = 2;
            });
          },
          onNavigateToAsistencia: () {
            setState(() {
              _currentIndex = 3;
            });
          },
        );
      case 1:
        return const RegistroScreen();
      case 2:
        return const ReportesScreen();
      case 3:
        return const AsistenciaScreen();
      case 4:
        return const KidsScreen();
      case 5:
        return SettingsScreen(authController: widget.authController);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🏠 [MainShellScreen] build() with index: $_currentIndex');
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 20,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                debugPrint('📱 [MainShell] User tapped bottom tab: $index');
                setState(() {
                  _currentIndex = index;
                });
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF4F46E5),
              unselectedItemColor: const Color(0xFF94A3B8),
              selectedFontSize: 11,
              unselectedFontSize: 10,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view_outlined, size: 22),
                  activeIcon: Icon(Icons.grid_view_rounded, size: 22),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_add_outlined, size: 22),
                  activeIcon: Icon(Icons.person_add_rounded, size: 22),
                  label: 'Registro',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.analytics_outlined, size: 22),
                  activeIcon: Icon(Icons.analytics_rounded, size: 22),
                  label: 'Reportes',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.task_alt_outlined, size: 22),
                  activeIcon: Icon(Icons.task_alt_rounded, size: 22),
                  label: 'Asistencia',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.child_care_outlined, size: 22),
                  activeIcon: Icon(Icons.child_care_rounded, size: 22),
                  label: 'Kids',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined, size: 22),
                  activeIcon: Icon(Icons.settings_rounded, size: 22),
                  label: 'Ajustes',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
