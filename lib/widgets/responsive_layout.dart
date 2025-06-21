import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'clean_widgets.dart';

// Responsive Layout yang menggunakan Sidebar untuk web dan Bottom Navigation untuk mobile
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onNavigationTap;
  final VoidCallback onFabPressed;
  final bool isFabExpanded;
  final Animation<double> animation;
  final ValueChanged<String> onActivitySelected;

  const ResponsiveLayout({
    Key? key,
    required this.child,
    required this.currentIndex,
    required this.onNavigationTap,
    required this.onFabPressed,
    required this.isFabExpanded,
    required this.animation,
    required this.onActivitySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final navBar = CleanBottomNavBar(
      currentIndex: currentIndex,
      onTap: onNavigationTap,
      onFabPressed: onFabPressed,
      isFabExpanded: isFabExpanded,
      animation: animation,
      onActivitySelected: onActivitySelected,
    );

    if (kIsWeb) {
      // Layout untuk web dengan sidebar
      return Scaffold(
        backgroundColor: Colors.black,
        body: Row(
          children: [
            // Sidebar
            navBar,
            // Main content
            Expanded(
              child: child,
            ),
          ],
        ),
      );
    } else {
      // Layout untuk mobile dengan bottom navigation
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Main content
            child,
            // Bottom navigation overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: navBar,
            ),
          ],
        ),
      );
    }
  }
}
