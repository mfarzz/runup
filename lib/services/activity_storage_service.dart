import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/activity_models.dart';
import 'firebase_activity_service.dart';

class ActivityStorageService {
  static final ActivityStorageService _instance = ActivityStorageService._internal();
  factory ActivityStorageService() => _instance;
  ActivityStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final FirebaseActivityService _firebaseService = FirebaseActivityService();
  static const String _activitiesKey = 'runup_saved_activities';
  static const String _lastSyncKey = 'last_firebase_sync';

  // Save an activity (hybrid: local + Firebase)
  Future<void> saveActivity(ActivitySession activity) async {
    try {
      // Always save locally first for offline support
      await _saveActivityLocally(activity);
      
      // Try to save to Firebase if user is authenticated
      if (_firebaseService.isUserAuthenticated) {
        final success = await _firebaseService.saveActivity(activity);
        if (success) {
          await _updateLastSyncTime();
          print('Activity saved to both local and Firebase');
        } else {
          print('Activity saved locally, Firebase sync failed');
        }
      } else {
        print('Activity saved locally only (user not authenticated)');
      }
    } catch (e) {
      print('Error in hybrid save: $e');
    }
  }

  // Save activity locally only
  Future<void> _saveActivityLocally(ActivitySession activity) async {
    try {
      final activities = await _getLocalActivities();
      activities.add(activity);
      
      // Keep only the last 50 activities to prevent storage overflow
      if (activities.length > 50) {
        activities.removeRange(0, activities.length - 50);
      }
      
      final jsonString = jsonEncode(activities.map((a) => _activityToMap(a)).toList());
      await _storage.write(key: _activitiesKey, value: jsonString);
      
      print('Activity saved locally. Total activities: ${activities.length}');
    } catch (e) {
      print('Error saving activity locally: $e');
    }
  }
  // Get all saved activities (hybrid: try cloud first, fallback to local)
  Future<List<ActivitySession>> getActivities() async {
    try {
      // If user is authenticated, try to get from Firebase first
      if (_firebaseService.isUserAuthenticated) {
        final firebaseActivities = await _firebaseService.getActivities();
        if (firebaseActivities.isNotEmpty) {
          print('Loaded ${firebaseActivities.length} activities from Firebase');
          return firebaseActivities;
        }
      }
      
      // Fallback to local storage
      return await _getActivitiesLocally();
    } catch (e) {
      print('Error loading activities, falling back to local: $e');
      return await _getActivitiesLocally();
    }
  }

