import 'package:flutter/material.dart';

import '../models/activity_models.dart';

/// Utility class for activity colors to ensure consistency across the app
class ActivityColors {
  static const Color running = Color(0xFF00D4FF); // Bright cyan for running
  static const Color cycling = Color(0xFF5856D6); // Purple for cycling  
  static const Color walking = Color(0xFFAF52DE); // Magenta for walking

  // Additional colors for different UI elements
  static const Color distance = Color(0xFF5856D6); // Purple for distance
  static const Color duration = Color(0xFF00D4FF); // Cyan for duration
  static const Color calories = Color(0xFFFF5722); // Red Orange for calories
  static const Color speed = Color(0xFFAF52DE); // Magenta for speed
  static const Color timeline = Color(0xFF9C27B0); // Purple for timeline/stats
  static const Color heart = Color(0xFFE91E63); // Pink for heart rate

  /// Get color for specific activity type
  static Color getColorForActivity(ActivityType type) {
    switch (type) {
      case ActivityType.running:
        return running;
      case ActivityType.cycling:
        return cycling;
      case ActivityType.walking:
        return walking;
    }
  }

  /// Get color for activity type from string
  static Color getColorForActivityString(String activityType) {
    switch (activityType.toLowerCase()) {
      case 'running':
        return running;
      case 'cycling':
        return cycling;
      case 'walking':
        return walking;
      default:
        return running; // Default to running color
    }
  }

  /// Get color with opacity for specific activity type
  static Color getColorForActivityWithOpacity(ActivityType type, double opacity) {
    return getColorForActivity(type).withOpacity(opacity);
  }

  /// Get gradient colors for activity type
  static List<Color> getGradientColorsForActivity(ActivityType type) {
    final baseColor = getColorForActivity(type);
    return [
      baseColor.withOpacity(0.8),
      baseColor,
    ];
  }

  /// Get icon for specific activity type
  static IconData getIconForActivity(ActivityType type) {
    switch (type) {
      case ActivityType.running:
        return Icons.directions_run;
      case ActivityType.cycling:
        return Icons.directions_bike;
      case ActivityType.walking:
        return Icons.directions_walk;
    }
  }

  /// Get icon for activity type from string
  static IconData getIconForActivityString(String activityType) {
    switch (activityType.toLowerCase()) {
      case 'running':
        return Icons.directions_run;
      case 'cycling':
        return Icons.directions_bike;
      case 'walking':
        return Icons.directions_walk;
      default:
        return Icons.directions_run; // Default to running icon
    }
  }

  /// Get activity info (color and icon) for specific activity type
  static ActivityColorInfo getActivityInfo(ActivityType type) {
    return ActivityColorInfo(
      color: getColorForActivity(type),
      icon: getIconForActivity(type),
      type: type,
    );
  }

  /// Get stat colors for consistent UI elements
  static Color getStatColor(String statType) {
    switch (statType.toLowerCase()) {
      case 'distance':
        return distance;
      case 'duration':
      case 'time':
        return duration;
      case 'calories':
        return calories;
      case 'speed':
        return speed;
      case 'timeline':
      case 'stats':
        return timeline;
      case 'heart':
      case 'heartrate':
        return heart;
      default:
        return duration;
    }
  }
}

/// Data class for activity color and icon information
class ActivityColorInfo {
  final Color color;
  final IconData icon;
  final ActivityType type;

  const ActivityColorInfo({
    required this.color,
    required this.icon,
    required this.type,
  });
}
