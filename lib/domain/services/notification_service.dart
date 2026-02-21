import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../presentation/tools/birthday/birthday_provider.dart';

/// Global navigator key — set in app.dart, used for notification tap navigation.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Local notification service for birthday reminders.
/// Follows SecureConfig pattern (static-only, private constructor).
class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // ── Initialise ──────────────────────────────────────────────────────────

  static Future<void> init() async {
    if (kIsWeb || _initialized) return;

    // Timezone setup
    tz.initializeTimeZones();
    try {
      final tzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onTap,
    );
    _initialized = true;
  }

  // ── Permission ──────────────────────────────────────────────────────────

  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    // Android 13+
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      if (granted != true) return false;
    }

    // iOS
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (granted != true) return false;
    }

    return true;
  }

  // ── Schedule / Cancel ───────────────────────────────────────────────────

  /// Schedule 3 notifications for a birthday entry.
  static Future<void> scheduleBirthdayNotifications(
    BirthdayEntry entry, {
    bool isKr = true,
  }) async {
    if (kIsWeb || !_initialized) return;

    await requestPermission();

    final baseId = entry.id.hashCode.abs() % 100000;

    // D-3 at 18:00
    final d3 = _nextOccurrence(entry.month, entry.day, -3, 18, 0);
    if (d3 != null) {
      await _schedule(
        id: baseId * 3,
        title: isKr ? '🎂 생일 알림' : '🎂 Birthday Reminder',
        body: isKr
            ? '${entry.name}님 생일이 3일 남았어요!'
            : '${entry.name}\'s birthday is in 3 days!',
        scheduledDate: d3,
      );
    }

    // D-1 at 18:00
    final d1 = _nextOccurrence(entry.month, entry.day, -1, 18, 0);
    if (d1 != null) {
      await _schedule(
        id: baseId * 3 + 1,
        title: isKr ? '🎂 생일 알림' : '🎂 Birthday Reminder',
        body: isKr
            ? '내일은 ${entry.name}님 생일이에요!'
            : 'Tomorrow is ${entry.name}\'s birthday!',
        scheduledDate: d1,
      );
    }

    // D-day at 08:00
    final d0 = _nextOccurrence(entry.month, entry.day, 0, 8, 0);
    if (d0 != null) {
      await _schedule(
        id: baseId * 3 + 2,
        title: isKr ? '🎉 생일 축하!' : '🎉 Happy Birthday!',
        body: isKr
            ? '오늘은 ${entry.name}님 생일입니다!'
            : 'Today is ${entry.name}\'s birthday!',
        scheduledDate: d0,
      );
    }
  }

  /// Cancel all 3 notifications for an entry.
  static Future<void> cancelBirthdayNotifications(String entryId) async {
    if (kIsWeb || !_initialized) return;

    final baseId = entryId.hashCode.abs() % 100000;
    await _plugin.cancel(baseId * 3);
    await _plugin.cancel(baseId * 3 + 1);
    await _plugin.cancel(baseId * 3 + 2);
  }

  /// Reschedule all birthday notifications (call on app start).
  static Future<void> rescheduleAll(
    List<BirthdayEntry> entries, {
    bool isKr = true,
  }) async {
    if (kIsWeb || !_initialized) return;

    await _plugin.cancelAll();
    for (final entry in entries) {
      await scheduleBirthdayNotifications(entry, isKr: isKr);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Compute the next TZDateTime for a birthday (month/day) offset by [dayOffset]
  /// at [hour]:[minute]. Returns null if the computed date is in the past for
  /// this year AND next year (shouldn't happen for birthdays, but safety).
  static tz.TZDateTime? _nextOccurrence(
    int month,
    int day,
    int dayOffset,
    int hour,
    int minute,
  ) {
    final now = tz.TZDateTime.now(tz.local);

    // Target date this year
    var target = DateTime(now.year, month, day).add(Duration(days: dayOffset));
    var scheduled = tz.TZDateTime(
      tz.local,
      target.year,
      target.month,
      target.day,
      hour,
      minute,
    );

    // If already passed this year, schedule for next year
    if (scheduled.isBefore(now)) {
      target = DateTime(now.year + 1, month, day).add(Duration(days: dayOffset));
      scheduled = tz.TZDateTime(
        tz.local,
        target.year,
        target.month,
        target.day,
        hour,
        minute,
      );
    }

    return scheduled;
  }

  static Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'birthday_reminder',
      'Birthday Reminders',
      channelDescription: 'Notifications for upcoming birthdays',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      payload: 'birthday',
    );
  }

  static void _onTap(NotificationResponse response) {
    if (response.payload == 'birthday') {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) {
        GoRouter.of(ctx).go('/tools/birthday');
      }
    }
  }
}
