import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../main.dart';
import '../models/activity_models.dart';
import '../services/location_service.dart';
import '../widgets/floating_activity_widget.dart';

class FloatingActivityService {
  static final FloatingActivityService _instance = FloatingActivityService._internal();
  factory FloatingActivityService() => _instance;
  FloatingActivityService._internal();

  final LocationService _locationService = LocationService();
  OverlayEntry? _overlayEntry;
  StreamSubscription<ActivitySession>? _sessionSubscription;
  BuildContext? _validContext; // Store a valid context from initialization
  
  // Use ValueNotifier to update only the widget content, not the overlay
  final ValueNotifier<ActivitySession?> _sessionNotifier = ValueNotifier(null);
  final ValueNotifier<bool> _isOverlayActive = ValueNotifier(false);
  bool _isOnTrackingScreen = false;

  // Getter for overlay status
  ValueNotifier<bool> get isOverlayActive => _isOverlayActive;

  void setOnTrackingScreen(bool isOnTracking) {
    _isOnTrackingScreen = isOnTracking;
    
    if (_isOnTrackingScreen) {
      _hideFloatingWidget();
    } else if (_sessionNotifier.value != null && 
        (_sessionNotifier.value!.status == ActivityStatus.active || 
         _sessionNotifier.value!.status == ActivityStatus.paused)) {
      // We need context to show the widget, so we'll store this state
      // and show it when showOnPageExit is called
    }
  }

  void initialize(BuildContext context) {
    // Store the valid context for later use
    _validContext = context;
    
    // Listen to session updates
    _sessionSubscription = _locationService.sessionStream.listen((session) {
      _sessionNotifier.value = session;
      
      print('FloatingActivityService: Session update - Status: ${session.status}, OnTracking: $_isOnTrackingScreen');
      print('Session data: ${session.formattedDistance}, ${session.formattedDuration}, ${session.calories} kcal');
      
      // Only show if we're not on tracking screen and session is active/paused
      if (!_isOnTrackingScreen && 
          (session.status == ActivityStatus.active || session.status == ActivityStatus.paused)) {
        _showFloatingWidget(context);
      } else if (session.status == ActivityStatus.completed || session.status == ActivityStatus.notStarted) {
        // Hide widget when activity is completed or not started
        _hideFloatingWidget();
      }
    });
  }

