import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../models/activity_models.dart';
import '../services/share_service.dart';
import '../utils/activity_colors.dart';
import 'clean_widgets.dart';

class ExpandableWeeklyStatsItem extends StatefulWidget {
  final Map<String, dynamic> weekData;
  final int index;

  const ExpandableWeeklyStatsItem({
    super.key,
    required this.weekData,
    required this.index,
  });

  @override
  State<ExpandableWeeklyStatsItem> createState() => _ExpandableWeeklyStatsItemState();
}

class _ExpandableWeeklyStatsItemState extends State<ExpandableWeeklyStatsItem>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  final ShareService _shareService = ShareService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: _isExpanded
          ? _buildExpandedView()
          : _buildCollapsedView(),
    );
  }

  Widget _buildCollapsedView() {
    return Slidable(
      key: ValueKey('weekly_stats_${widget.index}'),
      enabled: !_isExpanded, // Disable slidable when expanded
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.25, // Increase width to prevent overflow
        children: [
          SlidableAction(
            onPressed: (context) => _shareWeekStats(widget.weekData),
            backgroundColor: Colors.transparent,
            foregroundColor: ActivityColors.running,
            icon: Icons.share,
            label: 'Share',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: _toggleExpanded,
        child: CleanCard(
          addBackground: true,
          addBorder: true,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildMainContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedView() {
    return GestureDetector(
      onTap: _toggleExpanded,
      child: CleanCard(
        addBackground: true,
        addBorder: true,
        child: Column(
          children: [
            // Main card content
            Padding(
              padding: const EdgeInsets.all(20),
              child: _buildMainContent(),
            ),
            
            // Expandable content
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Column(
                children: [
                  const Divider(
                    color: Colors.white24,
                    thickness: 1,
                    height: 1,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildExpandedContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    final weekStart = widget.weekData['weekStart'] as DateTime;
    final weekEnd = widget.weekData['weekEnd'] as DateTime;
    final stats = widget.weekData['stats'] as Map<String, dynamic>;
    final activities = widget.weekData['activities'] as List<ActivitySession>;
    final isCurrentWeek = widget.weekData['isCurrentWeek'] as bool;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Week header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Week title and current badge in a row with proper spacing
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _formatWeekRange(weekStart, weekEnd),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentWeek) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: ActivityColors.running.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: ActivityColors.running.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Current',
                            style: TextStyle(
                              fontSize: 11,
                              color: ActivityColors.running,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${stats['totalActivities']} activities',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16), // Add space between content and actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white.withOpacity(0.7),
                  size: 24,
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Stats row
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: Icons.straighten,
                value: _formatDistance(stats['totalDistance'].toDouble()),
                label: 'Distance',
                color: ActivityColors.distance,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatItem(
                icon: Icons.timer,
                value: _formatDuration(stats['totalDuration']),
                label: 'Duration',
                color: ActivityColors.duration,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatItem(
                icon: Icons.fitness_center,
                value: '${activities.length}',
                label: 'Activities',
                color: ActivityColors.timeline,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpandedContent() {
    final stats = widget.weekData['stats'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Breakdown',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 12),
        ..._buildActivityBreakdown(
          stats['activityCounts'],
          stats['activityDistances'],
        ),
        const SizedBox(height: 16),
        // Share button
        GestureDetector(
          onTap: () => _shareWeekStats(widget.weekData),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: ActivityColors.running.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ActivityColors.running.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.share,
                  color: ActivityColors.running,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Share Weekly Stats',
                  style: TextStyle(
                    color: ActivityColors.running,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  List<Widget> _buildActivityBreakdown(Map<ActivityType, int> counts, Map<ActivityType, double> distances) {
    return counts.entries.map((entry) {
      final activityType = entry.key;
      final count = entry.value;
      final distance = distances[activityType] ?? 0;
      final color = getActivityColor(activityType);
      
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              getActivityIcon(activityType),
              color: color,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activityType.name.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$count activities • ${_formatDistance(distance)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  IconData getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.running:
        return Icons.directions_run;
      case ActivityType.cycling:
        return Icons.directions_bike;
      case ActivityType.walking:
        return Icons.directions_walk;
    }
  }

  Color getActivityColor(ActivityType type) {
    return ActivityColors.getColorForActivity(type);
  }

  String _formatWeekRange(DateTime start, DateTime end) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    if (start.month == end.month) {
      return '${start.day}-${end.day} ${months[start.month - 1]} ${start.year}';
    } else {
      return '${start.day} ${months[start.month - 1]} - ${end.day} ${months[end.month - 1]} ${start.year}';
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _formatDistance(double distance) {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    } else {
      return '${distance.toInt()} m';
    }
  }

  void _shareWeekStats(Map<String, dynamic> weekData) async {
    try {
      await _shareService.shareWeeklyStats(weekData['stats']);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share stats: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
