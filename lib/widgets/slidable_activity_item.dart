import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../models/activity_models.dart';
import '../services/activity_storage_service.dart';
import '../services/share_service.dart';
import '../utils/activity_colors.dart';
import 'clean_widgets.dart';

class SlidableActivityItem extends StatelessWidget {
  final ActivitySession activity;
  final VoidCallback? onDeleted;
  final VoidCallback? onTap;

  const SlidableActivityItem({
    super.key,
    required this.activity,
    this.onDeleted,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final activityInfo = ActivityColors.getActivityInfo(activity.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Slidable(
        key: ValueKey(activity.id),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.2, // Action area width
          children: [
            // Custom container with both actions
            CustomSlidableAction(
              onPressed: (context) {}, // This won't be used
              child: Container(
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Share button
                    GestureDetector(
                      onTap: () => _shareActivity(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.share,
                          color: const Color(0xFF00D4FF),
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Delete button
                    GestureDetector(
                      onTap: () => _showDeleteConfirmation(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.delete,
                          color: const Color(0xFFFF3B30),
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),        child: GestureDetector(
          onTap: onTap,
          child: CleanCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: activityInfo.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: activityInfo.color.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        activityInfo.icon,
                        color: activityInfo.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.activityTypeText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activity.endTime != null 
                                ? _formatDate(activity.endTime!)
                                : 'Just now',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildActivityStat(
                        icon: Icons.straighten,
                        label: 'Distance',
                        value: activity.formattedDistance,
                        color: const Color(0xFF00D4FF),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActivityStat(
                        icon: Icons.timer,
                        label: 'Duration',
                        value: activity.formattedDuration,
                        color: const Color(0xFF5856D6),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActivityStat(
                        icon: Icons.local_fire_department,
                        label: 'Calories',
                        value: '${activity.calories}',
                        color: const Color(0xFFAF52DE),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _shareActivity(BuildContext context) async {
    try {
      final shareService = ShareService();
      await shareService.shareActivityText(activity);

      // Show success feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Activity shared successfully!'),
            backgroundColor: const Color(0xFF00D4FF),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share activity: $e'),
            backgroundColor: const Color(0xFFFF3B30),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          title: const Text(
            'Delete Activity',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this ${activity.activityTypeText.toLowerCase()} activity? This action cannot be undone.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result == true && context.mounted) {
      await _deleteActivity(context);
    }
  }

  Future<void> _deleteActivity(BuildContext context) async {
    try {
      final storageService = ActivityStorageService();
      await storageService.deleteActivity(activity.id);

      // Show success feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Activity deleted successfully!'),
            backgroundColor: const Color(0xFF00D4FF),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Notify parent about deletion to refresh the list
      onDeleted?.call();
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete activity: $e'),
            backgroundColor: const Color(0xFFFF3B30),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return '${weekdays[date.weekday - 1]} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Custom slidable action widget for better control
class CustomSlidableAction extends StatelessWidget {
  final Widget child;
  final void Function(BuildContext) onPressed;

  const CustomSlidableAction({
    super.key,
    required this.child,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onPressed(context),
      child: child,
    );
  }
}
