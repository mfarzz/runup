import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Clean Card Widget tanpa background glossy
class CleanCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool addBorder;
  final bool addBackground;

  const CleanCard({
    Key? key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.onTap,
    this.addBorder = false,
    this.addBackground = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: (addBorder || addBackground) ? BoxDecoration(
          color: addBackground ? Colors.white.withOpacity(0.08) : null,
          borderRadius: BorderRadius.circular(16),
          border: addBorder ? Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1,
          ) : null,
        ) : null,
        child: child,
      ),
    );
  }
}

// Clean Button tanpa efek glossy
class CleanButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final double borderRadius;

  const CleanButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.width,
    this.height,
    this.borderRadius = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
          foregroundColor: foregroundColor ?? Colors.white,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: child,
      ),
    );
  }
}

// Clean Text Field tanpa border berlebihan
class CleanTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const CleanTextField({
    Key? key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon != null 
          ? IconButton(
              icon: Icon(suffixIcon),
              onPressed: onSuffixIconPressed,
            )
          : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}

// Clean Stats Card tanpa background berlebihan
class CleanStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color? iconColor;

  const CleanStatsCard({
    Key? key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: iconColor ?? Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Clean Section Header
class CleanSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onMorePressed;

  const CleanSectionHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.onMorePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
            ],
          ),
          if (onMorePressed != null)
            TextButton(
              onPressed: onMorePressed,
              child: const Text(
                'See All',
                style: TextStyle(color: Colors.blue),
              ),
            ),
        ],
      ),
    );
  }
}

// Clean Activity Card
class CleanActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String duration;
  final String distance;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  const CleanActivityCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.distance,
    required this.icon,
    this.iconColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4), // Ubah horizontal margin menjadi 0
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E1E2E).withOpacity(0.8),
              const Color(0xFF2A2A3E).withOpacity(0.6),
              (iconColor ?? Theme.of(context).primaryColor).withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (iconColor ?? Theme.of(context).primaryColor).withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: (iconColor ?? Theme.of(context).primaryColor).withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (iconColor ?? Theme.of(context).primaryColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor ?? Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  duration,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  distance,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Clean Activity Card Compact (tanpa margin untuk digunakan dalam container)
class CleanActivityCardCompact extends StatelessWidget {
  final String title;
  final String subtitle;
  final String duration;
  final String distance;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  const CleanActivityCardCompact({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.distance,
    required this.icon,
    this.iconColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (iconColor ?? Theme.of(context).primaryColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor ?? Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  duration,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  distance,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Clean Navigation Bar yang responsif - Bottom Navigation untuk mobile, Sidebar untuk web
class CleanBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onFabPressed;
  final bool isFabExpanded;
  final Animation<double> animation;
  final ValueChanged<String> onActivitySelected;

  const CleanBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabPressed,
    required this.isFabExpanded,
    required this.animation,
    required this.onActivitySelected,
  }) : super(key: key);

  // Check if current platform should use sidebar
  bool get _shouldUseSidebar {
    return kIsWeb;
  }

  @override
  Widget build(BuildContext context) {
    if (_shouldUseSidebar) {
      return _buildSidebar(context);
    } else {
      return _buildBottomNavigation(context);
    }
  }

  // Sidebar untuk web
  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 280,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F0F23),
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
          ],
        ),
        border: Border(
          right: BorderSide(
            color: Colors.grey.shade800,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header dengan logo atau brand
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF667EEA),
                        Color(0xFF764BA2),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.bolt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'RunUp',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(color: Colors.grey, height: 1),
          
          // Navigation Items
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  _buildSidebarItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                    index: 0,
                  ),
                  _buildSidebarItem(
                    icon: Icons.history_outlined,
                    activeIcon: Icons.history_rounded,
                    label: 'Activity',
                    index: 1,
                  ),
                  _buildSidebarItem(
                    icon: Icons.bar_chart_outlined,
                    activeIcon: Icons.bar_chart_rounded,
                    label: 'Statistics',
                    index: 2,
                  ),
                  _buildSidebarItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profile',
                    index: 3,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Quick Actions Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Actions',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildQuickActionButton(
                          icon: Icons.directions_run,
                          label: 'Start Running',
                          color: const Color(0xFF4CAF50),
                          onTap: () => onActivitySelected('running'),
                        ),
                        const SizedBox(height: 8),
                        _buildQuickActionButton(
                          icon: Icons.directions_bike,
                          label: 'Start Cycling',
                          color: const Color(0xFF2196F3),
                          onTap: () => onActivitySelected('cycling'),
                        ),
                        const SizedBox(height: 8),
                        _buildQuickActionButton(
                          icon: Icons.directions_walk,
                          label: 'Start Walking',
                          color: const Color(0xFFFF9800),
                          onTap: () => onActivitySelected('walking'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = currentIndex == index;
    
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF667EEA).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive ? Border.all(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            width: 1,
          ) : null,
        ),
        child: Row(
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? const Color(0xFF667EEA) : Colors.grey.shade400,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade400,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bottom Navigation untuk mobile
  Widget _buildBottomNavigation(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isFabExpanded ? 210 : 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            const Color(0xFF0F0F23).withOpacity(0.6),
            const Color(0xFF0F0F23).withOpacity(0.9),
            const Color(0xFF0F0F23),
          ],
          stops: const [0.0, 0.2, 0.6, 1.0],
        ),
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Main Navigation Container dengan cekungan
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width - 48, 72),
              painter: NotchedNavigationPainter(
                color: const Color(0xFF1A1A2E),
                notchRadius: 32,
              ),
              child: Container(
                height: 72,
                child: Row(
                  children: [
                    // Left side icons
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavItem(
                            icon: Icons.home_outlined,
                            activeIcon: Icons.home_rounded,
                            index: 0,
                          ),
                          _buildNavItem(
                            icon: Icons.history_outlined,
                            activeIcon: Icons.history_rounded,
                            index: 1,
                          ),
                        ],
                      ),
                    ),
                    // Center space for FAB
                    const SizedBox(width: 80),
                    // Right side icons
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNavItem(
                            icon: Icons.bar_chart_outlined,
                            activeIcon: Icons.bar_chart_rounded,
                            index: 2,
                          ),
                          _buildNavItem(
                            icon: Icons.person_outline_rounded,
                            activeIcon: Icons.person_rounded,
                            index: 3,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Floating Activity Buttons
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Running button - kiri atas
                  if (isFabExpanded)
                    Positioned(
                      bottom: 66 + (45 * animation.value),
                      left: MediaQuery.of(context).size.width / 2 - 30 - (65 * animation.value),
                      child: Transform.scale(
                        scale: animation.value,
                        child: _buildFloatingActivityButton(
                          icon: Icons.directions_run,
                          color: const Color(0xFF4CAF50),
                          onTap: () => onActivitySelected('running'),
                        ),
                      ),
                    ),
                  
                  // Cycling button - atas
                  if (isFabExpanded)
                    Positioned(
                      bottom: 66 + (75 * animation.value),
                      child: Transform.scale(
                        scale: animation.value,
                        child: _buildFloatingActivityButton(
                          icon: Icons.directions_bike,
                          color: const Color(0xFF2196F3),
                          onTap: () => onActivitySelected('cycling'),
                        ),
                      ),
                    ),
                  
                  // Walking button - kanan atas
                  if (isFabExpanded)
                    Positioned(
                      bottom: 66 + (45 * animation.value),
                      right: MediaQuery.of(context).size.width / 2 - 30 - (65 * animation.value),
                      child: Transform.scale(
                        scale: animation.value,
                        child: _buildFloatingActivityButton(
                          icon: Icons.directions_walk,
                          color: const Color(0xFFFF9800),
                          onTap: () => onActivitySelected('walking'),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          
          // Floating Action Button utama
          Positioned(
            bottom: 58,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF667EEA),
                    Color(0xFF764BA2),
                    Color(0xFF6B46C1),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: onFabPressed,
                  child: AnimatedRotation(
                    turns: isFabExpanded ? 0.125 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(
                      Icons.bolt,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required int index,
  }) {
    final isActive = currentIndex == index;
    
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12), // Kurangi dari 20 ke 12
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? Colors.white : Colors.grey.shade400,
              size: 26, // Kurangi sedikit dari 28 ke 26
            ),
            if (isActive) ...[
              const SizedBox(height: 4),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActivityButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 52, // Diperbesar dari 44
      height: 52, // Diperbesar dari 44
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26), // Sesuai dengan radius baru
          onTap: onTap,
          child: Icon(
            icon,
            color: Colors.white,
            size: 24, // Diperbesar dari 20
          ),
        ),
      ),
    );
  }
}

