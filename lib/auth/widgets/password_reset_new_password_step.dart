import 'package:flutter/material.dart';

import '../../shared/utils/app_colors.dart';
import '../../shared/widgets/animated_text_field.dart';
import '../../shared/widgets/modern_hover_button.dart';

/// Third step of password reset: Set new password.
///
/// Displays new password and confirm password fields with visibility toggles.
class PasswordResetNewPasswordStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final Animation<double> fadeAnimation;
  final AnimationController animationController;
  final bool isNewPasswordVisible;
  final bool isConfirmPasswordVisible;
  final VoidCallback onToggleNewPasswordVisibility;
  final VoidCallback onToggleConfirmPasswordVisibility;
  final bool isLoading;
  final VoidCallback onResetPassword;
  final String? Function(String?)? newPasswordValidator;
  final String? Function(String?)? confirmPasswordValidator;

  const PasswordResetNewPasswordStep({
    super.key,
    required this.formKey,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.fadeAnimation,
    required this.animationController,
    required this.isNewPasswordVisible,
    required this.isConfirmPasswordVisible,
    required this.onToggleNewPasswordVisibility,
    required this.onToggleConfirmPasswordVisibility,
    required this.isLoading,
    required this.onResetPassword,
    this.newPasswordValidator,
    this.confirmPasswordValidator,
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

          // New Password Field
          _buildNewPasswordField(),
          const SizedBox(height: 20),

          // Confirm Password Field
          _buildConfirmPasswordField(),
          const SizedBox(height: 36),

          // Reset Button
          _buildResetButton(theme),
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
              Icons.lock_reset,
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
          'Set New Password',
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
          'Create a strong password for your account',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildNewPasswordField() {
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
              controller: newPasswordController,
              obscureText: !isNewPasswordVisible,
              labelText: 'New Password',
              hintText: 'Enter new password',
              prefixIcon: Icons.lock_outline,
              primaryColor: AppColors.primaryBlue,
              suffixIcon: IconButton(
                icon: Icon(
                  isNewPasswordVisible
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: AppColors.tertiaryLightGray,
                ),
                onPressed: onToggleNewPasswordVisibility,
              ),
              validator: newPasswordValidator,
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: AnimatedTextField(
              controller: confirmPasswordController,
              obscureText: !isConfirmPasswordVisible,
              labelText: 'Confirm Password',
              hintText: 'Re-enter new password',
              prefixIcon: Icons.lock_outline,
              primaryColor: AppColors.secondaryOrange,
              suffixIcon: IconButton(
                icon: Icon(
                  isConfirmPasswordVisible
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: AppColors.tertiaryLightGray,
                ),
                onPressed: onToggleConfirmPasswordVisibility,
              ),
              validator: confirmPasswordValidator,
            ),
          ),
        );
      },
    );
  }

  Widget _buildResetButton(ThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: ModernHoverButton(
              label: 'Reset Password',
              icon: Icons.check_circle_outline_rounded,
              onPressed: onResetPassword,
              isLoading: isLoading,
              height: 64,
              gradient: AppColors.secondaryGradient,
            ),
          ),
        );
      },
    );
  }
}
