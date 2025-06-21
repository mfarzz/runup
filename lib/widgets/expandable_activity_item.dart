import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/activity_models.dart';
import '../services/activity_storage_service.dart';
import '../services/share_service.dart';
import '../utils/activity_colors.dart';
import 'clean_widgets.dart';

class ExpandableActivityItem extends StatefulWidget {
  final ActivitySession activity;
  final VoidCallback? onDeleted;
  final VoidCallback? onTap;

  const ExpandableActivityItem({
    super.key,
    required this.activity,
    this.onDeleted,
    this.onTap,
  });

  @override
  State<ExpandableActivityItem> createState() => _ExpandableActivityItemState();
}

class _ExpandableActivityItemState extends State<ExpandableActivityItem>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  GoogleMapController? _mapController;

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
    _mapController?.dispose();
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
    final activityInfo = ActivityColors.getActivityInfo(widget.activity.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: _isExpanded
          ? _buildExpandedView(activityInfo)
          : _buildCollapsedView(activityInfo),
    );
  }

  Widget _buildCollapsedView(activityInfo) {
    return Slidable(
      key: ValueKey(widget.activity.id),
      enabled: !_isExpanded, // Disable slidable when expanded
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.2,
        children: [
          CustomSlidableAction(
            onPressed: (context) {},
            child: Container(
              width: 60,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _shareActivity(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.share,
                        color: Color(0xFF00D4FF),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => _showDeleteConfirmation(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.delete,
                        color: Color(0xFFFF3B30),
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),      child: GestureDetector(
        onTap: _toggleExpanded,
        child: CleanCard(
          padding: const EdgeInsets.all(20),
          addBorder: true,
          addBackground: true,
          child: _buildActivityContent(activityInfo),
        ),
      ),
    );
  }

  Widget _buildExpandedView(activityInfo) {    return GestureDetector(
      onTap: _toggleExpanded,
      child: CleanCard(
        padding: const EdgeInsets.all(20),
        addBorder: true,
        addBackground: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildActivityContent(activityInfo),
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildMapSection(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityContent(activityInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.activity.activityTypeText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: Colors.white.withOpacity(0.7),
                        size: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.activity.endTime != null 
                        ? _formatDate(widget.activity.endTime!)
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
                value: widget.activity.formattedDistance,
                color: const Color(0xFF00D4FF),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActivityStat(
                icon: Icons.timer,
                label: 'Duration',
                value: widget.activity.formattedDuration,
                color: const Color(0xFF5856D6),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActivityStat(
                icon: Icons.local_fire_department,
                label: 'Calories',
                value: '${widget.activity.calories}',
                color: const Color(0xFFAF52DE),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    if (widget.activity.route.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map_outlined,
                color: Colors.white.withOpacity(0.6),
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                'No route data available',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
          initialCameraPosition: CameraPosition(
            target: widget.activity.route.isNotEmpty 
                ? widget.activity.route.first 
                : const LatLng(0, 0),
            zoom: 15,
          ),
          polylines: {
            Polyline(
              polylineId: const PolylineId('route'),
              points: widget.activity.route,
              color: const Color(0xFF00D4FF),
              width: 4,
            ),
          },
          markers: {
            if (widget.activity.route.isNotEmpty)
              Marker(
                markerId: const MarkerId('start'),
                position: widget.activity.route.first,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                infoWindow: const InfoWindow(title: 'Start'),
              ),
            if (widget.activity.route.isNotEmpty)
              Marker(
                markerId: const MarkerId('end'),
                position: widget.activity.route.last,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                infoWindow: const InfoWindow(title: 'End'),
              ),
          },
          mapType: MapType.normal,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _shareActivity(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF00D4FF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00D4FF).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.share,
                    color: Color(0xFF00D4FF),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Share',
                    style: TextStyle(
                      color: Color(0xFF00D4FF),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => _showDeleteConfirmation(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF3B30).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete,
                    color: Color(0xFFFF3B30),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Delete',
                    style: TextStyle(
                      color: Color(0xFFFF3B30),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
      await shareService.shareActivityWithCustomDesign(context, widget.activity);
    } catch (e) {
      print('Error sharing activity: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to share activity'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
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
            'Are you sure you want to delete this ${widget.activity.activityTypeText.toLowerCase()} activity? This action cannot be undone.',
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
      await storageService.deleteActivity(widget.activity.id);

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

      widget.onDeleted?.call();
    } catch (e) {
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
