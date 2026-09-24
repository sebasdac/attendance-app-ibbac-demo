import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'birthday_cache_service.dart';

class BirthdayNotificationService {
  static final BirthdayNotificationService _instance =
      BirthdayNotificationService._internal();
  factory BirthdayNotificationService() => _instance;
  BirthdayNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _notifiedDateKey = 'last_birthday_notified_date';
  static const String _askedPermissionKey = 'birthday_permission_asked';
  static const int _notificationId = 888;

  /// Initializes the local notification plugin and channel settings.
  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(initSettings);
  }

  /// Requests notification permission with an initial explanatory dialog.
  /// If the user denies permission, notifies them that birthday alerts won't be sent.
  Future<bool> requestPermissionsWithExplanation(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyAsked = prefs.getBool(_askedPermissionKey) ?? false;

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      final bool? isGranted = await androidImplementation
          .areNotificationsEnabled();
      if (isGranted == true) {
        return true; // Already granted
      }
    }

    if (alreadyAsked) {
      return false; // Don't prompt again automatically if already answered
    }

    if (!context.mounted) return false;

    // 1. Show explanation modal / dialog first
    final bool? proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cake_rounded, color: Color(0xFF6366F1)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Notificaciones de Cumpleaños',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Solicitamos tu permiso de notificaciones para poder avisarte cuando las personas o niños estén de cumpleaños.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'No permitir',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Permitir'),
          ),
        ],
      ),
    );

    await prefs.setBool(_askedPermissionKey, true);

    void showDenialSnackBar() {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(
                  Icons.notifications_off_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No vas a ser avisado de los cumpleaños.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }

    if (proceed != true) {
      showDenialSnackBar();
      return false;
    }

    // 2. Request Android OS system permission prompt
    bool granted = false;
    if (androidImplementation != null) {
      granted =
          await androidImplementation.requestNotificationsPermission() ?? false;
    } else {
      granted = true;
    }

    if (!granted) {
      showDenialSnackBar();
    }

    return granted;
  }

  /// Checks the local cache for today's birthdays and triggers a notification if any exist.
  /// Guarantees that only one notification is sent per calendar day.
  Future<void> checkAndNotifyTodayBirthdays({
    bool forceNotification = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final lastNotified = prefs.getString(_notifiedDateKey);

    if (!forceNotification && lastNotified == todayStr) {
      // Already notified today
      return;
    }

    final birthdayMembers = await BirthdayCacheService()
        .getTodayBirthdayMembers();
    if (birthdayMembers.isEmpty) {
      return;
    }

    final String title = '🎂 ¡Cumpleaños de Hoy!';
    final String body;

    if (birthdayMembers.length == 1) {
      final m = birthdayMembers.first;
      final tag = m.type == 'kid' ? '👶 (Niño)' : '👤 (Adulto)';
      body =
          '🎉 Hoy es el cumpleaños de ${m.name} $tag. ¡Felicítalo en su día!';
    } else {
      final names = birthdayMembers.map((m) => m.name).join(', ');
      body =
          '🎉 Hoy cumplen años ${birthdayMembers.length} personas: $names. ¡Felicítalos!';
    }

    await _showNotification(id: _notificationId, title: title, body: body);

    await prefs.setString(_notifiedDateKey, todayStr);
  }

  /// Displays an immediate local notification
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'cumpleanos_channel_ibbac',
      'Cumpleaños IBBAC',
      channelDescription:
          'Notificaciones diarias de cumpleaños de miembros y niños',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(id, title, body, notificationDetails);
  }
}
