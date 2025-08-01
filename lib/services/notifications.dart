import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzData;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  final notificationPlugin = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return; //prevent re-initialization

    // Initialize timezone data
    tzData.initializeTimeZones();
    final currentTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimeZone)); // Set your timezone

    // Android and iOS initialization settings
    const initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // init settings
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize the plugin
    await notificationPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        // Handle notification response
        print('Notification clicked: ${response.payload}');
      },
    );

    // Request permissions
    await _handlePermissions();

    _isInitialized = true;
  }

  // Notification Details Setup
  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        "daily_smile_channel",
        "Daily Smile Notifications",
        channelDescription: "Daily Smile Notifications",
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  // Show Notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
      _isInitialized = true;
    }

    await notificationPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails(),
      payload: payload,
    );
  }

  // Notification Permission Check
  Future<void> _handlePermissions() async {
    if (Platform.isAndroid) {
      // Android 13+ Notification Permission
      if (await Permission.notification.isDenied ||
          await Permission.notification.isPermanentlyDenied) {
        final status = await Permission.notification.request();

        if (!status.isGranted) {
          debugPrint("Notifications permission denied");
          // Optionally alert the user or guide them to settings
        }
      }
    }

    if (Platform.isIOS) {
      await notificationPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  // Schedule Notification
  Future<void> scheduleotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    // Get Current Timezone
    final now = tz.TZDateTime.now(tz.local);

    final scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    await notificationPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      // Ensure the notification is shown at the exact time daily
      matchDateTimeComponents: DateTimeComponents.time,
    );
    print("notification scheduled at: $scheduledTime");
  }

  // Cancel Notification
  Future<void> cancelAllNotifications() async {
    await notificationPlugin.cancelAll();
  }

  // Log Scheduled Notifications
  Future<void> logScheduledNotifications() async {
    final pending = await notificationPlugin.pendingNotificationRequests();
    for (final n in pending) {
      print('Pending Notification: ID=${n.id}, Title=${n.title}');
    }
  }
}
