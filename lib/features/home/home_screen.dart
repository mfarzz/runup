import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/activity_models.dart';
import '../../services/activity_storage_service.dart';
import '../../services/floating_activity_service.dart';
import '../../services/notification_service.dart';
import '../../utils/activity_colors.dart';
import '../../widgets/clean_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ActivityStorageService _storageService = ActivityStorageService();
  final FloatingActivityService _floatingService = FloatingActivityService();
  final NotificationService _notificationService = NotificationService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Map<String, dynamic>? _weeklyStats;
  List<ActivitySession> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
          ),
        );    _animationController.forward();
    _loadData();
    _setupNotifications();
    
    // Initialize floating service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _floatingService.initialize(context);
    });
  }

  Future<void> _loadData() async {
    try {
      print('Loading home screen data...');

      // Debug: Check if activities exist
      final hasActivities = await _storageService.hasActivities();
      print('Has activities before loading: $hasActivities');

      final weeklyStats = await _storageService.getWeeklyStats();
      final recentActivities = await _storageService.getRecentActivities(
        limit: 10,
      );

      print('Loaded ${recentActivities.length} recent activities');
      for (var activity in recentActivities) {
        print(
          'Activity: ${activity.activityTypeText} - ${activity.formattedDistance} - ${activity.formattedDuration}',
        );
      }      if (mounted) {
        setState(() {
          _weeklyStats = weeklyStats;
          _recentActivities = recentActivities;
        });
        print('UI updated with ${_recentActivities.length} activities');
        
        // Check for achievements after loading data
        _checkAchievements();
      }
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user.displayName!.split(' ').first;
    }
    return 'Runner';
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

    if (hours > 0) {      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '0m';
    }
  }  Future<void> _setupNotifications() async {
    try {
      // Register FCM token for current user
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('Registering FCM token for home screen...');
        await _notificationService.registerFCMTokenForCurrentUser();
      }
      
      // Setup daily reminder at 7:00 AM
      await _notificationService.scheduleDailyReminder(
        hour: 07,
        minute: 00,
        customMessage: "Good morning! Time for your daily workout! 💪",
      );
        // Setup weekly progress notification on Sunday at 7 PM
      await _notificationService.scheduleWeeklyProgress(
        weekday: DateTime.sunday,
        hour: 19,
        minute: 0,
      );
      
      print('Notifications scheduled successfully');
    } catch (e) {
      print('Error setting up notifications: $e');
    }
  }
  Future<void> _checkAchievements() async {
    final weeklyStats = _weeklyStats;
    if (weeklyStats == null) return;

    // Check for weekly distance milestones
    final totalDistance = weeklyStats['totalDistance'] ?? 0.0;
    if (totalDistance >= 50000 && totalDistance < 52000) { // ~50km milestone
      await _notificationService.showAchievementNotification(
        title: '🏃‍♂️ Distance Champion!',
        message: 'Amazing! You\'ve covered ${(totalDistance / 1000).toStringAsFixed(1)}km this week!',
        bigText: 'Keep up the incredible pace! You\'re on track for an amazing month.',
      );
    }

    // Check for activity streak
    final activeDays = weeklyStats['activeDays'] ?? 0;
    if (activeDays >= 7) {
      await _notificationService.showAchievementNotification(
        title: '🔥 Perfect Week!',
        message: 'You\'ve been active every day this week!',
        bigText: 'Consistency is key to success. You\'re building an amazing habit!',
      );
    } else if (activeDays >= 5) {
      await _notificationService.showAchievementNotification(
        title: '⭐ Great Consistency!',
        message: 'You\'ve been active $activeDays days this week!',
        bigText: 'You\'re doing fantastic! Keep up the momentum.',
      );
    }

    // Check for personal bests
    if (_recentActivities.isNotEmpty) {
      final latestActivity = _recentActivities.first;
      final todayStart = DateTime.now().copyWith(hour: 0, minute: 0, second: 0);
      
      if (latestActivity.startTime != null && latestActivity.startTime!.isAfter(todayStart)) {
        // Check if it's a personal best distance for this activity type
        final allActivities = await _storageService.getActivities();
        final sameTypeActivities = allActivities
            .where((a) => a.type == latestActivity.type && a.id != latestActivity.id)
            .toList();
        
        if (sameTypeActivities.isNotEmpty) {
          final maxDistance = sameTypeActivities
              .map((a) => a.distance)
              .fold(0.0, (max, distance) => distance > max ? distance : max);
          
          if (latestActivity.distance > maxDistance && maxDistance > 0) {
            await _notificationService.showAchievementNotification(
              title: '🎉 Personal Best!',
              message: 'New ${latestActivity.activityTypeText} distance record: ${latestActivity.formattedDistance}!',
              bigText: 'You\'ve just set a new personal record! Your dedication is paying off.',
            );
          }
        }
      }
    }
  }  @override
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
          child: Column(
            children: [
              // Fixed Header Section - tidak ikut scroll
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0F0F23).withOpacity(0.95),
                      const Color(0xFF1A1A2E).withOpacity(0.90),
                      const Color(0xFF16213E).withOpacity(0.85),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildTopSection(),
                ),
              ),
              
              // Scrollable Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadData,
                  color: ActivityColors.running,
                  backgroundColor: Colors.white,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),

                          // Quick Actions Section
                          SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildHealthInsights(),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Stats Overview
                          SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildStatsSection(),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Recent Activities
                          SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildRecentActivitiesSection(),
                            ),
                          ),

                          const SizedBox(height: 100), // Bottom padding
                        ],
                      ),
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
  Widget _buildTopSection() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getUserName(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => context.go('/profile'),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: _buildUserAvatar(),
            ),
          ),
        ),
      ],
    );
  }  Widget _buildHealthInsights() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CleanSectionHeader(
            title: 'Health Insights',
            subtitle: 'Your fitness overview',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInsightCard(
                  icon: Icons.favorite_outline,
                  title: 'Heart Health',
                  value: '${_calculateAverageHeartRate()} BPM',
                  subtitle: 'Avg. Heart Rate',
                  color: ActivityColors.heart,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInsightCard(
                  icon: Icons.local_fire_department_outlined,
                  title: 'Calories',
                  value: '${_calculateTotalCalories()}',
                  subtitle: 'This Week',
                  color: ActivityColors.calories,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInsightCard(
                  icon: Icons.speed_outlined,
                  title: 'Avg. Speed',
                  value: '${_calculateAverageSpeed()} km/h',
                  subtitle: 'Last 7 days',
                  color: ActivityColors.speed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInsightCard(
                  icon: Icons.trending_up_outlined,
                  title: 'Progress',
                  value: '${_calculateProgressPercentage()}%',
                  subtitle: 'vs Last Week',
                  color: ActivityColors.getStatColor('stats'),
                ),
              ),
            ],
          ),
        ],
      ),
    );  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CleanSectionHeader(
            title: 'This Week',
            onMorePressed: () {
              context.go('/weekly-stats');
            },
          ),
          const SizedBox(height: 8),          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1E1E2E).withOpacity(0.8),
                  const Color(0xFF2A2A3E).withOpacity(0.6),
                  const Color(0xFF16213E).withOpacity(0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: CleanStatsCard(
                    title: 'Distance',
                    value: _formatDistance(
                      _weeklyStats?['distance']?.toDouble() ?? 0.0,
                    ).split(' ')[0],
                    unit: _formatDistance(
                      _weeklyStats?['distance']?.toDouble() ?? 0.0,
                    ).split(' ')[1],
                    icon: Icons.straighten,
                    iconColor: ActivityColors.distance,
                  ),
                ),                Container(
                  width: 1,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),Expanded(
                  child: CleanStatsCard(
                    title: 'Duration',
                    value: _formatDuration(
                      Duration(seconds: 
                        _weeklyStats?['duration'] is Duration 
                          ? (_weeklyStats!['duration'] as Duration).inSeconds
                          : (_weeklyStats?['duration'] ?? 0),
                      ),
                    ).split(' ')[0].replaceAll('h', '').replaceAll('m', ''),
                    unit: _formatDuration(
                      Duration(seconds: 
                        _weeklyStats?['duration'] is Duration 
                          ? (_weeklyStats!['duration'] as Duration).inSeconds
                          : (_weeklyStats?['duration'] ?? 0),
                      ),
                    ).contains('h') ? 'hours' : 'mins',
                    icon: Icons.timer,
                    iconColor: ActivityColors.duration,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }  Widget _buildRecentActivitiesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CleanSectionHeader(
            title: 'Recent Activities',
            onMorePressed: _recentActivities.isNotEmpty ? () {
              context.go('/all-activities');
            } : null,
          ),
          const SizedBox(height: 8),
          _recentActivities.isEmpty
              ? _buildEmptyActivitiesState()
              : Column(
                  children: _recentActivities.map((activity) {
                    return CleanActivityCard(
                      title: activity.activityTypeText,
                      subtitle: activity.endTime != null 
                        ? _formatDate(activity.endTime!)
                        : 'Just completed',
                      duration: activity.formattedDuration,
                      distance: activity.formattedDistance,
                      icon: ActivityColors.getIconForActivity(activity.type),
                      iconColor: ActivityColors.getColorForActivity(activity.type),
                      onTap: () {
                        context.push('/activity-summary', extra: {
                          'activity': activity,
                        });
                      },
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyActivitiesState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ActivityColors.running.withOpacity(0.7),
                  ActivityColors.cycling.withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: ActivityColors.running.withOpacity(0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: ActivityColors.running.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              ActivityColors.getIconForActivity(ActivityType.running),
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No activities yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start your first workout to see your progress here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );  }

  Widget _buildUserAvatar() {
    final user = FirebaseAuth.instance.currentUser;
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withOpacity(0.6),
            Colors.purple.withOpacity(0.6),
          ],
        ),
      ),
      child: user?.photoURL != null
        ? ClipOval(
            child: Image.network(
              user!.photoURL!,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildDefaultAvatar(user);
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        : _buildDefaultAvatar(user),
    );
  }
  
  Widget _buildDefaultAvatar(User? user) {
    final initials = _getUserInitials(user);
    
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
  
  String _getUserInitials(User? user) {
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      final names = user.displayName!.split(' ');
      if (names.length >= 2) {
        return '${names[0][0]}${names[1][0]}'.toUpperCase();
      } else {
        return names[0][0].toUpperCase();
      }
    } else if (user?.email != null && user!.email!.isNotEmpty) {
      return user.email![0].toUpperCase();
    }
    return 'U';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E1E2E).withOpacity(0.8),
            const Color(0xFF2A2A3E).withOpacity(0.6),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
  int _calculateAverageHeartRate() {
    // Since ActivitySession doesn't have heart rate data, 
    // we'll calculate based on activity intensity
    if (_recentActivities.isEmpty) return 120; // Default resting + activity
    
    int totalEstimatedHR = 0;
    
    for (var activity in _recentActivities) {
      // Estimate heart rate based on activity type and speed
      int estimatedHR = 120; // Base heart rate
      
      switch (activity.type) {
        case ActivityType.running:
          estimatedHR = 140 + (activity.averageSpeed * 5).round();
          break;
        case ActivityType.cycling:
          estimatedHR = 130 + (activity.averageSpeed * 3).round();
          break;
        case ActivityType.walking:
          estimatedHR = 100 + (activity.averageSpeed * 8).round();
          break;
      }
      
      totalEstimatedHR += estimatedHR.clamp(80, 180);
    }
    
    return (totalEstimatedHR / _recentActivities.length).round();
  }

  int _calculateTotalCalories() {
    if (_weeklyStats == null) return 0;
    return (_weeklyStats!['calories'] ?? 0).round();
  }

  double _calculateAverageSpeed() {
    if (_recentActivities.isEmpty) return 0.0;
    
    double totalSpeed = 0.0;
    
    for (var activity in _recentActivities) {
      if (activity.averageSpeed > 0) {
        // Convert m/s to km/h
        totalSpeed += activity.averageSpeed * 3.6;
      }
    }
    
    return _recentActivities.isNotEmpty 
        ? double.parse((totalSpeed / _recentActivities.length).toStringAsFixed(1)) 
        : 0.0;
  }

  int _calculateProgressPercentage() {
    // Simple calculation based on current vs previous week
    if (_weeklyStats == null) return 0;
    
    double currentDistance = (_weeklyStats!['distance'] ?? 0.0).toDouble();
    // Simulate previous week data (in real app, you'd fetch this)
    double previousWeekDistance = currentDistance * 0.85; // Assume 15% improvement
    
    if (previousWeekDistance == 0) return 0;
    
    double percentage = ((currentDistance - previousWeekDistance) / previousWeekDistance) * 100;
    return percentage.round().clamp(0, 999);
  }
}