import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/activity_models.dart';
import '../../services/floating_activity_service.dart';
import '../../services/location_service.dart';
import '../../utils/activity_colors.dart';
import '../../widgets/conditional_map_widget.dart';

class WalkingTrackingScreen extends StatefulWidget {
  const WalkingTrackingScreen({super.key});

  @override
  State<WalkingTrackingScreen> createState() => _WalkingTrackingScreenState();
}

class _WalkingTrackingScreenState extends State<WalkingTrackingScreen> {
  final LocationService _locationService = LocationService();
  final FloatingActivityService _floatingService = FloatingActivityService();
  GoogleMapController? _mapController;
  ActivitySession? _currentSession;
  StreamSubscription<ActivitySession>? _sessionSubscription;
  
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  bool _isTracking = false;
  bool _isReady = false;
  bool _autoFollow = true; // Auto follow camera
  bool _isOverlayActive = false; // Track overlay status
  LatLng? _userLocation;
  
  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(-6.2088, 106.8456), // Jakarta coordinates as fallback
    zoom: 16.0,
  );

  @override
  void initState() {
    super.initState();
    // Hide floating widget when entering tracking screen
    _floatingService.hideOnPageEnter();
    
    // Listen to overlay status
    _floatingService.isOverlayActive.addListener(_onOverlayStatusChanged);
    
    _initializeTracking();
  }

  void _onOverlayStatusChanged() {
    if (mounted) {
      setState(() {
        _isOverlayActive = _floatingService.isOverlayActive.value;
      });
    }
  }

  @override
  void dispose() {
    _floatingService.isOverlayActive.removeListener(_onOverlayStatusChanged);
    _sessionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeTracking() async {
    // Check permissions first
    final hasPermission = await _locationService.checkAndRequestPermissions();
    if (!hasPermission) {
      if (mounted) {
        _showPermissionDialog();
      }
      return;
    }

    // Get current location
    try {
      final currentLocation = await _locationService.getCurrentPosition();
      if (currentLocation != null && mounted) {
        setState(() {
          _userLocation = currentLocation;
        });
        
        // Move camera to user location if map is already created
        if (_mapController != null) {
          await _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: currentLocation,
                zoom: 16.0,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error getting current location: $e');
    }

    // Check if there's already an active session
    final existingSession = _locationService.currentSession;
    if (existingSession != null && 
        existingSession.type == ActivityType.walking &&
        (existingSession.status == ActivityStatus.active || existingSession.status == ActivityStatus.paused)) {
      print('WalkingTracking: Found existing session - ${existingSession.id}');
      print('Session data: ${existingSession.formattedDistance}, ${existingSession.formattedDuration}, ${existingSession.calories} kcal');
      
      if (mounted) {
        setState(() {
          _currentSession = existingSession;
          _isTracking = existingSession.status == ActivityStatus.active;
          _updateMapData();
        });
      }
    }

    // Listen to session updates
    _sessionSubscription = _locationService.sessionStream.listen((session) {
      if (mounted) {
        setState(() {
          _currentSession = session;
          _isTracking = (session.status == ActivityStatus.active);
          _updateMapData();
        });
        
        // Navigate to summary if session is completed
        if (session.status == ActivityStatus.completed) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              context.go('/activity-summary', extra: {'activity': session});
            }
          });
        }
      }
    });

    // Set ready state - don't start automatically
    if (mounted) {
      setState(() {
        _isReady = true;
      });
    }
  }

  void _updateMapData() {
    if (_currentSession == null || _currentSession!.route.isEmpty) return;

    // Update polyline with vibrant colors for dark theme
    _polylines = {
      Polyline(
        polylineId: const PolylineId('walking_route'),
        points: _currentSession!.route,
        color: ActivityColors.walking, // Using consistent walking color
        width: 6, // Increased width for better visibility
        patterns: [],
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };

    // Update markers
    _markers = {};
    
    // Start marker
    if (_currentSession!.route.isNotEmpty) {
      _markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: _currentSession!.route.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Start'),
        ),
      );
    }

    // Current position marker
    if (_currentSession!.currentLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current'),
          position: _currentSession!.currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Current Position'),
        ),
      );

      // Auto follow: Move camera to current location with smooth animation
      if (_autoFollow) {
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _currentSession!.currentLocation!,
              zoom: 16.0, // Maintain consistent zoom level
              bearing: 0, // Keep north up for consistency
            ),
          ),
        );
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'This app needs location permission to track your walking activity. Please enable location services and grant permission.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _initializeTracking();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _startTracking() async {
    if (!_isReady) return;
    
    final success = await _locationService.startActivity(ActivityType.walking);
    if (!success) {
      if (mounted) {
        _showPermissionDialog();
      }
    }
  }

  void _pauseTracking() {
    if (_isTracking) {
      _locationService.pauseActivity();
    }
  }

  void _resumeTracking() {
    if (!_isTracking && _currentSession != null) {
      _locationService.resumeActivity();
    }
  }

  void _stopTracking() {
    if (_currentSession == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Stop Walking', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to stop this walking session?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFFFF9500))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _locationService.stopActivity();
            },
            child: const Text('Stop', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleTracking() {
    if (!_isReady || _isOverlayActive) return; // Disable when overlay is active
    
    if (_currentSession == null) {
      // No session yet, start new one
      _startTracking();
    } else if (_isTracking) {
      // Currently tracking, pause it
      _pauseTracking();
    } else {
      // Currently paused, resume it
      _resumeTracking();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            print('Back button tapped');
            if (mounted) {
              context.go('/home');
              // Show floating widget after navigation
              Future.delayed(const Duration(milliseconds: 300), () {
                // Show floating widget if activity is running or paused
                if (_currentSession != null && 
                    (_currentSession!.status == ActivityStatus.active || 
                     _currentSession!.status == ActivityStatus.paused)) {
                  _floatingService.showOnPageExit();
                }
              });
            }
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _currentSession?.activityTypeText ?? 'Walking',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          // Auto follow toggle button
          IconButton(
            onPressed: () {
              if (mounted) {
                setState(() {
                  _autoFollow = !_autoFollow;
                });
                
                // If auto follow is enabled and we have a current location, move camera
                if (_autoFollow && _currentSession?.currentLocation != null) {
                  _mapController?.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(
                        target: _currentSession!.currentLocation!,
                        zoom: 16.0,
                        bearing: 0,
                      ),
                    ),
                  );
                }
              }
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _autoFollow 
                    ? const Color(0xFFFF9500).withOpacity(0.3)
                    : Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: _autoFollow 
                    ? Border.all(color: const Color(0xFFFF9500), width: 1)
                    : null,
              ),
              child: Icon(
                Icons.my_location,
                color: _autoFollow ? const Color(0xFFFF9500) : Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          // Conditional Map Widget
          ConditionalMapWidget(
            initialCameraPosition: _userLocation != null 
                ? CameraPosition(target: _userLocation!, zoom: 16.0)
                : _defaultPosition,
            polylines: _polylines,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) async {
              _mapController = controller;
              // Move to user location if available
              if (_userLocation != null) {
                await controller.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: _userLocation!, zoom: 16.0),
                  ),
                );
              }
            },
          ),
          
          // Stats overlay
          Positioned(
            top: 130,
            left: 16,
            right: 16,
            child: _buildStatsOverlay(),
          ),
          
          // Control buttons
          Positioned(
            bottom: 50,
            left: 16,
            right: 16,
            child: _buildControlButtons(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.timer,
              label: 'Time',
              value: _currentSession?.formattedDuration ?? '00:00',
              color: const Color(0xFFFF9500),
            ),
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.straighten,
              label: 'Distance',
              value: _currentSession?.formattedDistance ?? '0 m',
              color: ActivityColors.distance,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.speed,
              label: 'Speed',
              value: _currentSession?.formattedSpeed ?? '0 km/h',
              color: ActivityColors.speed,
            ),
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildControlButtons() {
    // Show start button if no session or session not started yet
    if (_currentSession == null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Start Button
          GestureDetector(
            onTap: (_isReady && !_isOverlayActive) ? _toggleTracking : null,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: (_isReady && !_isOverlayActive)
                      ? [const Color(0xFFFF9500).withOpacity(0.8), const Color(0xFFFF9500)]
                      : [Colors.grey.withOpacity(0.8), Colors.grey],
                ),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF9500).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ],
      );
    }

    // Show pause/resume and stop buttons when session is active
    final isActive = _currentSession?.status == ActivityStatus.active;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Pause/Resume Button
        Opacity(
          opacity: _isOverlayActive ? 0.5 : 1.0,
          child: GestureDetector(
            onTap: !_isOverlayActive ? _toggleTracking : null,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isActive 
                      ? [Colors.orange.withOpacity(0.8), Colors.orange]
                      : [const Color(0xFFFF9500).withOpacity(0.8), const Color(0xFFFF9500)],
                ),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: (isActive ? Colors.orange : const Color(0xFFFF9500)).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isActive ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),
        
        // Stop Button
        Opacity(
          opacity: _isOverlayActive ? 0.5 : 1.0,
          child: GestureDetector(
            onTap: !_isOverlayActive ? _stopTracking : null,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.red.withOpacity(0.8), Colors.red],
                ),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.stop,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
