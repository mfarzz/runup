import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/activity_models.dart';
import '../../services/activity_storage_service.dart';
import '../../services/share_service.dart';
import '../../utils/map_styles.dart';
import '../../widgets/clean_widgets.dart';

class ActivitySummaryScreen extends StatefulWidget {
  final ActivitySession activity;

  const ActivitySummaryScreen({
    super.key,
    required this.activity,
  });

  @override
  State<ActivitySummaryScreen> createState() => _ActivitySummaryScreenState();
}

class _ActivitySummaryScreenState extends State<ActivitySummaryScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  final ShareService _shareService = ShareService();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupMapData();
    _autoSaveActivity(); // Auto save when screen opens
  }
  Future<void> _autoSaveActivity() async {
    try {
      print('=== ACTIVITY AUTO-SAVE ===');
      print('Activity type: ${widget.activity.activityTypeText}');
      print('Activity status: ${widget.activity.status}');
      print('Activity details: ${widget.activity.formattedDistance}, ${widget.activity.formattedDuration}, ${widget.activity.calories} kcal');
      print('Has endTime: ${widget.activity.endTime != null}');
      print('EndTime: ${widget.activity.endTime}');
      print('Route points: ${widget.activity.route.length}');
      
      await ActivityStorageService().saveActivity(widget.activity);
      
      // Verify the save
      final activities = await ActivityStorageService().getActivities();
      final completedActivities = activities.where((a) => 
          a.endTime != null || a.status == ActivityStatus.completed).toList();
      
      print('Activity auto-saved successfully.');
      print('Total activities in storage: ${activities.length}');
      print('Total completed activities: ${completedActivities.length}');
      print('=== END AUTO-SAVE ===');
    } catch (e) {
      print('Error auto-saving activity: $e');  
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  void _setupMapData() {
    if (widget.activity.route.isNotEmpty) {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('activity_route'),
          points: widget.activity.route,
          color: const Color(0xFF00D4FF),
          width: 6,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      };
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F0F23), // Dark blue-purple
              Color(0xFF1A1A2E), // Medium dark blue
              Color(0xFF16213E), // Dark navy
              Color(0xFF0F0F23), // Back to dark blue-purple
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main content with padding for floating buttons
              SingleChildScrollView(
                child: RepaintBoundary(
                  key: _repaintBoundaryKey,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 100), // Space for floating buttons
                    child: Column(
                      children: [
                        // Header
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildHeader(),
                        ),

                        // Content
                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: _buildContent(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Floating action buttons
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,                    ).animate(CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
                    )),
                    child: _buildFloatingActions(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Activity completed message
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${widget.activity.activityTypeText} Completed!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Great job! Here\'s your activity summary',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          // Stats Cards
          _buildStatsGrid(),
          const SizedBox(height: 20),
          
          // Map Card
          _buildMapCard(),
        ],
      ),
    );
  }
  Widget _buildStatsGrid() {
    return CleanCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity Stats',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.timer,
                  label: 'Duration',
                  value: widget.activity.formattedDuration,
                  color: const Color(0xFF00D4FF),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.straighten,
                  label: 'Distance',
                  value: widget.activity.formattedDistance,
                  color: const Color(0xFF5856D6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.speed,
                  label: 'Avg Speed',
                  value: widget.activity.formattedAverageSpeed,
                  color: const Color(0xFFAF52DE),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.local_fire_department,
                  label: 'Calories',
                  value: '${widget.activity.calories} kcal',
                  color: const Color(0xFFFF6B35),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  Widget _buildMapCard() {
    return CleanCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Route',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 250, // Fixed height for the map
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: widget.activity.route.isNotEmpty
                  ? GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: widget.activity.route.first,
                        zoom: 14.0,
                      ),
                      style: fitnessMapStyle,
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                        if (widget.activity.route.length > 1) {
                          _fitRouteInView();
                        }
                      },
                      polylines: _polylines,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      scrollGesturesEnabled: false,
                      zoomGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                      markers: {
                        if (widget.activity.route.isNotEmpty)
                          Marker(
                            markerId: const MarkerId('start'),
                            position: widget.activity.route.first,
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueGreen,
                            ),
                            infoWindow: const InfoWindow(title: 'Start'),
                          ),
                        if (widget.activity.route.length > 1)
                          Marker(
                            markerId: const MarkerId('end'),
                            position: widget.activity.route.last,
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueRed,
                            ),
                            infoWindow: const InfoWindow(title: 'Finish'),
                          ),
                      },
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.map_outlined,
                              size: 48,
                              color: Colors.white.withOpacity(0.6),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No route data available',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActions() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(                child: GestureDetector(
                  onTap: () async {
                    print('Share button tapped');
                    try {
                      // Direct share without loading dialog
                      await _shareService.shareActivityWithCustomDesign(
                        context,
                        widget.activity,
                      );
                    } catch (e) {
                      print('Error sharing: $e');
                      // Show error message if needed
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to share activity'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.25),
                          Colors.white.withOpacity(0.15),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.share,
                          color: Colors.white,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Share',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withOpacity(0.2),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    print('Done button tapped - navigating to home');
                    if (mounted) {
                      context.go('/home');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF00D4FF),
                          Color(0xFF0099CC),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Done',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _fitRouteInView() {
    if (_mapController == null || widget.activity.route.length < 2) return;

    double minLat = widget.activity.route.first.latitude;
    double maxLat = widget.activity.route.first.latitude;
    double minLng = widget.activity.route.first.longitude;
    double maxLng = widget.activity.route.first.longitude;

    for (final point in widget.activity.route) {
      minLat = minLat > point.latitude ? point.latitude : minLat;
      maxLat = maxLat < point.latitude ? point.latitude : maxLat;
      minLng = minLng > point.longitude ? point.longitude : minLng;
      maxLng = maxLng < point.longitude ? point.longitude : maxLng;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding
      ),
    );
  }
}
