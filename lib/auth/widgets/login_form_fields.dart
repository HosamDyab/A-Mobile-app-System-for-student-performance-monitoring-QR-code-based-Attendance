import 'package:flutter/material.dart';

import '../../shared/utils/app_colors.dart';
import '../../shared/widgets/animated_text_field.dart';

/// Contains the email and password input fields for the login form.
///
/// Both fields are animated and include validation logic.
class LoginFormFields extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isPasswordVisible;
  final VoidCallback onTogglePasswordVisibility;
  final Animation<double> fieldAnimation;
  final String? Function(String?)? emailValidator;
  final String? Function(String?)? passwordValidator;

  const LoginFormFields({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.isPasswordVisible,
    required this.onTogglePasswordVisibility,
    required this.fieldAnimation,
    this.emailValidator,
    this.passwordValidator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Animated Email Field
        AnimatedBuilder(
          animation: fieldAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - fieldAnimation.value)),
              child: Opacity(
                opacity: fieldAnimation.value,
                child: AnimatedTextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  hintText: 'Enter your MTI email',
                  prefixIcon: Icons.email_outlined,
                  primaryColor: AppColors.primaryBlue,
                  validator: emailValidator,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 22),

        // Animated Password Field
        AnimatedBuilder(
          animation: fieldAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - fieldAnimation.value)),
              child: Opacity(
                opacity: fieldAnimation.value,
                child: AnimatedTextField(
                  controller: passwordController,
                  obscureText: !isPasswordVisible,
                  hintText: 'Enter your password',
                  prefixIcon: Icons.lock_outline,
                  primaryColor: AppColors.secondaryOrange,
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: AppColors.tertiaryLightGray,
                    ),
                    onPressed: onTogglePasswordVisibility,
                  ),
                  validator: passwordValidator,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
