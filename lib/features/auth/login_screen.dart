import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';
import '../../widgets/clean_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Starting sign in process from UI...');
      final userCredential = await _authService.signInWithGoogle();
      
      if (userCredential != null && mounted) {
        print('Sign in successful, navigating to home...');
        // Navigate to home screen using GoRouter
        if (mounted) {
          context.go('/home');
        }
      } else if (mounted) {
        print('Sign in cancelled or failed');
        // User cancelled or sign in failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sign in cancelled or failed'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('Exception in sign in: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign in: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [                      // App Logo and Title
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF00D4FF).withOpacity(0.9),
                                    const Color(0xFF00D4FF).withOpacity(0.7),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00D4FF).withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.directions_run,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 32),
                            const Text(
                              'RunUp',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Track your fitness journey',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withOpacity(0.7),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 80),
                        // Login Card
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(                          opacity: _fadeAnimation,
                          child: CleanCard(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                const Text(
                                  'Welcome Back',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Sign in to continue your fitness journey',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 40),
                                  // Google Sign In Button
                                CleanButton(
                                  width: double.infinity,
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black87,
                                  onPressed: _signInWithGoogle,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (!_isLoading) ...[
                                        Image.asset(
                                          'assets/google_logo.png',
                                          width: 20,
                                          height: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        const Text('Continue with Google'),
                                      ] else
                                        const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // Terms and Privacy
                                Text(
                                  'By continuing, you agree to our Terms of Service and Privacy Policy',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                              ],                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
