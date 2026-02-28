import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

// Top-level callback — required by flutter_local_notifications for background
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  _handleResponse(response);
}

void _handleResponse(NotificationResponse response) {
  final payload = response.payload;
  if (payload != null) {
    final index = int.tryParse(payload);
    if (index != null) {
      _markFromNotification(index);
    }
  }
}

Future<void> _markFromNotification(int index) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('water_consumed_today');
  if (raw == null) return;
  try {
    final list = (json.decode(raw) as List);
    if (index < list.length) {
      list[index] = 1;
      await prefs.setString('water_consumed_today', json.encode(list));
    }
  } catch (_) {}
}

class WaterNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'water_reminders';
  static const _channelName = 'Water Reminders';
  static const _actionId = 'mark_drunk';

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    _initialized = true;
  }

  static Future<bool> requestPermissions() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      // null = platform doesn't need runtime permission (pre-Android 13) → treat as granted
      final granted = await android?.requestNotificationsPermission();
      return granted ?? true;
    } catch (_) {
      return true; // fail open — let save proceed
    }
  }

  static Future<void> scheduleAll({
    required int servings,
    required int servingMl,
    required TimeOfDay startTime,
  }) async {
    await cancelAll();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Reminders to drink water throughout the day',
      importance: Importance.high,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction(
          _actionId,
          '💧 Mark as Drunk',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );
    const details = NotificationDetails(android: androidDetails);

    // Spread N servings across 16 hours starting from startTime
    const totalMinutes = 16 * 60;
    final interval = totalMinutes ~/ servings;
    final offset = DateTime.now().timeZoneOffset;
    final now = DateTime.now();

    for (int i = 0; i < servings; i++) {
      final startMins = startTime.hour * 60 + startTime.minute;
      final targetMins = startMins + i * interval;
      final hour = (targetMins ~/ 60) % 24;
      final minute = targetMins % 60;

      // Convert local target time to UTC for zonedSchedule
      final targetLocal =
          DateTime(now.year, now.month, now.day, hour, minute);
      final targetUtc = targetLocal.subtract(offset);

      var scheduled = tz.TZDateTime.from(targetUtc, tz.UTC);
      if (scheduled.isBefore(tz.TZDateTime.now(tz.UTC))) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        i,
        '💧 Time to hydrate!',
        'Serving ${i + 1}/$servings — drink ${servingMl}ml',
        scheduled,
        details,
        payload: '$i',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static Future<void> cancelAll() async => _plugin.cancelAll();
}
