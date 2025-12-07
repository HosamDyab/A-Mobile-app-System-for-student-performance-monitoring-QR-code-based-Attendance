import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Curved Bottom Navigation Bar with integrated Floating Action Button (FAB).
///
/// Features:
/// - Custom curved notch for FAB
/// - Smooth animations between tabs
/// - Animated FAB with contextual icons
/// - Theme-aware styling
/// - Hover effects on navigation items
class CurvedBottomNavWithFAB extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavBarItem> items;
  final VoidCallback onFABPressed;
  final IconData fabIcon;
  final String fabTooltip;

  const CurvedBottomNavWithFAB({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    required this.onFABPressed,
    this.fabIcon = Icons.add_rounded,
    this.fabTooltip = 'Add',
  });

  @override
  State<CurvedBottomNavWithFAB> createState() => _CurvedBottomNavWithFABState();
}

class _CurvedBottomNavWithFABState extends State<CurvedBottomNavWithFAB>
    with TickerProviderStateMixin {
  late AnimationController _fabController;
  late AnimationController _navController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _fabRotationAnimation;

  @override
  void initState() {
    super.initState();

    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _navController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );

    _fabRotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    _navController.dispose();
    super.dispose();
  }

  void _handleFABPressed() {
    _fabController.forward().then((_) {
      _fabController.reverse();
    });
    widget.onFABPressed();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // Bottom Navigation Bar with Notch
        _buildBottomBar(theme, isDark),

        // Floating Action Button
        Positioned(
          bottom: 20,
          child: _buildFAB(theme),
        ),
      ],
    );
  }

  Widget _buildBottomBar(ThemeData theme, bool isDark) {
    return Container(
      height: 75,
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, -8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipPath(
        clipper: _BottomBarClipper(),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: _buildNavItems(theme, isDark),
        ),
      ),
    );
  }

  Widget _buildNavItems(ThemeData theme, bool isDark) {
    return SafeArea(
      top: false,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Left items (before FAB)
          ...widget.items.take(widget.items.length ~/ 2).map((item) {
            final index = widget.items.indexOf(item);
            return _buildNavItem(item, index, theme, isDark);
          }),

          // Spacer for FAB
          const SizedBox(width: 80),

          // Right items (after FAB)
          ...widget.items.skip(widget.items.length ~/ 2).map((item) {
            final index = widget.items.indexOf(item);
            return _buildNavItem(item, index, theme, isDark);
          }),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      NavBarItem item, int index, ThemeData theme, bool isDark) {
    final isSelected = index == widget.currentIndex;
    final unselectedColor = isDark
        ? theme.colorScheme.onSurface.withOpacity(0.6)
        : AppColors.tertiaryLightGray;

    return Expanded(
      child: _NavItemButton(
        item: item,
        isSelected: isSelected,
        onTap: () => widget.onTap(index),
        selectedColor: AppColors.primaryBlue,
        unselectedColor: unselectedColor,
        theme: theme,
      ),
    );
  }

  Widget _buildFAB(ThemeData theme) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fabScaleAnimation, _fabRotationAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _fabScaleAnimation.value,
          child: Transform.rotate(
            angle: _fabRotationAnimation.value * 3.14159, // PI
            child: Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.5),
                    blurRadius: 25,
                    offset: const Offset(0, 8),
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: _handleFABPressed,
                  customBorder: const CircleBorder(),
                  child: Icon(
                    widget.fabIcon,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Custom clipper to create the curved notch for the FAB
class _BottomBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final notchRadius = 38.0;
    final notchMargin = 8.0;

    path.lineTo(0, 0);

    // Left side before notch
    path.lineTo(centerX - notchRadius - notchMargin, 0);

    // Create curved notch
    path.arcToPoint(
      Offset(centerX, notchRadius - 5),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );

    path.arcToPoint(
      Offset(centerX + notchRadius + notchMargin, 0),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );

    // Right side after notch
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Individual navigation item with hover animation
class _NavItemButton extends StatefulWidget {
  final NavBarItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color unselectedColor;
  final ThemeData theme;

  const _NavItemButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.selectedColor,
    required this.unselectedColor,
    required this.theme,
  });

  @override
  State<_NavItemButton> createState() => _NavItemButtonState();
}

class _NavItemButtonState extends State<_NavItemButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: _scaleAnimation.value,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: EdgeInsets.all(widget.isSelected ? 8 : 6),
                      decoration: BoxDecoration(
                        gradient: widget.isSelected
                            ? LinearGradient(
                                colors: [
                                  widget.selectedColor.withOpacity(0.2),
                                  widget.selectedColor.withOpacity(0.1),
                                ],
                              )
                            : null,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.item.icon,
                        color: widget.isSelected
                            ? widget.selectedColor
                            : widget.unselectedColor,
                        size: widget.isSelected ? 24 : 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontSize: widget.isSelected ? 10 : 9,
                      fontWeight:
                          widget.isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: widget.isSelected
                          ? widget.selectedColor
                          : widget.unselectedColor,
                      height: 1.0,
                    ),
                    child: Text(
                      widget.item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Navigation bar item model
class NavBarItem {
  final IconData icon;
  final String label;

  const NavBarItem({
    required this.icon,
    required this.label,
  });
}
