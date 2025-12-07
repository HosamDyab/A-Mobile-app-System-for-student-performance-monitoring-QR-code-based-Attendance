import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Modern, reusable MTI logo widget with consistent styling across the app.
///
/// Features:
/// - Clean, border-free design with subtle gradient background
/// - Automatic theme adaptation (light/dark mode)
/// - Smooth scale animation
/// - Consistent sizing and spacing
/// - Fallback icon if image fails to load
class ModernLogoWidget extends StatelessWidget {
  /// Height of the logo container
  final double height;

  /// Whether to show the gradient background
  final bool showBackground;

  /// Optional animation for scaling
  final Animation<double>? scaleAnimation;

  /// Background opacity (0.0 to 1.0)
  final double backgroundOpacity;

  const ModernLogoWidget({
    super.key,
    this.height = 120,
    this.showBackground = false,
    this.scaleAnimation,
    this.backgroundOpacity = 0.05,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget logoContent = Container(
      height: height,
      decoration: showBackground
          ? BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        AppColors.primaryBlue.withOpacity(backgroundOpacity),
                        AppColors.secondaryOrange
                            .withOpacity(backgroundOpacity * 0.5),
                      ]
                    : [
                        AppColors.primaryBlue
                            .withOpacity(backgroundOpacity * 1.5),
                        AppColors.secondaryOrange
                            .withOpacity(backgroundOpacity * 0.8),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            )
          : null,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(showBackground ? 20.0 : 0),
          child: Image.asset(
            'lib/images/MTI Logo.png',
            fit: BoxFit.contain,
            height: showBackground ? height - 40 : height,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: showBackground ? height - 40 : height,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.school_rounded,
                  size: (showBackground ? height - 40 : height) * 0.6,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
      ),
    );

    // Apply scale animation if provided
    if (scaleAnimation != null) {
      logoContent = AnimatedBuilder(
        animation: scaleAnimation!,
        builder: (context, child) {
          return Transform.scale(
            scale: scaleAnimation!.value,
            child: child,
          );
        },
        child: logoContent,
      );
    }

    return logoContent;
  }
}

/// Animated logo widget with hover effect for interactive elements
class AnimatedLogoWidget extends StatefulWidget {
  final double height;
  final bool showBackground;
  final double backgroundOpacity;

  const AnimatedLogoWidget({
    super.key,
    this.height = 120,
    this.showBackground = false,
    this.backgroundOpacity = 0.05,
  });

  @override
  State<AnimatedLogoWidget> createState() => _AnimatedLogoWidgetState();
}

class _AnimatedLogoWidgetState extends State<AnimatedLogoWidget>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
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
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: ModernLogoWidget(
              height: widget.height,
              showBackground: widget.showBackground,
              backgroundOpacity: widget.backgroundOpacity,
            ),
          );
        },
      ),
    );
  }
}
