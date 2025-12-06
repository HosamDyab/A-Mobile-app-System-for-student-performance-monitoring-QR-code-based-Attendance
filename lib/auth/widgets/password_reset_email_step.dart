import 'package:flutter/material.dart';

import '../../shared/utils/app_colors.dart';
import '../../shared/widgets/animated_text_field.dart';
import '../../shared/widgets/modern_hover_button.dart';

/// First step of password reset: Enter email address.
///
/// Displays an email input field and a button to send OTP.
class PasswordResetEmailStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final Animation<double> fadeAnimation;
  final AnimationController animationController;
  final bool isLoading;
  final VoidCallback onSendOTP;
  final VoidCallback onBackToLogin;
  final String? Function(String?)? emailValidator;

  const PasswordResetEmailStep({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.fadeAnimation,
    required this.animationController,
    required this.isLoading,
    required this.onSendOTP,
    required this.onBackToLogin,
    this.emailValidator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated Icon
          _buildAnimatedIcon(colorScheme),
          const SizedBox(height: 28),

          // Title
          _buildTitle(theme),
          const SizedBox(height: 16),

          // Subtitle
          _buildSubtitle(theme, colorScheme),
          const SizedBox(height: 40),

          // Email Field
          _buildEmailField(),
          const SizedBox(height: 36),

          // Send OTP Button
          _buildSendButton(theme),
          const SizedBox(height: 20),

          // Back to Login
          _buildBackButton(theme),
        ],
      ),
    );
  }

  Widget _buildAnimatedIcon(ColorScheme colorScheme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withOpacity(0.15),
                  colorScheme.secondary.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.email_outlined,
              size: 64,
              color: colorScheme.primary,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animationController,
          curve: const Interval(0.2, 0.5, curve: Curves.easeOutCubic),
        )),
        child: Text(
          'Enter Your Email',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 28,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSubtitle(ThemeData theme, ColorScheme colorScheme) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animationController,
          curve: const Interval(0.3, 0.6, curve: Curves.easeOutCubic),
        )),
        child: Text(
          'Enter your MTI email to receive a verification code',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
            fontSize: 16,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: AnimatedTextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              hintText: 'Enter your MTI email address',
              prefixIcon: Icons.email_outlined,
              primaryColor: AppColors.primaryBlue,
              showLabel: false,
              animateIcon: true,
              validator: emailValidator,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSendButton(ThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: ModernHoverButton(
              label: 'Send OTP',
              icon: Icons.send_rounded,
              onPressed: onSendOTP,
              isLoading: isLoading,
              height: 64,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackButton(ThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: TextButton.icon(
              onPressed: onBackToLogin,
              icon: Icon(
                Icons.arrow_back_rounded,
                size: 16,
                color: AppColors.primaryBlue,
              ),
              label: Text(
                'Back to Login',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
