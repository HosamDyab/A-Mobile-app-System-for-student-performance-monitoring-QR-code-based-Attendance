import '../ustils/supabase_manager.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;

class EmailService {
  final supabase = SupabaseManager.client;

  // Send OTP email using Supabase Edge Function or external email service
  Future<bool> sendOTPEmail({
    required String email,
    required String otp,
    required String userName,
  }) async {
    try {
      // Method 1: Using Supabase Edge Function (Recommended)
      // You need to create an edge function in your Supabase project
      final response = await supabase.functions.invoke(
        'send-otp-email',
        body: {
          'email': email,
          'otp': otp,
          'userName': userName,
        },
      );

      if (response.status == 200) {
        print('✅ OTP email sent successfully to $email');
        return true;
      } else {
        print('❌ Failed to send OTP email: ${response.status}');
        return false;
      }
    } catch (e) {
      print('❌ Error sending OTP email: $e');

      // Fallback: Try alternative method
      return await _sendEmailViaHTTP(email, otp, userName);
    }
  }

  // Alternative method using HTTP POST to a backend service
  Future<bool> _sendEmailViaHTTP(
      String email, String otp, String userName) async {
    try {
      // This is a fallback - you'll need to set up your own backend endpoint
      // or use a service like SendGrid, Mailgun, etc.

      // For now, we'll simulate success for development
      // In production, replace this with actual email service

      print('📧 Simulating email send to $email');
      print('   OTP: $otp');
      print('   User: $userName');

      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // In production, uncomment and configure this:
      /*
      final response = await http.post(
        Uri.parse('YOUR_EMAIL_SERVICE_ENDPOINT'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'to': email,
          'subject': 'Password Reset OTP - MTI ClassTrack',
          'html': _generateEmailHTML(otp, userName),
        }),
      );
      
      return response.statusCode == 200;
      */

      return true; // Change to false in production until configured
    } catch (e) {
      print('❌ HTTP email send failed: $e');
      return false;
    }
  }

  // Generate professional HTML email template
  String _generateEmailHTML(String otp, String userName) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Password Reset OTP</title>
</head>
<body style="margin: 0; padding: 0; font-family: Arial, sans-serif; background-color: #f4f4f4;">
    <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color: #f4f4f4; padding: 20px;">
        <tr>
            <td align="center">
                <table width="600" cellpadding="0" cellspacing="0" border="0" style="background-color: #ffffff; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
                    <!-- Header -->
                    <tr>
                        <td style="background-color: #D97A27; padding: 30px; text-align: center;">
                            <h1 style="margin: 0; color: #ffffff; font-size: 28px;">MTI ClassTrack</h1>
                            <p style="margin: 10px 0 0 0; color: #ffffff; font-size: 14px;">Student Performance Monitoring System</p>
                        </td>
                    </tr>
                    
                    <!-- Body -->
                    <tr>
                        <td style="padding: 40px 30px;">
                            <h2 style="margin: 0 0 20px 0; color: #333333; font-size: 24px;">Password Reset Request</h2>
                            
                            <p style="margin: 0 0 15px 0; color: #666666; font-size: 16px; line-height: 1.5;">
                                Hello <strong>$userName</strong>,
                            </p>
                            
                            <p style="margin: 0 0 25px 0; color: #666666; font-size: 16px; line-height: 1.5;">
                                We received a request to reset your password. Use the following One-Time Password (OTP) to complete the process:
                            </p>
                            
                            <!-- OTP Box -->
                            <table width="100%" cellpadding="0" cellspacing="0" border="0" style="margin: 25px 0;">
                                <tr>
                                    <td align="center" style="background-color: #f8f8f8; padding: 20px; border-radius: 8px; border: 2px dashed #D97A27;">
                                        <div style="font-size: 36px; font-weight: bold; color: #D97A27; letter-spacing: 8px; font-family: 'Courier New', monospace;">
                                            $otp
                                        </div>
                                    </td>
                                </tr>
                            </table>
                            
                            <p style="margin: 25px 0 15px 0; color: #666666; font-size: 16px; line-height: 1.5;">
                                This OTP will expire in <strong>10 minutes</strong> for security reasons.
                            </p>
                            
                            <p style="margin: 0 0 15px 0; color: #666666; font-size: 16px; line-height: 1.5;">
                                If you didn't request this password reset, please ignore this email or contact support if you have concerns.
                            </p>
                            
                            <!-- Warning Box -->
                            <table width="100%" cellpadding="0" cellspacing="0" border="0" style="margin: 25px 0;">
                                <tr>
                                    <td style="background-color: #fff3cd; padding: 15px; border-radius: 6px; border-left: 4px solid #ffc107;">
                                        <p style="margin: 0; color: #856404; font-size: 14px;">
                                            <strong>⚠️ Security Notice:</strong> Never share this OTP with anyone. MTI staff will never ask for your OTP.
                                        </p>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                    
                    <!-- Footer -->
                    <tr>
                        <td style="background-color: #f8f8f8; padding: 25px 30px; text-align: center; border-top: 1px solid #e0e0e0;">
                            <p style="margin: 0 0 10px 0; color: #999999; font-size: 14px;">
                                This is an automated message, please do not reply to this email.
                            </p>
                            <p style="margin: 0 0 10px 0; color: #999999; font-size: 14px;">
                                © 2025 Modern Technology Institute. All rights reserved.
                            </p>
                            <p style="margin: 0; color: #999999; font-size: 12px;">
                                <a href="https://mti.edu.eg" style="color: #D97A27; text-decoration: none;">www.mti.edu.eg</a>
                            </p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
    ''';
  }

  // Send password reset email using Supabase Auth (Alternative approach)
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'YOUR_APP_REDIRECT_URL', // Configure this in production
      );
      print('✅ Password reset email sent via Supabase Auth');
      return true;
    } catch (e) {
      print('❌ Supabase Auth reset email failed: $e');
      return false;
    }
  }
}
