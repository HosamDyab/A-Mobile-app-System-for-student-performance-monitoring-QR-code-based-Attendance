import 'dart:math';

/// Generates random OTP (One-Time Password) codes.
///
/// Used during password reset flow to verify user identity.
class OTPGenerator {
  /// Generates a random 6-digit OTP code.
  ///
  /// Returns a string containing 6 digits (e.g., "123456").
  static String generate() {
    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString();
    return otp;
  }
}
