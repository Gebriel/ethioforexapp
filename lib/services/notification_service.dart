import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../screens/summary_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _notificationEnabledKey = 'notifications_enabled';
  static const String _firstLaunchKey = 'first_launch_done';
  static const int _dailyNotificationId = 1;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  Function(String)? _onNotificationTapCallback;

  /// Call this from main() to initialize
  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Get notification launch details - ADD THIS METHOD
  Future<NotificationAppLaunchDetails?> getNotificationAppLaunchDetails() async {
    return await _flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  }

  /// Call from main.dart to link tap to navigation
  void setNotificationTapCallback(Function(String) callback) {
    _onNotificationTapCallback = callback;
  }

  /// Called internally on notification tap
  Future<void> _onNotificationTapped(NotificationResponse response) async {
    final payload = response.payload;
    if (payload != null && _onNotificationTapCallback != null) {
      _onNotificationTapCallback!(payload);
    }
  }

  /// First-launch and permission check
  Future<bool> checkAndRequestPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = !(prefs.getBool(_firstLaunchKey) ?? false);

    if (isFirstLaunch) {
      final permission = await Permission.notification.request();

      if (permission.isGranted) {
        await prefs.setBool(_notificationEnabledKey, true);
        await prefs.setBool(_firstLaunchKey, true);
        await scheduleDailyNotification();
        return true;
      } else {
        await prefs.setBool(_notificationEnabledKey, false);
        await prefs.setBool(_firstLaunchKey, true);
        return false;
      }
    }

    final permission = await Permission.notification.status;
    return permission.isGranted;
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationEnabledKey) ?? false;
  }

  Future<void> enableNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationEnabledKey, true);

    final permission = await Permission.notification.status;
    if (permission.isGranted) {
      await scheduleDailyNotification();
    } else {
      final newPermission = await Permission.notification.request();
      if (newPermission.isGranted) {
        await scheduleDailyNotification();
      }
    }
  }

  Future<void> disableNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationEnabledKey, false);
    await cancelDailyNotification();
  }

  Future<void> scheduleDailyNotification() async {
    await cancelDailyNotification();

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        _dailyNotificationId,
        'USD Exchange Rates Update',
        'Check the latest USD exchange rates from Ethiopian banks',
        _nextInstanceOfTime(14, 00),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_forex_channel',
            'Daily Forex Updates',
            channelDescription: 'Daily notifications for USD exchange rates',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            showWhen: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'usd_summary',
      );
    } catch (e) {
      print('Error scheduling notification: $e');
      await _scheduleNotificationFallback();
    }
  }

  Future<void> _scheduleNotificationFallback() async {
    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        _dailyNotificationId,
        'USD Exchange Rates Update',
        'Check the latest USD exchange rates from Ethiopian banks',
        _nextInstanceOfTime(9, 0),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_forex_channel',
            'Daily Forex Updates',
            channelDescription: 'Daily notifications for USD exchange rates',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            showWhen: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'usd_summary',
      );
    } catch (e) {
      print('Fallback scheduling also failed: $e');
    }
  }

  Future<void> cancelDailyNotification() async {
    await _flutterLocalNotificationsPlugin.cancel(_dailyNotificationId);
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Test notification channel',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      'Test Notification',
      'This is a test notification from EthioForex',
      notificationDetails,
      payload: 'usd_summary',
    );
  }
}