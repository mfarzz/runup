import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'notification_service.dart';
import 'storage_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Tambahkan client ID untuk web
    clientId: kIsWeb 
        ? '520954394142-jinv4195ci2h97h7p4ht0gc8oar5t2bc.apps.googleusercontent.com'
        : null,
  );
  final StorageService _storage = StorageService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      print('Starting Google Sign-In process...');
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('User cancelled Google Sign-In');
        return null;
      }

      print('Google user obtained: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      print('Google authentication obtained');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('Firebase credential created');

      // Once signed in, return the UserCredential
      final userCredential = await _auth.signInWithCredential(credential);
      
      print('Firebase sign-in successful: ${userCredential.user?.email}');      // Store user info securely
      if (userCredential.user != null) {
        final user = userCredential.user!;
        await _storage.write('user_id', user.uid);
        await _storage.write('user_email', user.email);
        
        // Store display name and photo URL if available
        if (user.displayName != null) {
          await _storage.write('user_name', user.displayName!);
        }
        if (user.photoURL != null) {
          await _storage.write('user_photo', user.photoURL!);
        }
        
        print('User data stored securely');
        print('Photo URL: ${user.photoURL}');
      }
        
      // Register FCM token after successful login
      try {
        await NotificationService().registerFCMTokenForCurrentUser();
        print('FCM token registration initiated after login');
      } catch (e) {
        print('Error registering FCM token after login: $e');
      }

      return userCredential;
    } catch (e, stackTrace) {
      print('Error signing in with Google: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();      // Only delete user-specific data, not all storage data
      await _storage.delete('user_id');
      await _storage.delete('user_email');
      await _storage.delete('user_name');
      await _storage.delete('user_photo');
      
      print('User signed out successfully');
    } catch (e) {
      print('Error signing out: $e');
    }
  }  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    if (kIsWeb) {
      // Untuk web, cukup cek current user Firebase
      return _auth.currentUser != null;
    }
    
    final userId = await _storage.read('user_id');
    return userId != null && _auth.currentUser != null;
  }

  // Update stored profile photo
  Future<void> updateStoredProfilePhoto() async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.photoURL != null) {
        await _storage.write('user_photo', user.photoURL!);
        print('Profile photo updated in storage: ${user.photoURL}');
      }
    } catch (e) {
      print('Error updating stored profile photo: $e');
    }
  }
}
