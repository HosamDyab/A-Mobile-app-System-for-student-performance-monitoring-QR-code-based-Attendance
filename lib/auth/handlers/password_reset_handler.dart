import 'package:flutter/material.dart';

import '../../services/email_service.dart';
import '../../shared/utils/app_colors.dart';
import '../../shared/widgets/hover_scale_widget.dart';
import '../../ustils/supabase_manager.dart';
import '../utils/otp_generator.dart';

/// Handles the complete password reset flow.
///
/// Coordinates OTP generation, email sending, verification, and password updates.
class PasswordResetHandler {
  final EmailService _emailService = EmailService();
  String _generatedOTP = '';
  String _userEmail = '';

  /// Sends OTP to the user's email address.
  ///
  /// Returns `true` if email was sent successfully, `false` otherwise.
  Future<bool> sendOTP(String email) async {
    _userEmail = email;
    _generatedOTP = OTPGenerator.generate();

    final userName = email.split('@')[0].split('.')[0];
    final capitalizedName = userName[0].toUpperCase() + userName.substring(1);

    return await _emailService.sendOTPEmail(
      email: email,
      otp: _generatedOTP,
      userName: capitalizedName,
    );
  }

  /// Verifies the OTP entered by the user.
  ///
  /// Returns `true` if the OTP matches the generated one.
  bool verifyOTP(String enteredOTP) {
    return enteredOTP.trim() == _generatedOTP;
  }

  /// Resets the user's password in the database.
  ///
  /// Throws an exception if the update fails.
  Future<void> resetPassword(String newPassword) async {
    final supabase = SupabaseManager.client;

    await supabase
        .from('User')
        .update({'PasswordHash': newPassword}).eq('Email', _userEmail);

    print('✅ Password updated successfully for: $_userEmail');
  }

  /// Shows a success dialog after password reset.
  static void showSuccessDialog(BuildContext context, VoidCallback onDismiss) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => ScaleTransition(
        scale: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: ModalRoute.of(context)!.animation!,
            curve: Curves.easeOutCubic,
          ),
        ),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.accentGreen, const Color(0xFF059669)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Success!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          content: Text(
            'Your password has been reset successfully. You can now log in with your new password.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          actions: [
            HoverScaleWidget(
              onTap: onDismiss,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: onDismiss,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Go to Login'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a snackbar with the given message and color.
  static void showSnackBar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
