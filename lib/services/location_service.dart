import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/activity_models.dart' as mymodels;

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionStreamSubscription;
  mymodels.ActivitySession? _currentSession;
  Timer? _durationTimer;
  Position? _lastPosition;

  // Streams
  final StreamController<mymodels.ActivitySession> _sessionController = 
      StreamController<mymodels.ActivitySession>.broadcast();
  
  Stream<mymodels.ActivitySession> get sessionStream => _sessionController.stream;

  // Check and request location permissions
  Future<bool> checkAndRequestPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Get current position
  Future<LatLng?> getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }
  // Start tracking activity
  Future<bool> startActivity(mymodels.ActivityType type) async {
    try {
      final hasPermission = await checkAndRequestPermissions();
      if (!hasPermission) {
        return false;
      }

      // If there's already an active or paused session of the same type, don't create new one
      if (_currentSession != null && 
          _currentSession!.type == type &&
          (_currentSession!.status == mymodels.ActivityStatus.active || 
           _currentSession!.status == mymodels.ActivityStatus.paused)) {
        print('LocationService: Session already exists for ${type.toString()}, not creating new one');
        print('Existing session: ${_currentSession!.id} - ${_currentSession!.formattedDistance}, ${_currentSession!.formattedDuration}');
        // If paused, resume it
        if (_currentSession!.status == mymodels.ActivityStatus.paused) {
          resumeActivity();
        }
        return true;
      }

      // Only create new session if no current session exists or it's a different type/completed
      if (_currentSession == null || 
          _currentSession!.type != type ||
          _currentSession!.status == mymodels.ActivityStatus.completed) {
        
        print('LocationService: Creating new session for ${type.toString()}');
        
        // Create new activity session
        _currentSession = mymodels.ActivitySession(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: type,
          status: mymodels.ActivityStatus.active,
          startTime: DateTime.now(),
        );

        print('LocationService: New session created - ${_currentSession!.id}');
      }

      // Start position tracking
      _startPositionTracking();
      
      // Start duration timer
      _startDurationTimer();

      _sessionController.add(_currentSession!);
      return true;
    } catch (e) {
      print('Error starting activity: $e');
      return false;
    }
  }

  // Pause activity
  void pauseActivity() {
    if (_currentSession?.status == mymodels.ActivityStatus.active) {
      final now = DateTime.now();
      
      // Calculate current duration before pausing
      final startTime = _currentSession!.startTime!;
      final totalElapsed = now.difference(startTime);
      final currentActiveDuration = totalElapsed - _currentSession!.pausedDuration;
      
      _currentSession = _currentSession!.copyWith(
        status: mymodels.ActivityStatus.paused,
        pausedAt: now,
        duration: currentActiveDuration, // Save current duration
      );
      _stopTracking();
      _sessionController.add(_currentSession!);
    }
  }

  // Resume activity
  void resumeActivity() {
    if (_currentSession?.status == mymodels.ActivityStatus.paused) {
      final now = DateTime.now();
      
      // Calculate time spent paused and add to total paused duration
      if (_currentSession!.pausedAt != null) {
        final pauseTime = now.difference(_currentSession!.pausedAt!);
        final totalPausedDuration = _currentSession!.pausedDuration + pauseTime;
        
        _currentSession = _currentSession!.copyWith(
          status: mymodels.ActivityStatus.active,
          pausedAt: null,
          pausedDuration: totalPausedDuration,
          // Keep the duration that was saved during pause
        );
      } else {
        _currentSession = _currentSession!.copyWith(status: mymodels.ActivityStatus.active);
      }
      
      _startPositionTracking();
      _startDurationTimer();
      _sessionController.add(_currentSession!);
    }
  }

  // Stop activity
  void stopActivity() {
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        status: mymodels.ActivityStatus.completed,
        endTime: DateTime.now(),
      );
      _stopTracking();
      _sessionController.add(_currentSession!);
    }
  }

  // Start position tracking
  void _startPositionTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _updatePosition(position);
    });
  }

  // Update position and calculate metrics
  void _updatePosition(Position position) {
    if (_currentSession == null || _currentSession!.status != mymodels.ActivityStatus.active) {
      return;
    }

    final newLocation = LatLng(position.latitude, position.longitude);
    
    // Update current location
    _currentSession = _currentSession!.copyWith(currentLocation: newLocation);

    // Add to route
    final updatedRoute = List<LatLng>.from(_currentSession!.route)..add(newLocation);
    _currentSession = _currentSession!.copyWith(route: updatedRoute);

    // Calculate distance if we have a previous position
    if (_lastPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );

      final totalDistance = _currentSession!.distance + distance;
      _currentSession = _currentSession!.copyWith(distance: totalDistance);

      // Calculate current speed (m/s)
      final currentSpeed = position.speed.clamp(0.0, double.infinity);
      _currentSession = _currentSession!.copyWith(currentSpeed: currentSpeed);

      // Calculate average speed
      final durationInSeconds = _currentSession!.duration.inSeconds;
      final averageSpeed = durationInSeconds > 0 ? totalDistance / durationInSeconds : 0.0;
      _currentSession = _currentSession!.copyWith(averageSpeed: averageSpeed);

      // Calculate calories (rough estimation)
      final calories = _calculateCalories(totalDistance, _currentSession!.type);
      _currentSession = _currentSession!.copyWith(calories: calories);
    }

    _lastPosition = position;
    _sessionController.add(_currentSession!);
  }

  // Start duration timer
  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSession != null && _currentSession!.status == mymodels.ActivityStatus.active) {
        final startTime = _currentSession!.startTime!;
        final now = DateTime.now();
        
        // Calculate elapsed time excluding paused duration
        final totalElapsed = now.difference(startTime);
        final activeDuration = totalElapsed - _currentSession!.pausedDuration;
        
        // Only update if the duration has actually changed (to avoid unnecessary updates)
        if (activeDuration.inSeconds != _currentSession!.duration.inSeconds) {
          _currentSession = _currentSession!.copyWith(duration: activeDuration);
          _sessionController.add(_currentSession!);
        }
      }
    });
  }

  // Stop all tracking
  void _stopTracking() {
    _positionStreamSubscription?.cancel();
    _durationTimer?.cancel();
    _lastPosition = null;
  }

  // Calculate estimated calories burned
  int _calculateCalories(double distanceInMeters, mymodels.ActivityType type) {
    final distanceInKm = distanceInMeters / 1000;
    
    // Rough estimation based on activity type and distance
    // Assuming 70kg person
    switch (type) {
      case mymodels.ActivityType.running:
        return (distanceInKm * 62).round(); // ~62 calories per km for running
      case mymodels.ActivityType.cycling:
        return (distanceInKm * 25).round(); // ~25 calories per km for cycling
      case mymodels.ActivityType.walking:
        return (distanceInKm * 30).round(); // ~30 calories per km for walking
    }
  }

  // Get current session
  mymodels.ActivitySession? get currentSession => _currentSession;
  
  // Check if there's an active session
  bool get hasActiveSession => _currentSession != null && 
      (_currentSession!.status == mymodels.ActivityStatus.active || 
       _currentSession!.status == mymodels.ActivityStatus.paused);

  // Clean up resources
  void dispose() {
    _stopTracking();
    _sessionController.close();
    _currentSession = null;
  }
}