  // Get activities from local storage only
  Future<List<ActivitySession>> _getActivitiesLocally() async {
    try {
      // Try new key first
      String? jsonString = await _storage.read(key: _activitiesKey);
      
      // If no data found, try old key for migration
      if (jsonString == null || jsonString.isEmpty) {
        jsonString = await _storage.read(key: 'saved_activities');
        
        // If old data exists, migrate it
        if (jsonString != null && jsonString.isNotEmpty) {
          print('Migrating activities from old storage key...');
          await _storage.write(key: _activitiesKey, value: jsonString);
          await _storage.delete(key: 'saved_activities');
          print('Migration completed');
        }
      }
      
      if (jsonString == null || jsonString.isEmpty) {
        print('No activities found in storage');
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final activities = jsonList.map((json) => _activityFromMap(json)).toList();
      
      print('Loaded ${activities.length} activities from storage');
      return activities;
    } catch (e) {
      print('Error loading activities: $e');
      return [];
    }
  }
  // Get recent activities (last 10)
  Future<List<ActivitySession>> getRecentActivities({int limit = 10}) async {
    try {
      // If user is authenticated, try to get from Firebase first
      if (_firebaseService.isUserAuthenticated) {
        final firebaseActivities = await _firebaseService.getRecentActivities(limit: limit);
        if (firebaseActivities.isNotEmpty) {
          return firebaseActivities;
        }
      }
      
      // Fallback to local storage
      final activities = await _getActivitiesLocally();
      activities.sort((a, b) => (b.endTime ?? DateTime.now()).compareTo(a.endTime ?? DateTime.now()));
      return activities.take(limit).toList();
    } catch (e) {
      print('Error loading recent activities, falling back to local: $e');
      final activities = await _getActivitiesLocally();
      activities.sort((a, b) => (b.endTime ?? DateTime.now()).compareTo(a.endTime ?? DateTime.now()));
      return activities.take(limit).toList();
    }
  }
  // Get activities for current week
  Future<List<ActivitySession>> getWeeklyActivities() async {
    try {
      // If user is authenticated, try to get from Firebase first
      if (_firebaseService.isUserAuthenticated) {
        final firebaseActivities = await _firebaseService.getWeeklyActivities();
        if (firebaseActivities.isNotEmpty) {
          return firebaseActivities;
        }
      }
      
      // Fallback to local storage
      final activities = await _getActivitiesLocally();
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);
      
      return activities.where((activity) {
        final activityDate = activity.endTime ?? activity.startTime;
        return activityDate != null && activityDate.isAfter(weekStartDay);
      }).toList();
    } catch (e) {
      print('Error loading weekly activities, falling back to local: $e');
      final activities = await _getActivitiesLocally();
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);      
      return activities.where((activity) {
        final activityDate = activity.endTime ?? activity.startTime;
        return activityDate != null && activityDate.isAfter(weekStartDay);
      }).toList();
    }
  }

  // Get weekly stats
  Future<Map<String, dynamic>> getWeeklyStats() async {
    try {
      final activities = await getWeeklyActivities();
      
      double totalDistance = 0;
      int totalDuration = 0; // in seconds
      int totalCalories = 0;
      
      for (final activity in activities) {
        totalDistance += activity.distance;
        totalDuration += activity.duration.inSeconds;
        totalCalories += activity.calories;
      }
      
      return {
        'distance': totalDistance,
        'duration': totalDuration, // Keep as int (seconds)
        'calories': totalCalories,
        'activities': activities.length,
      };
    } catch (e) {
      print('Error calculating weekly stats: $e');
      return {
        'distance': 0.0,
        'duration': 0,
        'calories': 0,
        'activities': 0,
      };
    }
  }

  // Delete an activity (hybrid: local + cloud)
  Future<void> deleteActivity(String activityId) async {
    try {
      // Delete from local storage
      await _deleteActivityLocally(activityId);
      
      // Try to delete from Firebase if user is authenticated
      if (_firebaseService.isUserAuthenticated) {
        await _firebaseService.deleteActivity(activityId);
      }
      
      print('Activity deleted successfully (local + cloud)');
    } catch (e) {
      print('Error deleting activity: $e');
    }
  }

  // Delete activity from local storage only
  Future<void> _deleteActivityLocally(String activityId) async {
    final activities = await _getActivitiesLocally();
    activities.removeWhere((activity) => activity.id == activityId);
    
    final jsonString = jsonEncode(activities.map((a) => _activityToMap(a)).toList());
    await _storage.write(key: _activitiesKey, value: jsonString);
  }
  // Clear all activities (hybrid: local + cloud)
  Future<void> clearAllActivities() async {
    try {
      // Clear local storage
      await _storage.delete(key: _activitiesKey);
      
      // Try to clear Firebase if user is authenticated
      if (_firebaseService.isUserAuthenticated) {
        await _firebaseService.clearAllActivities();
      }
      
      print('All activities cleared (local + cloud)');
    } catch (e) {
      print('Error clearing activities: $e');
    }
  }

  // Debug method to check if activities exist
  Future<bool> hasActivities() async {
    try {
      final jsonString = await _storage.read(key: _activitiesKey);
      final hasData = jsonString != null && jsonString.isNotEmpty;
      print('Has activities in storage: $hasData');
      return hasData;
    } catch (e) {
      print('Error checking activities: $e');
      return false;
    }
  }

  // Debug method to get raw storage data
  Future<String?> getRawActivitiesData() async {
    try {
      final data = await _storage.read(key: _activitiesKey);
      print('Raw activities data length: ${data?.length ?? 0}');
      return data;
    } catch (e) {
      print('Error getting raw data: $e');
      return null;
    }
  }

  // Sync local activities to Firebase (when user logs in)
  Future<bool> syncLocalActivitiesToFirebase() async {
    try {
      if (!_firebaseService.isUserAuthenticated) {
        print('User not authenticated, cannot sync to Firebase');
        return false;
      }

      final localActivities = await _getActivitiesLocally();
      if (localActivities.isEmpty) {
        print('No local activities to sync');
        return true;
      }

      final success = await _firebaseService.syncLocalActivitiesToFirebase(localActivities);
      if (success) {
        print('Successfully synced ${localActivities.length} activities to Firebase');
      }
      
      return success;
    } catch (e) {
      print('Error syncing activities to Firebase: $e');
      return false;
    }
  }

  // Sync local activities to Firebase
  Future<bool> syncLocalToFirebase() async {
    try {
      if (!_firebaseService.isUserAuthenticated) {
        print('User not authenticated, cannot sync to Firebase');
        return false;
      }

      final localActivities = await _getLocalActivities();
      if (localActivities.isEmpty) {
        print('No local activities to sync');
        return true;
      }

      final success = await _firebaseService.syncLocalActivitiesToFirebase(localActivities);
      if (success) {
        await _updateLastSyncTime();
        print('Successfully synced ${localActivities.length} activities to Firebase');
      }
      return success;
    } catch (e) {
      print('Error syncing local activities to Firebase: $e');
      return false;
    }
  }

  // Force sync from Firebase to local
  Future<bool> syncFirebaseToLocal() async {
    try {
      if (!_firebaseService.isUserAuthenticated) {
        print('User not authenticated, cannot sync from Firebase');
        return false;
      }

      final firebaseActivities = await _firebaseService.getActivities();
      await _syncFirebaseToLocal(firebaseActivities);
      return true;
    } catch (e) {
      print('Error syncing Firebase to local: $e');
      return false;
    }
  }

  // Check if data needs sync
  Future<bool> needsSync() async {
    if (!_firebaseService.isUserAuthenticated) return false;
    
    final lastSync = await getLastSyncTime();
    if (lastSync == null) return true;
    
    // Sync if last sync was more than 1 hour ago
    final now = DateTime.now();
    return now.difference(lastSync).inHours > 1;
  }

  // Get real-time stream of activities (only works when authenticated)
  Stream<List<ActivitySession>> getActivitiesStream() {
    if (_firebaseService.isUserAuthenticated) {
      return _firebaseService.getActivitiesStream();
    } else {
      // Return empty stream for unauthenticated users
      return Stream.value([]);
    }
  }

  // Check if user is authenticated for Firebase features
  bool get isFirebaseEnabled => _firebaseService.isUserAuthenticated;

  // Convert ActivitySession to Map for JSON serialization
  Map<String, dynamic> _activityToMap(ActivitySession activity) {
    return {
      'id': activity.id,
      'type': activity.type.toString(),
      'status': activity.status.toString(),
      'startTime': activity.startTime?.millisecondsSinceEpoch,
      'endTime': activity.endTime?.millisecondsSinceEpoch,
      'duration': activity.duration.inMilliseconds,
      'distance': activity.distance,
      'averageSpeed': activity.averageSpeed,
      'currentSpeed': activity.currentSpeed,
      'calories': activity.calories,
      'route': activity.route.map((point) => {
        'latitude': point.latitude,
        'longitude': point.longitude,
      }).toList(),
      'currentLocation': activity.currentLocation != null ? {
        'latitude': activity.currentLocation!.latitude,
        'longitude': activity.currentLocation!.longitude,
      } : null,
    };
  }

  // Convert Map to ActivitySession from JSON deserialization
  ActivitySession _activityFromMap(Map<String, dynamic> map) {
    return ActivitySession(
      id: map['id'],
      type: ActivityType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => ActivityType.running,
      ),
      status: ActivityStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => ActivityStatus.completed,
      ),
      startTime: map['startTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['startTime'])
          : null,
      endTime: map['endTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['endTime'])
          : null,
      duration: Duration(milliseconds: map['duration'] ?? 0),
      distance: map['distance']?.toDouble() ?? 0.0,
      averageSpeed: map['averageSpeed']?.toDouble() ?? 0.0,
      currentSpeed: map['currentSpeed']?.toDouble() ?? 0.0,
      calories: map['calories'] ?? 0,
      route: (map['route'] as List?)?.map((point) => 
        LatLng(point['latitude'], point['longitude'])
      ).toList() ?? [],
      currentLocation: map['currentLocation'] != null 
          ? LatLng(
              map['currentLocation']['latitude'],
              map['currentLocation']['longitude'],
            )
          : null,
    );
  }

  // Get local activities only
  Future<List<ActivitySession>> _getLocalActivities() async {
    try {
      // Try new key first
      String? jsonString = await _storage.read(key: _activitiesKey);
      
      // If no data found, try old key for migration
      if (jsonString == null || jsonString.isEmpty) {
        jsonString = await _storage.read(key: 'saved_activities');
        
        // If old data exists, migrate it
        if (jsonString != null && jsonString.isNotEmpty) {
          print('Migrating activities from old storage key...');
          await _storage.write(key: _activitiesKey, value: jsonString);
          await _storage.delete(key: 'saved_activities');
          print('Migration completed');
        }
      }
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => _activityFromMap(json)).toList();
    } catch (e) {
      print('Error loading local activities: $e');
      return [];
    }
  }

  // Update last sync time
  Future<void> _updateLastSyncTime() async {
    try {
      await _storage.write(
        key: _lastSyncKey, 
        value: DateTime.now().millisecondsSinceEpoch.toString()
      );
    } catch (e) {
      print('Error updating sync time: $e');
    }
  }

  // Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    try {
      final syncTimeString = await _storage.read(key: _lastSyncKey);
      if (syncTimeString != null) {
        return DateTime.fromMillisecondsSinceEpoch(int.parse(syncTimeString));
      }
    } catch (e) {
      print('Error getting sync time: $e');
    }
    return null;
  }

  // Sync Firebase data to local storage
  Future<void> _syncFirebaseToLocal(List<ActivitySession> firebaseActivities) async {
    try {
      final jsonString = jsonEncode(firebaseActivities.map((a) => _activityToMap(a)).toList());
      await _storage.write(key: _activitiesKey, value: jsonString);
      await _updateLastSyncTime();
      print('Firebase activities synced to local storage');
    } catch (e) {
      print('Error syncing Firebase to local: $e');
    }
  }
}
