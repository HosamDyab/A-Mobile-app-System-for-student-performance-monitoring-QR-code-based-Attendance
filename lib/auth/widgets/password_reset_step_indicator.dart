import 'package:flutter/material.dart';

import '../../shared/utils/app_colors.dart';

/// Visual indicator showing the current step in the password reset flow.
///
/// Displays 3 steps: Email → OTP → New Password
class PasswordResetStepIndicator extends StatelessWidget {
  final int currentStep;
  final AnimationController controller;

  const PasswordResetStepIndicator({
    super.key,
    required this.currentStep,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStepCircle(context, 1, currentStep >= 0, currentStep > 0),
            _buildStepLine(context, currentStep > 0),
            _buildStepCircle(context, 2, currentStep >= 1, currentStep > 1),
            _buildStepLine(context, currentStep > 1),
            _buildStepCircle(context, 3, currentStep >= 2, false),
          ],
        );
      },
    );
  }

  Widget _buildStepCircle(
    BuildContext context,
    int step,
    bool isActive,
    bool isCompleted,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: isActive ? 48 : 44,
      height: isActive ? 48 : 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isCompleted
            ? LinearGradient(
                colors: [AppColors.accentGreen, const Color(0xFF059669)],
              )
            : isActive
                ? AppColors.primaryGradient
                : null,
        color: isActive || isCompleted
            ? null
            : colorScheme.onSurface.withOpacity(0.1),
        border: Border.all(
          color: isCompleted
              ? AppColors.accentGreen
              : colorScheme.primary.withOpacity(0.3),
          width: isCompleted ? 0 : 2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isCompleted
              ? Icon(
                  Icons.check_rounded,
                  key: const ValueKey('check'),
                  color: Colors.white,
                  size: 24,
                )
              : Text(
                  '$step',
                  key: ValueKey('step$step'),
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: isActive ? 18 : 16,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStepLine(BuildContext context, bool isCompleted) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      width: 60,
      height: 3,
      decoration: BoxDecoration(
        gradient: isCompleted
            ? LinearGradient(
                colors: [AppColors.accentGreen, const Color(0xFF059669)],
              )
            : null,
        color:
            isCompleted ? null : theme.colorScheme.onSurface.withOpacity(0.1),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
