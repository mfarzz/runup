import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/activity_models.dart';
import '../services/location_service.dart';
import '../utils/activity_colors.dart';

class FloatingActivityWidget extends StatefulWidget {
  final ActivitySession session;
  final VoidCallback? onDismiss;
  final Function(ActivitySession)? onStopComplete;

  const FloatingActivityWidget({
    super.key,
    required this.session,
    this.onDismiss,
    this.onStopComplete,
  });

  @override
  State<FloatingActivityWidget> createState() => _FloatingActivityWidgetState();
}

class _FloatingActivityWidgetState extends State<FloatingActivityWidget>
    with TickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
      _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1), // Mulai dari atas layar
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _navigateToTracking() {
    // Get the latest session data from LocationService
    final currentSession = _locationService.currentSession;
    if (currentSession == null) {
      print('FloatingActivity: No current session found');
      return;
    }

    String route;
    switch (currentSession.type) {
      case ActivityType.running:
        route = '/running-tracking';
        break;
      case ActivityType.cycling:
        route = '/cycling-tracking';
        break;
      case ActivityType.walking:
        route = '/walking-tracking';
        break;
    }
    
    print('FloatingActivity: Navigating to tracking screen with session: ${currentSession.id}');
    print('Session data: ${currentSession.formattedDistance}, ${currentSession.formattedDuration}, ${currentSession.calories} kcal');
    
    context.go(route);
  }

  void _pauseActivity() {
    // Always use current session from LocationService
    final currentSession = _locationService.currentSession;
    if (currentSession == null) {
      print('FloatingActivity: No current session found for pause/resume');
      return;
    }

    if (currentSession.status == ActivityStatus.active) {
      print('FloatingActivity: Pausing activity');
      _locationService.pauseActivity();
    } else if (currentSession.status == ActivityStatus.paused) {
      print('FloatingActivity: Resuming activity');
      _locationService.resumeActivity();
    }
  }

  void _stopActivity() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          content: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0x40000000),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.0,
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Stop ${widget.session.activityTypeText}?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Are you sure you want to stop this activity?',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              Navigator.pop(context);
                              
                              try {
                                // Stop the activity
                                _locationService.stopActivity();
                                
                                // Wait a moment to ensure session is completed
                                await Future.delayed(const Duration(milliseconds: 800));
                                
                                // Get the completed session from location service
                                final completedSession = _locationService.currentSession;
                                
                                if (completedSession != null) {
                                  print('FloatingActivity: Session completed - ${completedSession.activityTypeText}');
                                  print('Session details: ${completedSession.formattedDistance}, ${completedSession.formattedDuration}, ${completedSession.calories} kcal');
                                  
                                  // Ensure the session has end time set
                                  final finalSession = completedSession.endTime == null 
                                      ? completedSession.copyWith(endTime: DateTime.now())
                                      : completedSession;
                                  
                                  // Call onStopComplete callback to navigate to summary
                                  if (widget.onStopComplete != null) {
                                    widget.onStopComplete!(finalSession);
                                  }
                                } else {
                                  print('FloatingActivity: Warning - No completed session found');
                                  // Still try to use the widget session as fallback
                                  final fallbackSession = widget.session.copyWith(
                                    status: ActivityStatus.completed,
                                    endTime: DateTime.now(),
                                  );
                                  
                                  if (widget.onStopComplete != null) {
                                    widget.onStopComplete!(fallbackSession);
                                  }
                                }
                              } catch (e) {
                                print('FloatingActivity: Error stopping activity - $e');
                              } finally {
                                // Always dismiss the overlay
                                widget.onDismiss?.call();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'Stop',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16, // Margin dari status bar + 16
          left: 16,
          right: 16,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0x30FFFFFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: _navigateToTracking,
                child: StreamBuilder<ActivitySession>(
                  stream: _locationService.sessionStream,
                  initialData: widget.session,
                  builder: (context, snapshot) {
                    final currentSession = snapshot.data ?? widget.session;
                    final activityColor = _getActivityColor(currentSession.type);
                    final isActive = currentSession.status == ActivityStatus.active;
                    
                    return Row(
                      children: [
                        // Activity Icon
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: activityColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: activityColor.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            _getActivityIcon(currentSession.type),
                            color: activityColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Activity Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    currentSession.activityTypeText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black26,
                                          offset: Offset(0, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (isActive ? Colors.green : Colors.orange).withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Text(
                                      isActive ? 'Active' : 'Paused',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${currentSession.formattedDuration} • ${currentSession.formattedDistance}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Control Buttons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Pause/Resume Button
                            GestureDetector(
                              onTap: _pauseActivity,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (isActive 
                                      ? Colors.orange 
                                      : Colors.green).withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: (isActive ? Colors.orange : Colors.green).withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  isActive ? Icons.pause : Icons.play_arrow,
                                  color: isActive ? Colors.orange : Colors.green,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            
                            // Stop Button
                            GestureDetector(
                              onTap: _stopActivity,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.red.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.stop,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getActivityColor(ActivityType type) {
    return ActivityColors.getColorForActivity(type);
  }

  IconData _getActivityIcon(ActivityType type) {
    return ActivityColors.getIconForActivity(type);
  }
}
