import 'package:flutter/material.dart';

import '../../../core/services/birthday_notification_service.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../kids/presentation/kids_screen.dart';
import '../../settings/presentation/settings_screen.dart';

class TeacherShellScreen extends StatefulWidget {
  final AuthController authController;

  const TeacherShellScreen({super.key, required this.authController});

  @override
  State<TeacherShellScreen> createState() => _TeacherShellScreenState();
}

class _TeacherShellScreenState extends State<TeacherShellScreen> {
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
        return const KidsScreen();
      case 1:
        return SettingsScreen(authController: widget.authController);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🏫 [TeacherShellScreen] build() with index: $_currentIndex');
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 16, top: 4),
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
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 6.0,
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                debugPrint('📱 [TeacherShell] User tapped bottom tab: $index');
                setState(() {
                  _currentIndex = index;
                });
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF4F46E5),
              unselectedItemColor: const Color(0xFF94A3B8),
              selectedFontSize: 12,
              unselectedFontSize: 11,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.child_care_outlined, size: 24),
                  activeIcon: Icon(Icons.child_care_rounded, size: 24),
                  label: 'Kids',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined, size: 24),
                  activeIcon: Icon(Icons.settings_rounded, size: 24),
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
