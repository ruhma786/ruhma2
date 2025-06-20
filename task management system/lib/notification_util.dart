// notification_util.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationUtil {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    final initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'task_notifications',
      'Task Notifications',
      channelDescription: 'Notification channel for task reminders',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      0, // Notification ID
      title,
      body,
      notificationDetails,
    );
  }
}