  void _showFloatingWidget(BuildContext context) {
    print('FloatingActivityService: _showFloatingWidget called for ${_sessionNotifier.value?.id}');
    
    // If overlay already exists, don't recreate it
    if (_overlayEntry != null) {
      print('FloatingActivityService: Overlay already exists, skipping creation');
      return;
    }

    // Use the stored valid context if the provided context is not mounted
    if (!context.mounted && _validContext != null && _validContext!.mounted) {
      print('FloatingActivityService: Using stored valid context');
      context = _validContext!;
    }

    // Ensure we have a valid context
    if (!context.mounted) {
      print('FloatingActivityService: Context is not mounted, trying global context');
      final globalContext = navigatorKey.currentContext;
      if (globalContext == null || !globalContext.mounted) {
        print('FloatingActivityService: No valid context available');
        return;
      }
      context = globalContext;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: ValueListenableBuilder<ActivitySession?>(
            valueListenable: _sessionNotifier,
            builder: (context, session, child) {
              if (session == null) return const SizedBox.shrink();
              return FloatingActivityWidget(
                session: session,
                onDismiss: _hideFloatingWidget,
                onStopComplete: _navigateToSummary,
              );
            },
          ),
        ),
      ),
    );

    try {
      // Always use root overlay to avoid issues with nested navigators
      final overlayState = Overlay.of(context, rootOverlay: true);
      overlayState.insert(_overlayEntry!);
      _isOverlayActive.value = true;
      print('FloatingActivityService: Overlay inserted successfully');
    } catch (e) {
      print('FloatingActivityService: Error inserting overlay: $e');
      print('FloatingActivityService: Context widget tree:');
      context.visitAncestorElements((element) {
        print('  - ${element.widget.runtimeType}');
        return true;
      });
      _overlayEntry = null;
    }
  }

  void _hideFloatingWidget() {
    print('FloatingActivityService: _hideFloatingWidget called, overlay exists: ${_overlayEntry != null}');
    if (_overlayEntry != null) {
      try {
        _overlayEntry!.remove();
        _isOverlayActive.value = false;
        print('FloatingActivityService: Overlay removed successfully');
      } catch (e) {
        print('FloatingActivityService: Error removing overlay: $e');
      }
      _overlayEntry = null;
    }
  }

  void _navigateToSummary(ActivitySession session) {
    print('=== FLOATING NAVIGATION TO SUMMARY ===');
    print('Session ID: ${session.id}');
    print('Activity type: ${session.activityTypeText}');
    print('Status: ${session.status}');
    print('Has endTime: ${session.endTime != null}');
    print('EndTime: ${session.endTime}');
    print('Distance: ${session.formattedDistance}');
    print('Duration: ${session.formattedDuration}');
    print('Calories: ${session.calories}');
    print('Route points: ${session.route.length}');
    
    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      context.go('/activity-summary', extra: {'activity': session});
      print('Navigation successful');
    } else {
      print('Navigation failed - no valid context');
    }
    print('=== END NAVIGATION ===');
  }

  void showOnPageExit([BuildContext? context]) {
    print('FloatingActivityService: showOnPageExit called');
    _isOnTrackingScreen = false;
    if (_sessionNotifier.value != null && 
        (_sessionNotifier.value!.status == ActivityStatus.active || 
         _sessionNotifier.value!.status == ActivityStatus.paused)) {
      print('FloatingActivityService: Showing widget for session: ${_sessionNotifier.value!.id}');
      
      // Use a delayed approach to ensure the navigation is complete
      // Try multiple times with increasing delays to ensure overlay is available
      _attemptToShowFloatingWidget(context, 0);
    } else {
      print('FloatingActivityService: No active session to show');
    }
  }

  void _attemptToShowFloatingWidget(BuildContext? context, int attempt) {
    final delays = [500, 1000, 2000, 3000]; // Longer delays to allow proper initialization
    
    if (attempt >= delays.length) {
      print('FloatingActivityService: Failed to show floating widget after ${delays.length} attempts');
      return;
    }
    
    Future.delayed(Duration(milliseconds: delays[attempt]), () {
      // Use the stored valid context first, then fallback to provided context or navigator key
      BuildContext? targetContext = _validContext;
      
      if (targetContext == null || !targetContext.mounted) {
        targetContext = context ?? navigatorKey.currentContext;
      }
      
      if (targetContext != null && targetContext.mounted) {
        print('FloatingActivityService: Attempting with context on try ${attempt + 1}');
        print('FloatingActivityService: Context widget tree:');
        targetContext.visitAncestorElements((element) {
          print('  - ${element.widget.runtimeType}');
          if (element.widget.runtimeType.toString().contains('MaterialApp')) {
            print('    ^ Found MaterialApp!');
          }
          return true;
        });
        
        try {
          // Try to use root overlay directly
          final overlay = Overlay.of(targetContext, rootOverlay: true);
          if (overlay.mounted) {
            _showFloatingWidget(targetContext);
            return;
          }
        } catch (e) {
          print('FloatingActivityService: Overlay not ready on attempt ${attempt + 1}: $e');
        }
      } else {
        print('FloatingActivityService: No valid context on attempt ${attempt + 1}');
      }
      
      // If we reach here, try again with the next delay
      _attemptToShowFloatingWidget(context, attempt + 1);
    });
  }

  void hideOnPageEnter() {
    _isOnTrackingScreen = true;
    _hideFloatingWidget();
  }

  void dispose() {
    _sessionSubscription?.cancel();
    _sessionNotifier.dispose();
    _isOverlayActive.dispose();
    _hideFloatingWidget();
  }
}
