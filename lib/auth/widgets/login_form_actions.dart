import 'package:flutter/material.dart';

import '../../shared/utils/app_colors.dart';
import '../../shared/widgets/modern_hover_button.dart';

/// Contains the Remember Me checkbox, Forgot Password link, and Login button.
///
/// All elements are animated and styled consistently.
class LoginFormActions extends StatelessWidget {
  final bool rememberMe;
  final Function(bool?) onRememberMeChanged;
  final VoidCallback onForgotPassword;
  final VoidCallback onLogin;
  final bool isLoading;
  final Animation<double> fieldAnimation;
  final String roleName;

  const LoginFormActions({
    super.key,
    required this.rememberMe,
    required this.onRememberMeChanged,
    required this.onForgotPassword,
    required this.onLogin,
    required this.isLoading,
    required this.fieldAnimation,
    required this.roleName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Remember Me Checkbox and Forgot Password Link
        AnimatedBuilder(
          animation: fieldAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - fieldAnimation.value)),
              child: Opacity(
                opacity: fieldAnimation.value,
                child: Row(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: rememberMe ? 1.0 : 0.0,
                        end: rememberMe ? 1.0 : 0.0,
                      ),
                      duration: const Duration(milliseconds: 200),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.9 + (0.1 * value),
                          child: Checkbox(
                            value: rememberMe,
                            onChanged: onRememberMeChanged,
                            activeColor: AppColors.primaryBlue,
                            checkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => onRememberMeChanged(!rememberMe),
                      child: Text(
                        'Remember Me',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.tertiaryBlack,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: onForgotPassword,
                      icon: Icon(
                        Icons.lock_reset_rounded,
                        size: 16,
                        color: AppColors.primaryBlue,
                      ),
                      label: Text(
                        'Forgot Password?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 36),

        // Animated Login Button with Modern Hover Effect
        AnimatedBuilder(
          animation: fieldAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - fieldAnimation.value)),
              child: Opacity(
                opacity: fieldAnimation.value,
                child: ModernHoverButton(
                  label: 'Log In',
                  icon: Icons.login_rounded,
                  onPressed: onLogin,
                  isLoading: isLoading,
                  height: 68,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
