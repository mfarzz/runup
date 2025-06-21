import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/home/all_activities_screen.dart';
import '../features/home/home_screen.dart';
import '../features/home/weekly_stats_screen.dart';
import '../features/profile/profile_screen.dart';
import '../widgets/responsive_layout.dart';

// Notification Screen - untuk sementara buat sederhana
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Main Layout dengan Bottom Navigation
class MainLayout extends StatefulWidget {
  final Widget? child; // Child widget untuk shell route
  
  const MainLayout({Key? key, this.child}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isFabExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const AllActivitiesScreen(),
    const WeeklyStatsScreen(), // Ubah dari NotificationScreen ke WeeklyStatsScreen
    const ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // Navigate to corresponding route
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/all-activities');
        break;
      case 2:
        context.go('/weekly-stats');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  void _onFabPressed() {
    setState(() {
      _isFabExpanded = !_isFabExpanded;
    });
    
    if (_isFabExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _updateCurrentIndexFromRoute(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    switch (location) {
      case '/home':
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
        break;
      case '/all-activities':
        if (_currentIndex != 1) {
          setState(() {
            _currentIndex = 1;
          });
        }
        break;
      case '/weekly-stats':
        if (_currentIndex != 2) {
          setState(() {
            _currentIndex = 2;
          });
        }
        break;
      case '/profile':
      case '/notification-settings':
        if (_currentIndex != 3) {
          setState(() {
            _currentIndex = 3;
          });
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Update current index berdasarkan route saat ini (tanpa setState dalam build)
    if (widget.child != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateCurrentIndexFromRoute(context);
      });
    }
    
    return ResponsiveLayout(
      currentIndex: _currentIndex,
      onNavigationTap: _onTabTapped,
      onFabPressed: _onFabPressed,
      isFabExpanded: _isFabExpanded,
      animation: _animation,
      onActivitySelected: (String activity) {
        setState(() {
          _isFabExpanded = false;
        });
        _animationController.reverse();
        // Handle activity selection dengan navigasi
        switch (activity) {
          case 'running':
            context.go('/running-tracking');
            break;
          case 'cycling':
            context.go('/cycling-tracking');
            break;
          case 'walking':
            context.go('/walking-tracking');
            break;
        }
      },
      child: widget.child ?? _screens[_currentIndex],
    );
  }
}
