import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../main.dart';
import '../features/auth/login_screen.dart';
import '../features/home/all_activities_screen.dart';
import '../features/home/home_screen.dart';
import '../features/home/weekly_stats_screen.dart';
import '../features/tracking/activity_summary_screen.dart';
import '../features/tracking/running_tracking_screen.dart';
import '../features/tracking/cycling_tracking_screen.dart';
import '../features/tracking/walking_tracking_screen.dart';
import '../features/profile/profile_screen.dart'; // Import ProfileScreen
import '../features/settings/notification_settings_screen.dart'; // Import NotificationSettingsScreen
import '../models/activity_models.dart';
import '../widgets/main_layout.dart';

class AppRouter {
  static GoRouter get router => _router;
  static final _router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isLoggedIn = user != null;
      final isLoggingIn = state.matchedLocation == '/login';

      // Debug logging
      print('Redirect check - Location: ${state.matchedLocation}, User: ${user?.uid}, LoggedIn: $isLoggedIn');

      // If not logged in and not on login page, redirect to login
      if (!isLoggedIn && !isLoggingIn) {
        print('Redirecting to login - not logged in');
        return '/login';
      }

      // If logged in and on login page, redirect to home
      if (isLoggedIn && isLoggingIn) {
        print('Redirecting to home - already logged in');
        return '/home';
      }

      // No redirect needed
      print('No redirect needed');
      return null;
    },    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      // Shell route untuk halaman yang membutuhkan bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/all-activities',
            name: 'all-activities',
            builder: (context, state) => const AllActivitiesScreen(),
          ),
          GoRoute(
            path: '/weekly-stats',
            name: 'weekly-stats',
            builder: (context, state) => const WeeklyStatsScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/notification-settings',
            name: 'notification-settings',
            builder: (context, state) => const NotificationSettingsScreen(),
          ),
        ],
      ),
      
      // Routes tanpa bottom navigation (tracking screens)
      GoRoute(
        path: '/running-tracking',
        name: 'running-tracking',
        builder: (context, state) => const RunningTrackingScreen(),
      ),
      GoRoute(
        path: '/cycling-tracking',
        name: 'cycling-tracking',
        builder: (context, state) {
          try {
            return const CyclingTrackingScreen();
          } catch (e) {
            print('Error building CyclingTrackingScreen: $e');
            return const HomeScreen();
          }
        },
      ),
      GoRoute(
        path: '/walking-tracking',
        name: 'walking-tracking',
        builder: (context, state) {
          try {
            return const WalkingTrackingScreen();
          } catch (e) {
            print('Error building WalkingTrackingScreen: $e');
            return const HomeScreen();
          }
        },
      ),
      GoRoute(
        path: '/activity-summary',
        name: 'activity-summary',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final activity = extra?['activity'] as ActivitySession?;
          
          if (activity == null) {
            // If no activity is passed, redirect to home
            return const HomeScreen();
          }

          return ActivitySummaryScreen(activity: activity);
        },
      ),
    ],
    errorBuilder: (context, state) {
      print('Router error - Location: ${state.matchedLocation}, Error: ${state.error}');
      
      // Check if user is logged in for error cases
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // User is logged in but route not found, redirect to home
        return const HomeScreen();
      } else {
        // User not logged in, redirect to login
        return const LoginScreen();
      }
    },
  );
}
