import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/activity_models.dart';

class FirebaseActivityService {
  static final FirebaseActivityService _instance = FirebaseActivityService._internal();
  factory FirebaseActivityService() => _instance;
  FirebaseActivityService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user's activities collection reference
  CollectionReference<Map<String, dynamic>>? get _activitiesCollection {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('activities');
  }

  // Check if user is authenticated
  bool get isUserAuthenticated => _auth.currentUser != null;

  // Save an activity to Firestore
  Future<bool> saveActivity(ActivitySession activity) async {
    try {
      if (!isUserAuthenticated) {
        print('User not authenticated, cannot save to Firebase');
        return false;
      }

      final collection = _activitiesCollection;
      if (collection == null) return false;

      final activityData = _activityToMap(activity);
      
      // Use activity ID as document ID for consistency
      await collection.doc(activity.id).set(activityData);
      
      print('Activity saved to Firebase successfully: ${activity.id}');
      return true;
    } catch (e) {
      print('Error saving activity to Firebase: $e');
      return false;
    }
  }

  // Get all activities from Firestore
  Future<List<ActivitySession>> getActivities() async {
    try {
      if (!isUserAuthenticated) {
        print('User not authenticated, cannot fetch from Firebase');
        return [];
      }

      final collection = _activitiesCollection;
      if (collection == null) return [];

      final querySnapshot = await collection
          .orderBy('endTime', descending: true)
          .get();

      final activities = querySnapshot.docs
          .map((doc) => _activityFromMap(doc.data()))
          .toList();

      print('Loaded ${activities.length} activities from Firebase');
      return activities;
    } catch (e) {
      print('Error loading activities from Firebase: $e');
      return [];
    }
  }

  // Get recent activities with limit
  Future<List<ActivitySession>> getRecentActivities({int limit = 10}) async {
    try {
      if (!isUserAuthenticated) {
        print('User not authenticated, cannot fetch from Firebase');
        return [];
      }

      final collection = _activitiesCollection;
      if (collection == null) return [];

      final querySnapshot = await collection
          .orderBy('endTime', descending: true)
          .limit(limit)
          .get();

      final activities = querySnapshot.docs
          .map((doc) => _activityFromMap(doc.data()))
          .toList();

      print('Loaded ${activities.length} recent activities from Firebase');
      return activities;
    } catch (e) {
      print('Error loading recent activities from Firebase: $e');
      return [];
    }
  }

  // Get activities for current week
  Future<List<ActivitySession>> getWeeklyActivities() async {
    try {
      if (!isUserAuthenticated) {
        print('User not authenticated, cannot fetch from Firebase');
        return [];
      }

      final collection = _activitiesCollection;
      if (collection == null) return [];

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);

      final querySnapshot = await collection
          .where('endTime', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStartDay))
          .orderBy('endTime', descending: true)
          .get();

      final activities = querySnapshot.docs
          .map((doc) => _activityFromMap(doc.data()))
          .toList();

      print('Loaded ${activities.length} weekly activities from Firebase');
      return activities;
    } catch (e) {
      print('Error loading weekly activities from Firebase: $e');
      return [];
    }
  }

  // Get weekly stats
  Future<Map<String, dynamic>> getWeeklyStats() async {
    final weeklyActivities = await getWeeklyActivities();
    
    double totalDistance = 0;
    Duration totalDuration = Duration.zero;
    int totalCalories = 0;
    
    for (final activity in weeklyActivities) {
      totalDistance += activity.distance;
      totalDuration += activity.duration;
      totalCalories += activity.calories;
    }
    
    return {
      'distance': totalDistance,
      'duration': totalDuration,
      'calories': totalCalories,
      'activitiesCount': weeklyActivities.length,
    };
  }

  // Delete an activity from Firestore
  Future<bool> deleteActivity(String activityId) async {
    try {
      if (!isUserAuthenticated) {
        print('User not authenticated, cannot delete from Firebase');
        return false;
      }

      final collection = _activitiesCollection;
      if (collection == null) return false;

      await collection.doc(activityId).delete();
      
      print('Activity deleted from Firebase successfully: $activityId');
      return true;
    } catch (e) {
      print('Error deleting activity from Firebase: $e');
      return false;
    }
  }

  // Clear all activities from Firestore
  Future<bool> clearAllActivities() async {
    try {
      if (!isUserAuthenticated) {
        print('User not authenticated, cannot clear Firebase data');
        return false;
      }

      final collection = _activitiesCollection;
      if (collection == null) return false;

      final batch = _firestore.batch();
      final querySnapshot = await collection.get();
      
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      
      print('All activities cleared from Firebase');
      return true;
    } catch (e) {
      print('Error clearing activities from Firebase: $e');
      return false;
    }
  }

  // Get real-time stream of activities
  Stream<List<ActivitySession>> getActivitiesStream() {
    if (!isUserAuthenticated) {
      return Stream.value([]);
    }

    final collection = _activitiesCollection;
    if (collection == null) return Stream.value([]);

    return collection
        .orderBy('endTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => _activityFromMap(doc.data()))
          .toList();
    });
  }

  // Sync local activities to Firebase
  Future<bool> syncLocalActivitiesToFirebase(List<ActivitySession> localActivities) async {
    try {
      if (!isUserAuthenticated) {
        print('User not authenticated, cannot sync to Firebase');
        return false;
      }

      final collection = _activitiesCollection;
      if (collection == null) return false;

      final batch = _firestore.batch();
      
      for (final activity in localActivities) {
        final docRef = collection.doc(activity.id);
        batch.set(docRef, _activityToMap(activity));
      }
      
      await batch.commit();
      
      print('Synced ${localActivities.length} local activities to Firebase');
      return true;
    } catch (e) {
      print('Error syncing local activities to Firebase: $e');
      return false;
    }
  }

  // Convert ActivitySession to Map for Firestore
  Map<String, dynamic> _activityToMap(ActivitySession activity) {
    return {
      'id': activity.id,
      'type': activity.type.toString(),
      'status': activity.status.toString(),
      'startTime': activity.startTime != null 
          ? Timestamp.fromDate(activity.startTime!) 
          : null,
      'endTime': activity.endTime != null 
          ? Timestamp.fromDate(activity.endTime!) 
          : null,
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
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Convert Map to ActivitySession from Firestore
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
          ? (map['startTime'] as Timestamp).toDate()
          : null,
      endTime: map['endTime'] != null 
          ? (map['endTime'] as Timestamp).toDate()
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
}
