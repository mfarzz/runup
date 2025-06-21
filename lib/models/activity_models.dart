import 'package:google_maps_flutter/google_maps_flutter.dart';

enum ActivityType {
  running,
  cycling,
  walking,
}

enum ActivityStatus {
  notStarted,
  active,
  paused,
  completed,
}

class ActivitySession {
  final String id;
  final ActivityType type;
  ActivityStatus status;
  DateTime? startTime;
  DateTime? endTime;
  DateTime? pausedAt;
  Duration pausedDuration; // Total time spent paused
  Duration duration;
  double distance; // in meters
  double averageSpeed; // in m/s
  double currentSpeed; // in m/s
  List<LatLng> route;
  LatLng? currentLocation;
  int calories;

  ActivitySession({
    required this.id,
    required this.type,
    this.status = ActivityStatus.notStarted,
    this.startTime,
    this.endTime,
    this.pausedAt,
    this.pausedDuration = Duration.zero,
    this.duration = Duration.zero,
    this.distance = 0.0,
    this.averageSpeed = 0.0,
    this.currentSpeed = 0.0,
    this.route = const [],
    this.currentLocation,
    this.calories = 0,
  });

  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  String get formattedDistance {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(2)} km';
    }
  }

  String get formattedSpeed {
    final kmh = (currentSpeed * 3.6);
    return '${kmh.toStringAsFixed(1)} km/h';
  }

  String get formattedAverageSpeed {
    final kmh = (averageSpeed * 3.6);
    return '${kmh.toStringAsFixed(1)} km/h';
  }

  String get activityTypeText {
    switch (type) {
      case ActivityType.running:
        return 'Running';
      case ActivityType.cycling:
        return 'Cycling';
      case ActivityType.walking:
        return 'Walking';
    }
  }

  ActivitySession copyWith({
    String? id,
    ActivityType? type,
    ActivityStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? pausedAt,
    Duration? pausedDuration,
    Duration? duration,
    double? distance,
    double? averageSpeed,
    double? currentSpeed,
    List<LatLng>? route,
    LatLng? currentLocation,
    int? calories,
  }) {
    return ActivitySession(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      pausedAt: pausedAt ?? this.pausedAt,
      pausedDuration: pausedDuration ?? this.pausedDuration,
      duration: duration ?? this.duration,
      distance: distance ?? this.distance,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      route: route ?? this.route,
      currentLocation: currentLocation ?? this.currentLocation,
      calories: calories ?? this.calories,
    );
  }
}
