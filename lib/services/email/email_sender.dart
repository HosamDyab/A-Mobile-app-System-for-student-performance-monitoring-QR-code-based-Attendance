import '../../ustils/supabase_manager.dart';

/// Email Sender - General email sending functionality
///
/// Handles sending various types of emails through Supabase Auth
/// or other email services.
class EmailSender {
  final supabase = SupabaseManager.client;

  /// Sends password reset email using Supabase Auth
  ///
  /// This uses Supabase's built-in password reset functionality
  Future<bool> sendPasswordResetLink(String email) async {
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

  /// Sends a custom email (placeholder for future implementation)
  Future<bool> sendCustomEmail({
    required String to,
    required String subject,
    required String body,
  }) async {
    // TODO: Implement custom email sending
    print('📧 Custom email to: $to');
    print('   Subject: $subject');
    return true;
  }
}

