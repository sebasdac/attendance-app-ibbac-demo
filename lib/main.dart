import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/app.dart';
import 'core/config/firebase_options.dart';
import 'core/services/birthday_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Log all Flutter framework errors with full stack traces
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🚨 [FLUTTER ERROR] Exception: ${details.exception}');
    debugPrint('🚨 [FLUTTER ERROR] Stack: ${details.stack}');
  };

  // Log all asynchronous / uncaught platform errors
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('🚨 [UNCAUGHT ERROR] Error: $error');
    debugPrint('🚨 [UNCAUGHT ERROR] Stack: $stack');
    return true;
  };

  // Custom ErrorWidget to ensure no screen ever fails silently with a blank white box
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('🚨 [RENDER ERROR WIDGET] ${details.exceptionAsString()}');
    return Material(
      color: const Color(0xFFF8FAFC),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 48),
              const SizedBox(height: 12),
              const Text(
                'Ocurrió un error al mostrar esta sección',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                details.exceptionAsString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ),
    );
  };

  debugPrint('🚀 [MAIN] Initializing Firebase...');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('🚀 [MAIN] Initializing Birthday Notification Service...');
  await BirthdayNotificationService().init();
  debugPrint('🚀 [MAIN] Running App...');

  runApp(const AsistenciaApp());
}
