import 'email_sender.dart';
import 'otp_email_sender.dart';

/// Email Service - Main interface for sending emails
///
/// This service provides a clean API for sending various types of emails:
/// - OTP emails for password reset
/// - Password reset links (Supabase Auth)
/// - Welcome emails
/// - Notifications
///
/// Features:
/// - Multiple sending methods (Supabase Functions, HTTP, SMTP)
/// - Automatic fallback on failure
/// - Professional HTML templates
/// - Error handling and logging
class EmailService {
  final OTPEmailSender _otpEmailSender;
  final EmailSender _emailSender;

  EmailService()
      : _otpEmailSender = OTPEmailSender(),
        _emailSender = EmailSender();

  /// Sends an OTP email for password reset
  ///
  /// [email] - Recipient email address
  /// [otp] - One-time password code
  /// [userName] - User's display name
  ///
  /// Returns `true` if email was sent successfully, `false` otherwise
  Future<bool> sendOTPEmail({
    required String email,
    required String otp,
    required String userName,
  }) async {
    return await _otpEmailSender.sendOTP(
      email: email,
      otp: otp,
      userName: userName,
    );
  }

  /// Sends a password reset email using Supabase Auth
  ///
  /// [email] - Recipient email address
  ///
  /// Returns `true` if email was sent successfully, `false` otherwise
  Future<bool> sendPasswordResetEmail(String email) async {
    return await _emailSender.sendPasswordResetLink(email);
  }

  /// Sends a welcome email to new users (Future feature)
  ///
  /// [email] - Recipient email address
  /// [userName] - User's display name
  ///
  /// Returns `true` if email was sent successfully, `false` otherwise
  Future<bool> sendWelcomeEmail({
    required String email,
    required String userName,
  }) async {
    // TODO: Implement welcome email
    print('📧 Welcome email to: $email (Not implemented yet)');
    return true;
  }

  /// Sends a notification email (Future feature)
  ///
  /// [email] - Recipient email address
  /// [subject] - Email subject
  /// [body] - Email body content
  ///
  /// Returns `true` if email was sent successfully, `false` otherwise
  Future<bool> sendNotificationEmail({
    required String email,
    required String subject,
    required String body,
  }) async {
    // TODO: Implement notification email
    print('📧 Notification to: $email (Not implemented yet)');
    return true;
  }
}
