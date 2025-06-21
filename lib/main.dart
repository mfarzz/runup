import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'router/app_router.dart';
import 'services/notification_service.dart';

// Global navigator key for floating widgets
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize notification service
  await NotificationService().initialize();
  
  // Initialize FCM
  await NotificationService().initializeFCM();
  
  runApp(const RunUpApp());
}

class RunUpApp extends StatelessWidget {
  const RunUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RunUp',
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
      // Add a builder to ensure we have a proper overlay context
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF), // iOS blue
          brightness: Brightness.light,
        ),
        fontFamily: 'SF Pro Display',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF),
          brightness: Brightness.dark,
        ),
        fontFamily: 'SF Pro Display',
      ),
    );
  }
}


