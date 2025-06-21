import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/activity_models.dart';
import '../utils/activity_colors.dart';

class CustomShareWidget extends StatelessWidget {
  final ActivitySession? activity;
  final Map<String, dynamic>? weeklyStats;
  final String title;
  final GlobalKey repaintBoundaryKey = GlobalKey();

  CustomShareWidget.activity({
    super.key,
    required this.activity,
    this.title = 'Activity Summary',
  }) : weeklyStats = null;

  CustomShareWidget.weeklyStats({
    super.key,
    required this.weeklyStats,
    this.title = 'Weekly Stats Summary',
  }) : activity = null;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
            Color(0xFF0F3460),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    activity != null ? _getActivityIcon(activity!.type) : Icons.analytics,
                    color: activity != null ? _getActivityColor(activity!.type) : ActivityColors.running,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _getSubtitle(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Stats
            if (activity != null) ..._buildActivityStats(),
            if (weeklyStats != null) ..._buildWeeklyStatsContent(),
            
            const SizedBox(height: 20),
            
            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_run,
                        color: ActivityColors.running,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'RunUp',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track your fitness journey',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSubtitle() {
    if (activity != null) {
      final date = activity!.endTime ?? DateTime.now();
      return _formatDate(date);
    } else if (weeklyStats != null) {
      return 'This Week Summary';
    }
    return '';
  }

  List<Widget> _buildActivityStats() {
    if (activity == null) return [];
    
    return [
      _buildStatRow([
        _buildStatItem(
          icon: Icons.timer,
          label: 'Duration',
          value: activity!.formattedDuration,
          color: const Color(0xFF5856D6),
        ),
        _buildStatItem(
          icon: Icons.straighten,
          label: 'Distance',
          value: activity!.formattedDistance,
          color: const Color(0xFF00D4FF),
        ),
      ]),
      const SizedBox(height: 12),
      _buildStatRow([
        _buildStatItem(
          icon: Icons.speed,
          label: 'Avg Speed',
          value: activity!.formattedAverageSpeed,
          color: const Color(0xFFFF9500),
        ),
        _buildStatItem(
          icon: Icons.local_fire_department,
          label: 'Calories',
          value: '${activity!.calories}',
          color: const Color(0xFFAF52DE),
        ),
      ]),
    ];
  }

  List<Widget> _buildWeeklyStatsContent() {
    if (weeklyStats == null) return [];
    
    final distance = weeklyStats!['totalDistance']?.toDouble() ?? 0.0;
    final duration = Duration(seconds: weeklyStats!['totalDuration'] ?? 0);
    final activities = weeklyStats!['totalActivities'] ?? 0;
    final avgDistance = weeklyStats!['averageDistance']?.toDouble() ?? 0.0;
    
    return [
      _buildStatRow([
        _buildStatItem(
          icon: Icons.fitness_center,
          label: 'Activities',
          value: '$activities',
          color: const Color(0xFF00D4FF),
        ),
        _buildStatItem(
          icon: Icons.straighten,
          label: 'Total Distance',
          value: _formatDistance(distance),
          color: const Color(0xFF5856D6),
        ),
      ]),
      const SizedBox(height: 12),
      _buildStatRow([
        _buildStatItem(
          icon: Icons.timer,
          label: 'Total Time',
          value: _formatDuration(duration),
          color: const Color(0xFFFF9500),
        ),
        _buildStatItem(
          icon: Icons.trending_up,
          label: 'Avg Distance',
          value: _formatDistance(avgDistance),
          color: const Color(0xFFAF52DE),
        ),
      ]),
    ];
  }

  Widget _buildStatRow(List<Widget> children) {
    return Row(
      children: children.map((child) => Expanded(child: child)).toList(),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.running:
        return Icons.directions_run;
      case ActivityType.cycling:
        return Icons.directions_bike;
      case ActivityType.walking:
        return Icons.directions_walk;
    }
  }

  Color _getActivityColor(ActivityType type) {
    return ActivityColors.getColorForActivity(type);
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

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
  
  Future<void> shareAsImage(BuildContext context) async {
    try {
      // Create invisible overlay to render widget off-screen
      OverlayEntry? overlayEntry;
      
      // Create overlay to render widget invisibly
      overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: -2000, // Position far off-screen
          top: -2000,  // Position far off-screen
          child: Material(
            color: Colors.transparent,
            child: RepaintBoundary(
              key: repaintBoundaryKey,
              child: this,
            ),
          ),
        ),
      );
      
      // Insert overlay
      Overlay.of(context).insert(overlayEntry);
      
      // Wait for widget to be fully rendered
      await Future.delayed(const Duration(milliseconds: 200));

      // Capture the widget as image
      RenderRepaintBoundary boundary = repaintBoundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      // Remove overlay immediately after capture
      overlayEntry.remove();
      
      if (byteData != null) {
        final buffer = byteData.buffer.asUint8List();
        
        // Save to temporary file
        final directory = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final imagePath = '${directory.path}/runup_share_$timestamp.png';
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(buffer);
        
        // Build share text
        final shareText = _buildShareText();
        
        // Share with image and text
        await Share.shareXFiles(
          [XFile(imagePath)],
          text: shareText,
          subject: title,
        );
        
        // Clean up temporary file after a short delay
        Future.delayed(const Duration(seconds: 5), () async {
          try {
            if (await imageFile.exists()) {
              await imageFile.delete();
            }
          } catch (e) {
            print('Error cleaning up temp file: $e');
          }
        });
      } else {
        throw Exception('Failed to capture image');
      }
    } catch (e) {
      print('Error sharing with image: $e');
      // Fallback to text only
      await Share.share(
        _buildShareText(),
        subject: title,
      );
    }
  }

  String _buildShareText() {
    final buffer = StringBuffer();
    
    if (activity != null) {
      buffer.writeln('🏃‍♂️ Just completed a ${activity!.activityTypeText.toLowerCase()} session!');
      buffer.writeln('');
      buffer.writeln('📊 Stats:');
      buffer.writeln('⏱️ Duration: ${activity!.formattedDuration}');
      buffer.writeln('📏 Distance: ${activity!.formattedDistance}');
      buffer.writeln('⚡ Avg Speed: ${activity!.formattedAverageSpeed}');
      buffer.writeln('🔥 Calories: ${activity!.calories} kcal');
      
      if (activity!.endTime != null) {
        final date = _formatDate(activity!.endTime!);
        buffer.writeln('📅 Date: $date');
      }
    } else if (weeklyStats != null) {
      buffer.writeln('📈 My Weekly Fitness Summary');
      buffer.writeln('');
      
      final distance = weeklyStats!['totalDistance']?.toDouble() ?? 0.0;
      final duration = Duration(seconds: weeklyStats!['totalDuration'] ?? 0);
      final activities = weeklyStats!['totalActivities'] ?? 0;
      
      buffer.writeln('🏃‍♂️ Activities: $activities');
      buffer.writeln('📏 Total Distance: ${_formatDistance(distance)}');
      buffer.writeln('⏱️ Total Time: ${_formatDuration(duration)}');
    }
    
    buffer.writeln('');
    buffer.writeln('Tracked with RunUp 💪');
    buffer.writeln('#fitness #running #health #workout');
    
    return buffer.toString();
  }
}
