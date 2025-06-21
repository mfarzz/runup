import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../main.dart' show navigatorKey;
import '../models/activity_models.dart';
import 'notification_api_service.dart' as api;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  final api.NotificationApiService _apiService = api.NotificationApiService();

  // Notification IDs
  static const int dailyReminderID = 1;
  static const int weeklyProgressID = 2;  static const int achievementID = 3;
  static const int motivationalID = 4;
  static const int targetReminderID = 5;

  Future<void> initialize() async {
    if (_isInitialized) return;    // Initialize timezone dengan zona waktu lokal
    tz.initializeTimeZones();
    
    // Set zona waktu ke zona waktu perangkat
    final String timeZoneName = await _getDeviceTimeZone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Android initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _requestPermissions();    _isInitialized = true;
  }
  Future<void> _requestPermissions() async {
    // Skip permission request untuk web platform
    if (kIsWeb) {
      return;
    }
    
    try {
      if (Platform.isAndroid) {
        final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidPlugin != null) {
          await androidPlugin.requestNotificationsPermission();
          await androidPlugin.requestExactAlarmsPermission();
        }
      } else if (Platform.isIOS) {
        final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        
        await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      print('Error requesting notifications permissions: $e');
    }
  }
  void _onNotificationTapped(NotificationResponse response) {
    // Get current context from global navigator key
    final context = navigatorKey.currentContext;
    
    if (context != null) {
      // Handle different notification types based on payload
      switch (response.payload) {
        case 'daily_reminder':
          // Navigate to home screen for daily reminders
          context.go('/');
          break;
        case 'weekly_progress':
          // Navigate to weekly stats screen for progress notifications
          context.go('/weekly-stats');
          break;
        case 'achievement':
          // Navigate to profile screen for achievements
          context.go('/profile');
          break;
        default:
          // Default navigation to home screen
          context.go('/');
          break;
      }
    }
  }
  // Schedule daily reminder notifications (uses local scheduling + server-side FCM)
  Future<void> scheduleDailyReminder({
    int hour = 07, // 7 AM
    int minute = 00, // 00 minutes
    String? customMessage,
  }) async {
    if (!_isInitialized) await initialize();

    final message = customMessage ?? "Time for your daily workout! 💪";
    
    // Local notification as backup (in case FCM server is down)
    await _notifications.zonedSchedule(
      dailyReminderID,
      'RunUp Fitness Reminder',
      message,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Workout Reminders',
          channelDescription: 'Daily reminders to stay active',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF00D4FF),
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          sound: 'default',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_reminder',
    );

    // NOTE: Server-side FCM scheduling is handled by the notification scheduler service
    // The server will send FCM notifications based on user preferences in the database
    }

  // Schedule weekly progress notification
  Future<void> scheduleWeeklyProgress({
    int weekday = DateTime.sunday, // Sunday
    int hour = 19, // 7 PM
    int minute = 0,
  }) async {
    if (!_isInitialized) await initialize();

    await _notifications.zonedSchedule(
      weeklyProgressID,
      'Weekly Progress Summary 📊',
      'Check out your amazing progress this week!',
      _nextInstanceOfWeekday(weekday, hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_progress',
          'Weekly Progress',
          channelDescription: 'Weekly fitness progress summaries',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF5856D6),
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          sound: 'default',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'weekly_progress',
    );  }
  // Send achievement notification via FCM
  Future<void> showAchievementNotification({
    required String title,
    required String message,
    String? bigText,
  }) async {
    // Send via FCM first
    await sendFCMNotification(
      title: '🏆 $title',
      body: message,
      type: 'achievement',
      data: {
        'bigText': bigText ?? message,
        'achievement': 'true',
      },
    );
    }
  // Send motivational notification via FCM
  Future<void> showMotivationalNotification() async {
    final messages = [
      "You're doing great! Keep up the momentum! 🚀",
      "Every step counts towards your goal! 👟",
      "Your consistency is paying off! 💪",
      "Time to crush today's workout! 🔥",
      "You're stronger than yesterday! 💪",
      "Make today count - you've got this! ⭐",
      "Your future self will thank you! 🌟",
      "Progress, not perfection! 📈",
    ];

    final message = messages[DateTime.now().millisecond % messages.length];

    // Send via FCM
    await sendFCMNotification(
      title: 'Stay Motivated! 🌟',
      body: message,
      type: 'motivational',
      data: {
        'category': 'motivation',
      },
    );  }

  // Check and notify about personal records
  Future<void> checkPersonalRecords(ActivitySession newActivity, List<ActivitySession> allActivities) async {
    // Check for longest distance
    final previousBestDistance = allActivities
        .where((a) => a.type == newActivity.type && a.id != newActivity.id)
        .map((a) => a.distance)
        .fold(0.0, (prev, curr) => curr > prev ? curr : prev);

    if (newActivity.distance > previousBestDistance && previousBestDistance > 0) {
      await showAchievementNotification(
        title: '🏆 New Distance Record!',
        message: 'You just completed your longest ${newActivity.activityTypeText.toLowerCase()} ever!',
        bigText: 'Distance: ${newActivity.formattedDistance}\nPrevious best: ${_formatDistance(previousBestDistance)}\nKeep breaking those records! 🚀',
      );
    }

    // Check for longest duration
    final previousBestDuration = allActivities
        .where((a) => a.type == newActivity.type && a.id != newActivity.id)
        .map((a) => a.duration)
        .fold(Duration.zero, (prev, curr) => curr > prev ? curr : prev);

    if (newActivity.duration > previousBestDuration && previousBestDuration > Duration.zero) {
      await showAchievementNotification(
        title: '⏱️ New Duration Record!',
        message: 'You just had your longest ${newActivity.activityTypeText.toLowerCase()} session!',
        bigText: 'Duration: ${newActivity.formattedDuration}\nPrevious best: ${_formatDuration(previousBestDuration)}\nYour endurance is improving! 💪',
      );
    }

    // Check milestones
    await _checkDistanceMilestones(newActivity, allActivities);
  }

  Future<void> _checkDistanceMilestones(ActivitySession newActivity, List<ActivitySession> allActivities) async {
    final totalDistance = allActivities.fold(0.0, (sum, activity) => sum + activity.distance);
    final milestones = [1000, 5000, 10000, 25000, 50000, 100000]; // in meters

    for (final milestone in milestones) {
      final previousTotal = totalDistance - newActivity.distance;
      if (previousTotal < milestone && totalDistance >= milestone) {
        final kmMilestone = milestone / 1000;
        await showAchievementNotification(
          title: '🎯 Milestone Achieved!',
          message: 'You\'ve completed ${kmMilestone}km total!',
          bigText: 'Total distance: ${_formatDistance(totalDistance)}\nYou\'re absolutely crushing it! Keep up the amazing work! 🌟',
        );
        break; // Only show one milestone at a time
      }
    }
  }

  // Schedule inactivity reminder
  Future<void> scheduleInactivityReminder(int daysInactive) async {
    if (!_isInitialized) await initialize();

    String message;
    if (daysInactive == 1) {
      message = "We miss you! Ready for a quick workout? 🏃‍♂️";
    } else if (daysInactive <= 3) {
      message = "It's been $daysInactive days - time to get moving again! 💪";
    } else {
      message = "Your fitness journey is waiting! Let's get back on track! 🚀";
    }

    await _notifications.show(
      targetReminderID + daysInactive,
      'Come Back to RunUp! 👋',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'inactivity',
          'Inactivity Reminders',
          channelDescription: 'Reminders when you haven\'t been active',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF00D4FF),
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          sound: 'default',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'inactivity_$daysInactive',
    );
  }

  // Cancel specific notifications
  Future<void> cancelDailyReminder() async {
    await _notifications.cancel(dailyReminderID);
  }

  Future<void> cancelWeeklyProgress() async {
    await _notifications.cancel(weeklyProgressID);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Send immediate test notification
  Future<void> sendImmediateTestNotification() async {
    if (!_isInitialized) await initialize();

    await _notifications.show(
      999, // Test notification ID
      'Test Notification',
      'This is a test notification sent immediately!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Notifications',
          channelDescription: 'Test notifications for debugging',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF00D4FF),
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          sound: 'default',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'test_notification',
    );
    
    print('Test notification sent immediately');
  }

  // Check if notifications are scheduled and show their next trigger time
  Future<void> showScheduledNotifications() async {
    print('=== SCHEDULED NOTIFICATIONS ===');
    
    final now = tz.TZDateTime.now(tz.local);
    print('Current time: ${now.toString()}');
    
    // Calculate next daily reminder time
    final nextDaily = _nextInstanceOfTime(07, 00); // Updated to current settings
    print('Next daily reminder: ${nextDaily.toString()}');
    
    // Calculate next weekly progress time  
    final nextWeekly = _nextInstanceOfWeekday(DateTime.sunday, 19, 0);
    print('Next weekly progress: ${nextWeekly.toString()}');
    
    print('===============================');
  }
  // Send test notification via FCM
  Future<void> showTestNotification({
    String title = 'Test Notification',
    String message = 'This is a test notification from RunUp!',
  }) async {
    // Send via FCM
    await sendFCMNotification(
      title: title,
      body: message,
      type: 'test',
      data: {
        'test': 'true',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    print('Test notification processed: $title - $message');
  }

  // Schedule notification for a specific time (within next 5 minutes for testing)
  Future<void> scheduleTestReminder({
    int delayMinutes = 1,
    String? customMessage,
  }) async {
    if (!_isInitialized) await initialize();

    final message = customMessage ?? "Test reminder from RunUp! 🔔";
    final scheduledTime = tz.TZDateTime.now(tz.local).add(Duration(minutes: delayMinutes));
    
    await _notifications.zonedSchedule(
      998, // Test reminder ID
      'Test Reminder',
      message,
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_reminders',
          'Test Reminders',
          channelDescription: 'Test reminders with specific timing',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFFF9500),
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          sound: 'default',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'test_reminder',
    );

    print('Test reminder scheduled for ${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')} (in $delayMinutes minutes)');
  }

  // Schedule a test notification in X seconds
  Future<void> scheduleTestNotificationIn({
    required int seconds,
    String? customTitle,
    String? customMessage,
  }) async {
    if (!_isInitialized) await initialize();

    final now = tz.TZDateTime.now(tz.local);
    final scheduledTime = now.add(Duration(seconds: seconds));
    
    final title = customTitle ?? 'RunUp Test Notification ⏰';
    final message = customMessage ?? 'This notification was scheduled $seconds seconds ago!';
    
    await _notifications.zonedSchedule(
      999, // Test notification ID
      title,
      message,
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_scheduled',
          'Scheduled Test Notifications',
          channelDescription: 'Test notifications with custom timing',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF00D4FF),
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          sound: 'default',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'test_scheduled',
    );
    
    print('Test notification scheduled for: $scheduledTime ($seconds seconds from now)');
  }

  // Get device timezone
  Future<String> _getDeviceTimeZone() async {
    try {
      // Untuk Indonesia biasanya 'Asia/Jakarta'
      // Tapi kita bisa coba deteksi otomatis
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      
      // Indonesia Western Time (WIB) = UTC+7
      if (offset.inHours == 7) {
        return 'Asia/Jakarta';
      }
      // Indonesia Central Time (WITA) = UTC+8  
      else if (offset.inHours == 8) {
        return 'Asia/Makassar';
      }
      // Indonesia Eastern Time (WIT) = UTC+9
      else if (offset.inHours == 9) {
        return 'Asia/Jayapura';
      }
      
      // Default fallback untuk zona waktu lain
      print('Unknown timezone offset: ${offset.inHours}h, using UTC');
      return 'UTC';
    } catch (e) {
      print('Error getting timezone: $e, defaulting to Asia/Jakarta');
      return 'Asia/Jakarta';
    }
  }

  // Debug timezone information
  Future<void> debugTimezone() async {
    print('=== TIMEZONE DEBUG ===');
    
    final deviceTime = DateTime.now();
    final tzTime = tz.TZDateTime.now(tz.local);
    final offset = deviceTime.timeZoneOffset;
    
    print('Device time: $deviceTime');
    print('TZ time: $tzTime');
    print('Timezone offset: ${offset.inHours}h ${offset.inMinutes % 60}m');
    print('Timezone name: ${tz.local.name}');
    
    // Test next notification time
    final nextDaily = _nextInstanceOfTime(08, 22);
    print('Next daily notification: $nextDaily');
    
    print('=====================');
  }

  // Helper methods
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    print('--- Scheduling Debug ---');
    print('Current time: $now');
    print('Target time today: $scheduledDate');
    print('Is target before now? ${scheduledDate.isBefore(now)}');
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
      print('Scheduled for tomorrow: $scheduledDate');
    } else {
      print('Scheduled for today: $scheduledDate');
    }
    
    final difference = scheduledDate.difference(now);
    print('Time until notification: ${difference.inHours}h ${difference.inMinutes % 60}m');
    print('----------------------');
    
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);
    
    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }


  String _formatDistance(double distance) {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    } else {
      return '${distance.toInt()} m';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
  // Check notification permissions
  Future<bool> areNotificationsEnabled() async {
    // Return true untuk web platform
    if (kIsWeb) {
      return true;
    }
    
    try {
      if (Platform.isAndroid) {
        final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await androidPlugin?.areNotificationsEnabled() ?? false;
      }
      return true; // iOS handles this differently
    } catch (e) {
      print('Error checking notification permissions: $e');
      return false;
    }
  }

  // Get pending notifications count
  Future<int> getPendingNotificationsCount() async {
    final pending = await _notifications.pendingNotificationRequests();
    return pending.length;
  }

  // Get all pending notifications (Android/iOS)
  Future<void> checkPendingNotifications() async {
    try {
      final List<PendingNotificationRequest> pendingNotifications = 
          await _notifications.pendingNotificationRequests();
      
      print('=== PENDING NOTIFICATIONS ===');
      print('Total pending: ${pendingNotifications.length}');
      
      if (pendingNotifications.isEmpty) {
        print('No pending notifications found');
      } else {
        for (var notification in pendingNotifications) {
          print('ID: ${notification.id}');
          print('Title: ${notification.title}');
          print('Body: ${notification.body}');
          print('Payload: ${notification.payload}');
          print('---');
        }
      }
      print('============================');
    } catch (e) {
      print('Error checking pending notifications: $e');
    }
  }

  // Force reschedule daily notification (useful for debugging)
  Future<void> forceRescheduleDaily({
    int hour = 08,
    int minute = 22,
  }) async {
    try {
      // Cancel existing daily reminder
      await _notifications.cancel(dailyReminderID);
      print('Canceled existing daily reminder');
      
      // Schedule new one
      await scheduleDailyReminder(hour: hour, minute: minute);
      print('Rescheduled daily reminder for $hour:${minute.toString().padLeft(2, '0')}');
    } catch (e) {
      print('Error rescheduling daily reminder: $e');
    }
  }  // FCM implementation for push notifications
  Future<void> initializeFCM() async {
    try {
      final messaging = FirebaseMessaging.instance;
      
      // Request permission for notifications
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted FCM permission');
        
        // Get the token
        String? token = await messaging.getToken();
        if (token != null) {
          await _updateFCMToken(token);
        }

        // Listen for token refresh
        FirebaseMessaging.instance.onTokenRefresh.listen(_updateFCMToken);

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle background messages
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
        
        // Handle notification taps when app is in background
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
        
        print('FCM initialized successfully');
      } else {
        print('User declined FCM permission');
      }
    } catch (e) {
      print('Error initializing FCM: $e');
    }
  }
  Future<void> _updateFCMToken(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('Updating FCM token for user: ${user.uid}');
        final success = await _apiService.updateFCMToken(user.uid, token);
        if (success) {
          print('FCM token updated successfully: $token');
        } else {
          print('Failed to update FCM token on server');
        }
      } else {
        print('Cannot update FCM token: User not authenticated');
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');
    
    // Show local notification for foreground messages
    _showFCMNotification(message);
  }

  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.messageId}');
    
    // Handle navigation based on notification data
    final context = navigatorKey.currentContext;
    if (context != null) {
      final data = message.data;
      final type = data['type'];
      
      switch (type) {
        case 'daily_reminder':
          context.go('/home');
          break;
        case 'weekly_progress':
          context.go('/weekly-stats');
          break;
        case 'achievement':
          context.go('/profile');
          break;
        default:
          context.go('/home');
      }
    }
  }

  Future<void> _showFCMNotification(RemoteMessage message) async {
    if (!_isInitialized) await initialize();

    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      await _notifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'fcm_notifications',
            'FCM Notifications',
            channelDescription: 'Firebase Cloud Messaging notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: const Color(0xFF00D4FF),
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            sound: 'default',
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: data.toString(),
      );
    }
  }

  // Background message handler (must be top-level function)
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('Handling background message: ${message.messageId}');
    // Background processing can be done here
  }
  // Send FCM notification via server
  Future<void> sendFCMNotification({
    required String title,
    required String body,
    String? type,
    Map<String, String>? data,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User not authenticated, cannot send FCM notification');
        return;
      }
      
      // For now, use local notification as fallback since server handles scheduled notifications automatically
      await _showLocalNotification(title, body, type ?? 'general');
    } catch (e) {
      print('Error sending FCM notification: $e');
      // Fallback to local notification
      await _showLocalNotification(title, body, type ?? 'general');
    }
  }

  // Local notification fallback
  Future<void> _showLocalNotification(String title, String body, String type) async {
    if (!_isInitialized) await initialize();

    int notificationId;
    String channelId;
    String channelName;
    Color color;

    switch (type) {
      case 'daily_reminder':
        notificationId = dailyReminderID;
        channelId = 'daily_reminders';
        channelName = 'Daily Reminders';
        color = const Color(0xFF00E676);
        break;
      case 'weekly_progress':
        notificationId = weeklyProgressID;
        channelId = 'weekly_progress';
        channelName = 'Weekly Progress';
        color = const Color(0xFF2196F3);
        break;
      case 'achievement':
        notificationId = achievementID;
        channelId = 'achievements';
        channelName = 'Achievements';
        color = const Color(0xFFFF9500);
        break;
      default:
        notificationId = motivationalID;
        channelId = 'motivational';
        channelName = 'Motivational';
        color = const Color(0xFF9C27B0);
    }

    await _notifications.show(
      notificationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'RunUp $channelName notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: color,
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          sound: 'default',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: type,
    );
  }

  // Force FCM token registration (call after user login)
  Future<void> registerFCMTokenForCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('Cannot register FCM token: User not authenticated');
        return;
      }

      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      
      if (token != null) {
        print('Registering FCM token for user: ${user.uid}');
        await _updateFCMToken(token);
      } else {
        print('FCM token is null, cannot register');
      }
    } catch (e) {
      print('Error registering FCM token: $e');
    }
  }
}
