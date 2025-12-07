import 'package:flutter/material.dart';
import 'teacher_main_screen.dart';

/// Teacher Portal View Wrapper
///
/// Simple wrapper for the teacher module. All BLoC providers are now
/// set up globally in main.dart, so this just passes the teacher data
/// to the main screen.
///
/// Note: Previously, BLoCs were provided here, but this caused provider
/// scope issues when navigating between screens. Now all BLoCs are
/// provided at the app root level in main.dart for global accessibility
class TeacherViewWrapper extends StatelessWidget {
  final String facultyName;
  final String facultyEmail;
  final String facultyId;
  final String role; // 'faculty' or 'teacher_assistant'

  const TeacherViewWrapper({
    super.key,
    required this.facultyName,
    required this.facultyEmail,
    required this.facultyId,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    // BLoCs are now provided globally in main.dart
    // No need to provide them here anymore
    return TeacherMainScreen(
      facultyName: facultyName,
      facultyEmail: facultyEmail,
      facultyId: facultyId,
      role: role,
    );
  }
}
