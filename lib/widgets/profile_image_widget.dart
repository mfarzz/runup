import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/storage_service.dart';

class ProfileImageWidget extends StatefulWidget {
  final double size;
  final double borderWidth;
  final Color? borderColor;

  const ProfileImageWidget({
    Key? key,
    this.size = 80,
    this.borderWidth = 2,
    this.borderColor,
  }) : super(key: key);

  @override
  State<ProfileImageWidget> createState() => _ProfileImageWidgetState();
}

class _ProfileImageWidgetState extends State<ProfileImageWidget> {
  String? _storedPhotoUrl;
  String? _cachedPhotoUrl;
  DateTime? _lastFetch;
  bool _isLoadingStored = false;
  final StorageService _storage = StorageService();

  @override
  void initState() {
    super.initState();
    _loadStoredPhoto();
  }

  Future<void> _loadStoredPhoto() async {
    if (_isLoadingStored) return;
    
    setState(() {
      _isLoadingStored = true;
    });

    try {
      final storedPhoto = await _storage.read('user_photo');
      if (storedPhoto != null && mounted) {
        setState(() {
          _storedPhotoUrl = storedPhoto;
        });
      }
    } catch (e) {
      print('Error loading stored photo: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStored = false;
        });
      }
    }
  }

  // Generate Gravatar URL as fallback
  String _generateGravatarUrl(String email, int size) {
    final bytes = utf8.encode(email.toLowerCase().trim());
    final digest = md5.convert(bytes);
    return 'https://www.gravatar.com/avatar/$digest?s=$size&d=identicon';
  }

  // Get effective photo URL with smart fallback strategy
  String? get _effectivePhotoUrl {
    final user = FirebaseAuth.instance.currentUser;
    
    // Untuk web, hindari Google Photos URL dan langsung gunakan Gravatar atau stored photo
    if (kIsWeb) {
      // Prioritas untuk web: stored photo, kemudian Gravatar
      if (_storedPhotoUrl != null && _storedPhotoUrl!.isNotEmpty) {
        return _storedPhotoUrl;
      }
      
      // Fallback to Gravatar jika ada email
      if (user?.email != null && user!.email!.isNotEmpty) {
        return _generateGravatarUrl(user.email!, widget.size.toInt());
      }
      
      return null;
    }
    
    // Untuk mobile, gunakan cached URL jika tersedia dan masih fresh
    if (_cachedPhotoUrl != null && _lastFetch != null) {
      final difference = DateTime.now().difference(_lastFetch!);
      if (difference.inMinutes < 10) {
        return _cachedPhotoUrl;
      }
    }

    // Prioritas untuk mobile: Firebase Auth photoURL, kemudian stored photo, kemudian Gravatar
    if (user?.photoURL != null && user!.photoURL!.isNotEmpty) {
      _cachedPhotoUrl = user.photoURL;
      _lastFetch = DateTime.now();
      return _cachedPhotoUrl;
    }
    
    if (_storedPhotoUrl != null && _storedPhotoUrl!.isNotEmpty) {
      return _storedPhotoUrl;
    }
    
    // Fallback to Gravatar if we have email
    if (user?.email != null && user!.email!.isNotEmpty) {
      return _generateGravatarUrl(user.email!, widget.size.toInt());
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (widget.borderColor ?? theme.primaryColor).withOpacity(0.1),
        border: Border.all(
          color: (widget.borderColor ?? theme.primaryColor).withOpacity(0.3),
          width: widget.borderWidth,
        ),
      ),
      child: ClipOval(
        child: _buildProfileImage(user, theme),
      ),
    );
  }

  Widget _buildProfileImage(User? user, ThemeData theme) {
    // Use cached/effective photo URL
    String? photoUrl = _effectivePhotoUrl;
    
    // If still no photo URL, show initials
    if (photoUrl == null || photoUrl.isEmpty) {
      return _buildInitialsAvatar(user, theme);
    }
    
    return Image.network(
      photoUrl,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.cover,
      // Add error handling untuk fallback ke initials jika gagal load
      errorBuilder: (context, error, stackTrace) {
        print('Error loading profile image: $error');
        return _buildInitialsAvatar(user, theme);
      },
      // Add loading placeholder
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / 
                  loadingProgress.expectedTotalBytes!
                : null,
            strokeWidth: 2,
          ),
        );
      },
    );
  }

  Widget _buildInitialsAvatar(User? user, ThemeData theme) {
    final initials = _getUserInitials(user);
    
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getColorFromInitials(initials).withOpacity(0.8),
            _getColorFromInitials(initials),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.size * 0.4, // 40% of container size
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  String _getUserInitials(User? user) {
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      final names = user.displayName!.trim().split(' ');
      if (names.length >= 2) {
        return '${names.first[0]}${names.last[0]}'.toUpperCase();
      } else {
        return names.first.substring(0, 1).toUpperCase();
      }
    } else if (user?.email != null && user!.email!.isNotEmpty) {
      // Use first letter of email if no display name
      return user.email!.substring(0, 1).toUpperCase();
    }
    return 'U'; // Default fallback
  }

  Color _getColorFromInitials(String initials) {
    // Generate a consistent color based on initials
    final hash = initials.hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[hash.abs() % colors.length];
  }
}