// Custom Painter untuk membuat cekungan di navigation bar
class NotchedNavigationPainter extends CustomPainter {
  final Color color;
  final double notchRadius;

  NotchedNavigationPainter({
    required this.color,
    required this.notchRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final centerX = size.width / 2;
    final cornerRadius = 32.0; // Radius sudut navigation bar
    final notchDepth = 47.0; // Kedalaman cekungan diperdalam dari 32 ke 38
    final notchWidth = notchRadius + 18.0; // Lebar cekungan sedikit lebih kecil dari FAB
    final controlPointOffset = 18.0; // Smooth curve yang lebih besar untuk transisi

    // Mulai dari kiri bawah dengan radius
    path.moveTo(0, size.height - cornerRadius);
    path.quadraticBezierTo(0, size.height, cornerRadius, size.height);
    
    // Garis bawah kiri menuju kanan
    path.lineTo(size.width - cornerRadius, size.height);
    
    // Sudut kanan bawah dengan radius
    path.quadraticBezierTo(size.width, size.height, size.width, size.height - cornerRadius);
    
    // Sisi kanan naik
    path.lineTo(size.width, cornerRadius);
    
    // Sudut kanan atas dengan radius
    path.quadraticBezierTo(size.width, 0, size.width - cornerRadius, 0);

    // Garis atas kanan menuju cekungan
    path.lineTo(centerX + notchWidth, 0);
    
    // Masuk ke cekungan - sisi kanan dengan curve yang smooth dan lebih dalam
    path.quadraticBezierTo(
      centerX + notchWidth - controlPointOffset, 0,
      centerX + notchWidth - controlPointOffset, controlPointOffset * 1.5,
    );
    
    // Cekungan bagian kanan ke tengah - lebih dalam dan circular untuk FAB
    path.quadraticBezierTo(
      centerX + (notchRadius * 0.6), notchDepth * 0.8,
      centerX, notchDepth,
    );
    
    // Cekungan bagian kiri dari tengah - lebih dalam dan circular untuk FAB  
    path.quadraticBezierTo(
      centerX - (notchRadius * 0.6), notchDepth * 0.8,
      centerX - notchWidth + controlPointOffset, controlPointOffset * 1.5,
    );
    
    // Keluar dari cekungan - sisi kiri dengan curve yang smooth dan lebih dalam
    path.quadraticBezierTo(
      centerX - notchWidth + controlPointOffset, 0,
      centerX - notchWidth, 0,
    );

    // Garis atas kiri dari cekungan
    path.lineTo(cornerRadius, 0);
    
    // Sudut kiri atas dengan radius
    path.quadraticBezierTo(0, 0, 0, cornerRadius);
    
    // Sisi kiri turun
    path.lineTo(0, size.height - cornerRadius);

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}