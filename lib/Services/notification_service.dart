import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    try {
      // Initialize timezone
      tz_data.initializeTimeZones();
      final String timeZoneName =
          await FlutterTimezone.getLocalTimezone() as String;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      // Fallback to Asia/Yangon (Myanmar Time) if lookup fails
      tz.setLocalLocation(tz.getLocation('Asia/Yangon'));
    }

    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('launcher_icon');

    // iOS initialization
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint("Notification tapped: ${details.payload}");
      },
    );

    if (Platform.isAndroid) {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      // Create channels first
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );

      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'vehicle_reminder_channel',
          'Vehicle Reminders',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          sound: RawResourceAndroidNotificationSound('notification_sound'),
        ),
      );

      // Explicitly request permissions using permission_handler
      debugPrint("Requesting notification permissions...");
      final status = await Permission.notification.request();
      debugPrint("Notification permission status: $status");

      if (Platform.isAndroid) {
        debugPrint("Requesting exact alarm permissions...");
        final alarmStatus = await Permission.scheduleExactAlarm.request();
        debugPrint("Exact alarm permission status: $alarmStatus");
      }
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'launcher_icon',
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          sound: 'notification_sound.wav',
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    final androidDetails = AndroidNotificationDetails(
      'vehicle_reminder_channel',
      'Vehicle Reminders',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'launcher_icon',
      fullScreenIntent: true,
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          sound: 'notification_sound.wav',
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> showTestNotification() async {
    await showNotification(
      id: 999,
      title: 'Test Notification',
      body:
          'If you see this, notifications are working correctly in Release Mode!',
    );
  }

  static Future<void> scheduleVehicleReminders({
    required String licensePlate,
    required DateTime? lastOilChangeDate,
    required DateTime? insuranceExpiryDate,
  }) async {
    final notiService = NotificationService();
    final int baseId = licensePlate.hashCode.abs() % 10000;

    // 1. Insurance Reminder (7 days before)
    if (insuranceExpiryDate != null) {
      final reminderDate = insuranceExpiryDate.subtract(
        const Duration(days: 7),
      );
      if (reminderDate.isAfter(DateTime.now())) {
        await notiService.scheduleNotification(
          id: baseId + 1,
          title: 'Insurance Expiry Reminder',
          body:
              'Insurance for $licensePlate will expire on ${DateFormat('dd MMM').format(insuranceExpiryDate)}.',
          scheduledDate: reminderDate,
        );
      }
    }

    // 2. Oil Change Reminder (6 months after last change)
    if (lastOilChangeDate != null) {
      final reminderDate = lastOilChangeDate.add(const Duration(days: 180));
      if (reminderDate.isAfter(DateTime.now())) {
        await notiService.scheduleNotification(
          id: baseId + 2,
          title: 'Engine Oil Change Reminder',
          body:
              'It’s been 6 months since the last oil change for $licensePlate. Please consider a service.',
          scheduledDate: reminderDate,
        );
      }
    }
  }
}
