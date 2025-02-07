import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize notifications
  Future<void> initNotifications() async {
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initSettings =
        InitializationSettings(android: androidInitSettings);
    await _notificationsPlugin.initialize(initSettings);

    // Request notification permission for Android 13 and above
    if (await Permission.notification.isGranted) {
      print('Notification permission granted');
    } else if (await Permission.notification.request().isGranted) {
      print('Notification permission granted');
    } else {
      print('Notification permission denied');
    }

    // Create notification channel for Android 8.0 and above
    await _createNotificationChannel();
  }

  // Create a notification channel for Android 8.0 and above
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'event_reminders', // Channel ID
      'Event Reminders', // Channel Name
      importance: Importance.high,
      description: 'Notifications for scheduled events',
    );

    // Create the channel
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Schedule notification
  Future<void> scheduleNotification(
      {required int id,
      required String title,
      required String body,
      required DateTime scheduledTime}) async {
    try {
      // Ensure the scheduled time is in the correct timezone
      final tz.TZDateTime scheduledDateTime =
          tz.TZDateTime.from(scheduledTime, tz.local);

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDateTime, // Use TZDateTime to handle time zones
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'event_reminders', // Channel ID
            'Event Reminders', // Channel Name
            channelDescription: 'Notifications for scheduled events',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode:
            AndroidScheduleMode.exactAllowWhileIdle, // ✅ REQUIRED PARAMETER
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents:
            DateTimeComponents.time, // Ensures correct scheduling
      );
      print('Notification scheduled successfully');
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }
}
