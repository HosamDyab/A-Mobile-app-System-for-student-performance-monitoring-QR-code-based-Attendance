import 'package:flutter/material.dart';

import '../../shared/utils/app_colors.dart';
import '../../shared/widgets/modern_logo_widget.dart';

/// Displays the animated header section of the login form.
///
/// Includes:
/// - MTI logo with gradient background
/// - Role name (e.g., "Student", "Faculty")
/// - "Welcome Back" title with gradient text effect
/// - Subtitle message
class LoginFormHeader extends StatelessWidget {
  final String roleName;
  final Animation<double> logoScaleAnimation;
  final Animation<double> textOpacityAnimation;
  final Animation<Offset> textSlideAnimation;

  const LoginFormHeader({
    super.key,
    required this.roleName,
    required this.logoScaleAnimation,
    required this.textOpacityAnimation,
    required this.textSlideAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Modern Clean Animated MTI Logo
        ModernLogoWidget(
          height: 120,
          showBackground: false,
          scaleAnimation: logoScaleAnimation,
        ),
        const SizedBox(height: 36),

        // Animated Role Title
        FadeTransition(
          opacity: textOpacityAnimation,
          child: SlideTransition(
            position: textSlideAnimation,
            child: Text(
              roleName,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 32,
                color: AppColors.tertiaryBlack,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Animated Welcome Title with Gradient
        FadeTransition(
          opacity: textOpacityAnimation,
          child: SlideTransition(
            position: textSlideAnimation,
            child: ShaderMask(
              shaderCallback: (bounds) => AppColors.primaryGradient.createShader(
                Rect.fromLTWH(0, 0, bounds.width, bounds.height),
              ),
              blendMode: BlendMode.srcIn,
              child: Text(
                'Welcome Back',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 40,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Animated Subtitle
        FadeTransition(
          opacity: textOpacityAnimation,
          child: SlideTransition(
            position: textSlideAnimation,
            child: Text(
              'Log in to continue your learning journey.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontSize: 17,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

