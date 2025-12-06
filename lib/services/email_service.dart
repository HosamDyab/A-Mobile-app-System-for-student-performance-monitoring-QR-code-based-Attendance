/// Email Service Module
///
/// ⚠️ DEPRECATED: This file is kept for backward compatibility only.
/// Please use the new email service structure from services/email/ folder.
///
/// The Email Service has been refactored into multiple clean files:
/// - email/email_service.dart - Main service interface
/// - email/otp_email_sender.dart - OTP email functionality
/// - email/email_sender.dart - General email sending
/// - email/email_template_generator.dart - HTML templates
///
/// This improves:
/// - Code organization and single responsibility
/// - Testability (easier to mock individual components)
/// - Maintainability (easier to find and fix issues)
/// - Reusability (templates can be used independently)
library;

export 'email/email_service.dart';
export 'email/otp_email_sender.dart';
export 'email/email_sender.dart';
export 'email/email_template_generator.dart';
