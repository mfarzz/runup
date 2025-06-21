import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/activity_models.dart';
import '../widgets/custom_share_widget.dart';

class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();  // Share activity as text (fallback method)
  Future<void> shareActivityText(ActivitySession activity) async {
    final shareText = _buildShareText(activity);
    
    await Share.share(
      shareText,
      subject: 'Check out my ${activity.activityTypeText.toLowerCase()} activity!',
    );
  }
  // Share activity with custom themed design
  Future<void> shareActivityWithCustomDesign(
    BuildContext context,
    ActivitySession activity,
  ) async {
    try {
      final shareWidget = CustomShareWidget.activity(activity: activity);
      await shareWidget.shareAsImage(context);
    } catch (e) {
      print('Error sharing with custom design: $e');
      // Fallback to text only
      await shareActivityText(activity);
    }
  }

  // Share weekly stats with custom themed design
  Future<void> shareWeeklyStatsWithCustomDesign(
    BuildContext context,
    Map<String, dynamic> weeklyStats,
  ) async {
    final shareWidget = CustomShareWidget.weeklyStats(weeklyStats: weeklyStats);
    await shareWidget.shareAsImage(context);
  }

  // Share activity with image (if we can capture screenshot)
  Future<void> shareActivityWithImage(
    ActivitySession activity, 
    GlobalKey repaintBoundaryKey
  ) async {
    try {
      // Capture the widget as image
      RenderRepaintBoundary boundary = repaintBoundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final buffer = byteData.buffer.asUint8List();
        
        // Save to temporary file
        final directory = await getTemporaryDirectory();
        final imagePath = '${directory.path}/activity_share.png';
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(buffer);
        
        // Share with image and text
        final shareText = _buildShareText(activity);
        
        await Share.shareXFiles(
          [XFile(imagePath)],
          text: shareText,
          subject: 'Check out my ${activity.activityTypeText.toLowerCase()} activity!',
        );
        
        // Clean up temporary file
        await imageFile.delete();
      }
    } catch (e) {
      print('Error sharing with image: $e');
      // Fallback to text only
      await shareActivityText(activity);
    }
  }

  // Build shareable text content
  String _buildShareText(ActivitySession activity) {
    final buffer = StringBuffer();
    
    buffer.writeln('🏃‍♂️ Just completed a ${activity.activityTypeText.toLowerCase()} session!');
    buffer.writeln('');
    buffer.writeln('📊 Stats:');
    buffer.writeln('⏱️ Duration: ${activity.formattedDuration}');
    buffer.writeln('📏 Distance: ${activity.formattedDistance}');
    buffer.writeln('⚡ Avg Speed: ${activity.formattedAverageSpeed}');
    buffer.writeln('🔥 Calories: ${activity.calories} kcal');
    
    if (activity.endTime != null) {
      final date = _formatShareDate(activity.endTime!);
      buffer.writeln('📅 Date: $date');
    }
    
    buffer.writeln('');
    buffer.writeln('Tracked with RunUp 💪');
    buffer.writeln('#fitness #running #health #workout');
    
    return buffer.toString();
  }

  // Format date for sharing
  String _formatShareDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Share weekly stats
  Future<void> shareWeeklyStats(Map<String, dynamic> weeklyStats) async {
    final buffer = StringBuffer();
    
    buffer.writeln('📈 My Weekly Fitness Summary');
    buffer.writeln('');
    
    final distance = weeklyStats['distance']?.toDouble() ?? 0.0;
    final duration = weeklyStats['duration'] as Duration? ?? Duration.zero;
    final calories = weeklyStats['calories'] ?? 0;
    final activitiesCount = weeklyStats['activitiesCount'] ?? 0;
    
    buffer.writeln('🏃‍♂️ Activities: $activitiesCount');
    buffer.writeln('📏 Total Distance: ${_formatDistance(distance)}');
    buffer.writeln('⏱️ Total Time: ${_formatDuration(duration)}');
    buffer.writeln('🔥 Calories Burned: $calories kcal');
    
    buffer.writeln('');
    buffer.writeln('Keep moving! 💪');
    buffer.writeln('Tracked with RunUp');
    buffer.writeln('#fitness #weeklygoals #health #consistency');
    
    await Share.share(
      buffer.toString(),
      subject: 'My Weekly Fitness Summary',
    );
  }

  // Helper methods for formatting
  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(2)} km';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '0m';
    }
  }
}
