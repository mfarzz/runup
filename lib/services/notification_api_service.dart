import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class NotificationApiService {
  // For Android emulator use 10.0.2.2, for physical device use your computer's IP
  // static const String baseUrl = 'https://apirunup.maturino.my.id/api'; // Android emulator
  static const String baseUrl = 'http://10.44.9.41:3000/api'; // Physical device (replace with your IP)
  // static const String baseUrl = 'http://localhost:3000/api'; // Web/Desktop
  
  // Get authentication token for API requests
  Future<String?> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }

  // Get common headers for API requests
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Get notification settings for user
  Future<NotificationSettings?> getNotificationSettings(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/settings/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return NotificationSettings.fromJson(data['data']);
        }
      }
      
      print('Failed to get notification settings: ${response.body}');
      return null;
      
    } catch (e) {
      print('Error getting notification settings: $e');
      return null;
    }
  }

  // Update notification settings for user
  Future<bool> updateNotificationSettings(String userId, NotificationSettings settings) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/settings/$userId'),
        headers: headers,
        body: json.encode(settings.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      }
      
      print('Failed to update notification settings: ${response.body}');
      return false;
      
    } catch (e) {
      print('Error updating notification settings: $e');
      return false;
    }
  }

  // Save FCM token to server
  Future<bool> saveFcmToken(String userId, String fcmToken) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/users/fcm-token'),
        headers: headers,
        body: json.encode({
          'userId': userId,
          'fcmToken': fcmToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      }
      
      print('Failed to save FCM token: ${response.body}');
      return false;
      
    } catch (e) {
      print('Error saving FCM token: $e');
      return false;
    }
  }

  // Update FCM token for user
  Future<bool> updateFCMToken(String userId, String token) async {
    try {
      print('=== FCM TOKEN UPDATE ===');
      print('User ID: $userId');
      print('Token: ${token.substring(0, 20)}...');
      
      final headers = await _getHeaders();
      print('Headers prepared');
      
      final url = '$baseUrl/users/$userId/fcm-token';
      print('URL: $url');
      
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode({
          'fcmToken': token,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final success = data['success'] ?? false;
        print('FCM token update success: $success');
        return success;
      }
      
      print('Failed to update FCM token: ${response.body}');
      return false;
      
    } catch (e) {
      print('Error updating FCM token: $e');
      return false;
    }
  }



  // Get notification history
  Future<List<NotificationHistory>> getNotificationHistory(String userId, {int limit = 50, int offset = 0}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/history/$userId?limit=$limit&offset=$offset'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final List<dynamic> historyList = data['data'];
          return historyList.map((item) => NotificationHistory.fromJson(item)).toList();
        }
      }
      
      print('Failed to get notification history: ${response.body}');
      return [];
      
    } catch (e) {
      print('Error getting notification history: $e');
      return [];
    }
  }

  // Remove FCM token from server
  Future<bool> removeFcmToken(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/users/fcm-token/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      }
      
      print('Failed to remove FCM token: ${response.body}');
      return false;
      
    } catch (e) {
      print('Error removing FCM token: $e');
      return false;
    }
  }
}

// Model classes for notification settings
class NotificationSettings {
  final DailyReminder dailyReminder;
  final WeeklyProgress weeklyProgress;
  final bool achievementNotifications;
  final bool motivationalMessages;
  final String? createdAt;
  final String? updatedAt;

  NotificationSettings({
    required this.dailyReminder,
    required this.weeklyProgress,
    required this.achievementNotifications,
    required this.motivationalMessages,
    this.createdAt,
    this.updatedAt,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      dailyReminder: DailyReminder.fromJson(json['dailyReminder']),
      weeklyProgress: WeeklyProgress.fromJson(json['weeklyProgress']),
      achievementNotifications: json['achievementNotifications'] ?? true,
      motivationalMessages: json['motivationalMessages'] ?? true,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyReminder': dailyReminder.toJson(),
      'weeklyProgress': weeklyProgress.toJson(),
      'achievementNotifications': achievementNotifications,
      'motivationalMessages': motivationalMessages,
    };
  }

  NotificationSettings copyWith({
    DailyReminder? dailyReminder,
    WeeklyProgress? weeklyProgress,
    bool? achievementNotifications,
    bool? motivationalMessages,
  }) {
    return NotificationSettings(
      dailyReminder: dailyReminder ?? this.dailyReminder,
      weeklyProgress: weeklyProgress ?? this.weeklyProgress,
      achievementNotifications: achievementNotifications ?? this.achievementNotifications,
      motivationalMessages: motivationalMessages ?? this.motivationalMessages,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class DailyReminder {
  final bool enabled;
  final String time; // Format: HH:MM
  final String message;
  final List<int> days; // 0=Sunday, 6=Saturday

  DailyReminder({
    required this.enabled,
    required this.time,
    required this.message,
    required this.days,
  });

  factory DailyReminder.fromJson(Map<String, dynamic> json) {
    return DailyReminder(
      enabled: json['enabled'] ?? true,
      time: json['time'] ?? '07:00',
      message: json['message'] ?? 'Good morning! Time for your daily workout! 💪',
      days: List<int>.from(json['days'] ?? [1, 2, 3, 4, 5]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'time': time,
      'message': message,
      'days': days,
    };
  }

  DailyReminder copyWith({
    bool? enabled,
    String? time,
    String? message,
    List<int>? days,
  }) {
    return DailyReminder(
      enabled: enabled ?? this.enabled,
      time: time ?? this.time,
      message: message ?? this.message,
      days: days ?? this.days,
    );
  }
}

class WeeklyProgress {
  final bool enabled;
  final int day; // 0=Sunday, 6=Saturday
  final String time; // Format: HH:MM
  final String message;

  WeeklyProgress({
    required this.enabled,
    required this.day,
    required this.time,
    required this.message,
  });

  factory WeeklyProgress.fromJson(Map<String, dynamic> json) {
    return WeeklyProgress(
      enabled: json['enabled'] ?? true,
      day: json['day'] ?? 0, // Sunday
      time: json['time'] ?? '19:00',
      message: json['message'] ?? 'Check out your weekly progress! 📊',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'day': day,
      'time': time,
      'message': message,
    };
  }

  WeeklyProgress copyWith({
    bool? enabled,
    int? day,
    String? time,
    String? message,
  }) {
    return WeeklyProgress(
      enabled: enabled ?? this.enabled,
      day: day ?? this.day,
      time: time ?? this.time,
      message: message ?? this.message,
    );
  }
}

class NotificationHistory {
  final String id;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final String status;
  final String sentAt;

  NotificationHistory({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
    required this.status,
    required this.sentAt,
  });

  factory NotificationHistory.fromJson(Map<String, dynamic> json) {
    return NotificationHistory(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      status: json['status'] ?? '',
      sentAt: json['sentAt'] ?? '',
    );
  }
}
