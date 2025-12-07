import 'package:flutter/material.dart';

import '../../shared/utils/app_colors.dart';
import '../../shared/widgets/animated_text_field.dart';
import '../../shared/widgets/modern_hover_button.dart';

/// Second step of password reset: Verify OTP code.
///
/// Displays OTP input field, email display, and verification button.
class PasswordResetOTPStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController otpController;
  final String email;
  final Animation<double> fadeAnimation;
  final AnimationController animationController;
  final bool isLoading;
  final VoidCallback onVerifyOTP;
  final VoidCallback onResendOTP;
  final String? Function(String?)? otpValidator;

  const PasswordResetOTPStep({
    super.key,
    required this.formKey,
    required this.otpController,
    required this.email,
    required this.fadeAnimation,
    required this.animationController,
    required this.isLoading,
    required this.onVerifyOTP,
    required this.onResendOTP,
    this.otpValidator,
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

          // Subtitle with email
          _buildSubtitle(theme, colorScheme),
          const SizedBox(height: 40),

          // OTP Field
          _buildOTPField(colorScheme),
          const SizedBox(height: 36),

          // Verify Button
          _buildVerifyButton(theme),
          const SizedBox(height: 20),

          // Resend OTP
          _buildResendLink(theme, colorScheme),
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
              Icons.lock_clock,
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
          'Enter OTP Code',
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
        child: Column(
          children: [
            Text(
              'Enter the 6-digit code sent to',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                email,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOTPField(ColorScheme colorScheme) {
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
              controller: otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              hintText: '0 0 0 0 0 0',
              primaryColor: AppColors.secondaryOrange,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 12,
                color: colorScheme.onSurface,
              ),
              validator: otpValidator,
            ),
          ),
        );
      },
    );
  }

  Widget _buildVerifyButton(ThemeData theme) {
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
              label: 'Verify OTP',
              icon: Icons.verified_rounded,
              onPressed: onVerifyOTP,
              isLoading: isLoading,
              height: 64,
              gradient: AppColors.secondaryGradient,
            ),
          ),
        );
      },
    );
  }

  Widget _buildResendLink(ThemeData theme, ColorScheme colorScheme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Didn\'t receive the code? ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                TextButton(
                  onPressed: onResendOTP,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Resend',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondaryOrange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
