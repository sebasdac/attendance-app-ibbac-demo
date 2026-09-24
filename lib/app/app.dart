import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/home/presentation/main_shell_screen.dart';
import '../features/home/presentation/teacher_shell_screen.dart';

class AsistenciaApp extends StatefulWidget {
  const AsistenciaApp({super.key});

  @override
  State<AsistenciaApp> createState() => _AsistenciaAppState();
}

class _AsistenciaAppState extends State<AsistenciaApp> {
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = AuthController();
  }

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asistencia IBBAC',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
      theme: AppTheme.lightTheme,
      home: ListenableBuilder(
        listenable: _authController,
        builder: (context, _) {
          // 1. Initial loading state
          if (_authController.isLoading) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF007BFF)),
                    SizedBox(height: 16),
                    Text(
                      'Cargando...',
                      style: TextStyle(color: Color(0xFF666666)),
                    ),
                  ],
                ),
              ),
            );
          }

          // 2. Unauthenticated user -> LoginScreen
          if (!_authController.isAuthenticated) {
            return LoginScreen(
              authController: _authController,
              onLoginSuccess: () {},
            );
          }

          // 3. Role-based Route Filtering
          // If the user has a teacher role (`isTeacher` == true), route exclusively to TeacherShell
          if (_authController.isTeacher) {
            return TeacherShellScreen(authController: _authController);
          }

          // Otherwise (Admin / General User), route to MainShell
          return MainShellScreen(authController: _authController);
        },
      ),
    );
  }
}
