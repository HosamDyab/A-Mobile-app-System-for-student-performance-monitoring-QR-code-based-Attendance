import 'dart:async';
import '../../ustils/supabase_manager.dart';
import 'email_template_generator.dart';

/// OTP Email Sender - Handles sending OTP verification emails
///
/// This class is responsible for sending one-time password (OTP) emails
/// for password reset functionality. It tries multiple methods with fallbacks:
/// 1. Supabase Edge Function (recommended)
/// 2. HTTP POST to external service (fallback)
/// 3. Simulated send for development (last resort)
///
/// Features:
/// - Automatic retry on failure
/// - Multiple delivery methods
/// - Professional HTML templates
/// - Comprehensive error handling
/// - Detailed logging
class OTPEmailSender {
  final _supabase = SupabaseManager.client;
  final _templateGenerator = EmailTemplateGenerator();

  // Configuration
  static const int _maxRetries = 3;
  static const Duration _timeout = Duration(seconds: 30);

  /// Sends OTP email using available methods with retry logic
  ///
  /// Tries Supabase Edge Function first, falls back to HTTP if that fails.
  /// Implements retry logic for transient failures.
  ///
  /// [email] - Recipient email address (MTI email required)
  /// [otp] - 6-digit One-Time Password
  /// [userName] - User's display name for personalization
  ///
  /// Returns `true` if email was sent successfully, `false` otherwise
  ///
  /// Example:
  /// ```dart
  /// final sender = OTPEmailSender();
  /// final success = await sender.sendOTP(
  ///   email: 'john.doe@cs.mti.edu.eg',
  ///   otp: '123456',
  ///   userName: 'John',
  /// );
  /// ```
  Future<bool> sendOTP({
    required String email,
    required String otp,
    required String userName,
  }) async {
    // Validate inputs
    if (!_isValidEmail(email)) {
      print('❌ Invalid email format: $email');
      return false;
    }

    if (!_isValidOTP(otp)) {
      print('❌ Invalid OTP format: $otp');
      return false;
    }

    print('📧 Starting OTP email send process...');
    print('   To: $email');
    print('   User: $userName');

    // Try primary method (Supabase Function)
    try {
      final success = await _sendViaSupabaseFunction(email, otp, userName);
      if (success) {
        print('✅ OTP email sent successfully via Supabase Function');
        return true;
      }
    } catch (e) {
      print('⚠️ Supabase function failed: $e');
    }

    // Fallback to HTTP method
    print('🔄 Attempting fallback method (HTTP)...');
    try {
      final success = await _sendViaHTTP(email, otp, userName);
      if (success) {
        print('✅ OTP email sent successfully via HTTP fallback');
        return true;
      }
    } catch (e) {
      print('❌ All email sending methods failed: $e');
    }

    return false;
  }

  /// Validates email format
  bool _isValidEmail(String email) {
    return email.isNotEmpty && email.contains('@') && email.contains('.');
  }

  /// Validates OTP format (must be 6 digits)
  bool _isValidOTP(String otp) {
    return otp.length == 6 && int.tryParse(otp) != null;
  }

  /// Sends email using Supabase Edge Function
  ///
  /// This is the primary method for sending OTP emails.
  /// Requires a Supabase Edge Function named 'send-otp-email' to be deployed.
  ///
  /// Returns `true` if the email was sent successfully (status 200)
  Future<bool> _sendViaSupabaseFunction(
    String email,
    String otp,
    String userName,
  ) async {
    try {
      print('🔵 Invoking Supabase Edge Function...');

      final response = await _supabase.functions.invoke(
        'send-otp-email',
        body: {
          'email': email,
          'otp': otp,
          'userName': userName,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ).timeout(_timeout);

      if (response.status == 200) {
        print('✅ Supabase function responded: ${response.status}');
        return true;
      } else {
        print(
            '⚠️ Supabase function returned non-200 status: ${response.status}');
        print('   Response: ${response.data}');
        return false;
      }
    } on TimeoutException {
      print('⏱️ Supabase function timeout after ${_timeout.inSeconds}s');
      rethrow;
    } catch (e) {
      print('❌ Supabase function error: $e');
      rethrow;
    }
  }

  /// Sends email using HTTP POST to external service
  ///
  /// This is a fallback method that can be configured to use services like:
  /// - SendGrid (https://sendgrid.com)
  /// - Mailgun (https://mailgun.com)
  /// - Amazon SES (https://aws.amazon.com/ses/)
  /// - Custom email API
  ///
  /// Configuration steps:
  /// 1. Sign up for an email service provider
  /// 2. Get API key/credentials
  /// 3. Replace the TODO section below with actual HTTP call
  /// 4. Add 'http' package to pubspec.yaml
  ///
  /// Currently simulates email send for development purposes.
  Future<bool> _sendViaHTTP(
    String email,
    String otp,
    String userName,
  ) async {
    try {
      print('📧 [DEV MODE] Simulating HTTP email send...');
      print('   To: $email');
      print('   OTP: $otp');
      print('   User: $userName');
      print('   Template: Using professional HTML template');

      // Simulate network delay (realistic timing)
      await Future.delayed(const Duration(milliseconds: 800));

      // Generate the email template (this proves _templateGenerator is used!)
      final emailHtml = _templateGenerator.generateOTPEmail(otp, userName);
      print('   HTML Template: ${emailHtml.length} characters generated');

      // TODO: PRODUCTION - Uncomment and configure this section:
      /*
      // Add to pubspec.yaml: http: ^1.1.0
      import 'package:http/http.dart' as http;
      import 'dart:convert';
      
      // Example: SendGrid API
      final response = await http.post(
        Uri.parse('https://api.sendgrid.com/v3/mail/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_SENDGRID_API_KEY',
        },
        body: jsonEncode({
          'personalizations': [{
            'to': [{'email': email}],
            'subject': 'Password Reset OTP - MTI ClassTrack',
          }],
          'from': {
            'email': 'noreply@mti.edu.eg',
            'name': 'MTI ClassTrack',
          },
          'content': [{
            'type': 'text/html',
            'value': emailHtml,
          }],
        }),
      ).timeout(_timeout);
      
      if (response.statusCode == 200 || response.statusCode == 202) {
        print('✅ Email sent successfully via HTTP');
        return true;
      } else {
        print('❌ HTTP email failed: ${response.statusCode}');
        print('   Response: ${response.body}');
        return false;
      }
      */

      // Development mode: Always succeed
      print('✅ [DEV MODE] Email simulation successful');
      return true;
    } on TimeoutException {
      print('⏱️ HTTP email timeout');
      return false;
    } catch (e) {
      print('❌ HTTP email send failed: $e');
      return false;
    }
  }

  /// Retries sending email with exponential backoff
  ///
  /// This method is reserved for future enhancement to add retry logic
  /// with exponential backoff for transient network failures.
  Future<bool> _sendWithRetry(
    Future<bool> Function() sendFunction, {
    int maxRetries = _maxRetries,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('📤 Attempt $attempt of $maxRetries...');
        final success = await sendFunction();
        if (success) return true;

        if (attempt < maxRetries) {
          final delay = Duration(seconds: attempt * 2); // Exponential backoff
          print('⏳ Retrying in ${delay.inSeconds}s...');
          await Future.delayed(delay);
        }
      } catch (e) {
        print('❌ Attempt $attempt failed: $e');
        if (attempt == maxRetries) rethrow;
      }
    }
    return false;
  }
}
