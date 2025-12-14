import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Teacher/shared/constants/app_color.dart';
import '../../services/email/email_service.dart';
import '../../shared/widgets/hover_scale_widget.dart';
import '../../ustils/supabase_manager.dart';
import '../utils/otp_generator.dart';

class PasswordResetHandler {
  final EmailService _emailService = EmailService();
  String _generatedOTP = '';
  String _userEmail = '';
  String _userId = '';
  String _userType = '';

  /// Sends OTP to the user's email address.
  /// [emailOrId] can be either email or user ID
  /// [userType] should be 'student', 'faculty', or 'ta'
  Future<bool> sendOTP(String emailOrId, String userType) async {
    final supabase = SupabaseManager.client;

    // Determine if input is email or ID
    final bool isEmail = emailOrId.contains('@');

    String userId = '';
    String userEmail = '';
    String userName = '';

    try {
      if (userType == 'student') {
        final query = isEmail
            ? supabase.from('student').select('studentid, email, fullname').eq('email', emailOrId)
            : supabase.from('student').select('studentid, email, fullname').eq('studentid', emailOrId);

        final student = await query.maybeSingle();
        if (student == null) throw Exception('Student not found');

        userId = student['studentid'];
        userEmail = student['email'];
        userName = student['fullname'];

      } else if (userType == 'faculty') {
        final query = isEmail
            ? supabase.from('faculty').select('facultysnn, email, fullname').eq('email', emailOrId)
            : supabase.from('faculty').select('facultysnn, email, fullname').eq('facultysnn', emailOrId);

        final faculty = await query.maybeSingle();
        if (faculty == null) throw Exception('Faculty not found');

        userId = faculty['facultysnn'];
        userEmail = faculty['email'];
        userName = faculty['fullname'];

      } else if (userType == 'ta') {
        final query = isEmail
            ? supabase.from('ta').select('tasnn, email, fullname').eq('email', emailOrId)
            : supabase.from('ta').select('tasnn, email, fullname').eq('tasnn', emailOrId);

        final ta = await query.maybeSingle();
        if (ta == null) throw Exception('TA not found');

        userId = ta['tasnn'];
        userEmail = ta['email'];
        userName = ta['fullname'];
      }

      _userId = userId;
      _userEmail = userEmail;
      _userType = userType;
      _generatedOTP = OTPGenerator.generate();

      // Extract first name for personalization
      final firstName = userName.split(' ')[0];
      final capitalizedName = firstName[0].toUpperCase() + firstName.substring(1);

      return await _emailService.sendOTPEmail(
        email: userEmail,
        otp: _generatedOTP,
        userName: capitalizedName,
      );
    } catch (e) {
      print('❌ Error sending OTP: $e');
      return false;
    }
  }

  /// Verifies the OTP entered by the user.
  bool verifyOTP(String enteredOTP) {
    return enteredOTP.trim() == _generatedOTP;
  }

  /// Resets the user's password in the database.
  Future<void> resetPassword(String newPassword) async {
    final supabase = SupabaseManager.client;

    await supabase
        .from('user_credentials')
        .update({'hashed_password': newPassword})
        .eq('user_id', _userId)
        .eq('user_type', _userType);

    print('✅ Password updated successfully for: $_userEmail (ID: $_userId)');
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
                    colors: [Colors.green, const Color(0xFF059669)],
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
                   borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
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