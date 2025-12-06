import 'package:flutter/material.dart';

import '../../Student/presentaion/screens/StudentView.dart';
import '../../Teacher/TeacherView.dart';
import '../../services/auth_service.dart';
import '../../shared/utils/app_colors.dart';
import '../../shared/utils/page_transitions.dart';
import '../../ustils/supabase_manager.dart';

/// Handles user authentication flow for all roles (student, faculty, teaching assistant).
///
/// This service validates credentials against Supabase, checks role-specific
/// tables (Student, Faculty, TeacherAssistant), persists the session, and
/// navigates to the appropriate home screen.
class LoginHandler {
  /// Authenticates user credentials against Supabase and navigates to the
  /// appropriate screen based on role.
  ///
  /// Throws an [Exception] if authentication fails.
  static Future<void> handleLogin({
    required BuildContext context,
    required String email,
    required String password,
    required String role,
    required bool rememberMe,
    required Function(bool) setLoading,
  }) async {
    try {
      final supabase = SupabaseManager.client;

      print('🔐 Attempting login for: $email');

      // Fetch user from User table
      final userResponse = await supabase
          .from('User')
          .select('UserId, Email, PasswordHash, FullName, Role, IsActive')
          .eq('Email', email)
          .maybeSingle();

      if (userResponse == null) {
        throw Exception('Invalid email or password.');
      }

      print('✅ User found: ${userResponse['FullName']}');

      // Validate password
      final storedPasswordHash = userResponse['PasswordHash'];
      if (storedPasswordHash != password) {
        throw Exception('Invalid email or password.');
      }

      // Check if account is active
      if (userResponse['IsActive'] != true) {
        throw Exception('Your account is inactive. Please contact support.');
      }

      // Validate role
      final userRole = userResponse['Role'].toString().toLowerCase();
      _validateUserRole(role, userRole);

      final userId = userResponse['UserId'];

      // Authenticate and navigate based on role
      if (role == 'student') {
        await _handleStudentLogin(
          context: context,
          supabase: supabase,
          userId: userId,
          email: email,
          userName: userResponse['FullName'],
          rememberMe: rememberMe,
          setLoading: setLoading,
        );
      } else if (role == 'faculty') {
        await _handleFacultyLogin(
          context: context,
          supabase: supabase,
          userId: userId,
          email: email,
          userName: userResponse['FullName'],
          rememberMe: rememberMe,
          setLoading: setLoading,
        );
      } else if (role == 'teacher_assistant') {
        await _handleTeacherAssistantLogin(
          context: context,
          supabase: supabase,
          userId: userId,
          email: email,
          userName: userResponse['FullName'],
          rememberMe: rememberMe,
          setLoading: setLoading,
        );
      }
    } catch (e) {
      print('❌ Login error: $e');
      setLoading(false);
      rethrow;
    }
  }

  /// Validates that the user's role matches the expected role.
  static void _validateUserRole(String expectedRole, String actualRole) {
    if (expectedRole == 'student' && actualRole != 'student') {
      throw Exception('This email is not registered as a student.');
    } else if (expectedRole == 'faculty' && actualRole != 'faculty') {
      throw Exception('This email is not registered as faculty.');
    } else if (expectedRole == 'teacher_assistant' &&
        actualRole != 'teacherassistant') {
      throw Exception('This email is not registered as a teacher assistant.');
    }
  }

  /// Handles student-specific authentication and navigation.
  static Future<void> _handleStudentLogin({
    required BuildContext context,
    required dynamic supabase,
    required dynamic userId,
    required String email,
    required String userName,
    required bool rememberMe,
    required Function(bool) setLoading,
  }) async {
    final studentResponse = await supabase
        .from('Student')
        .select('StudentId, StudentCode')
        .eq('UserId', userId)
        .maybeSingle();

    if (studentResponse == null) {
      throw Exception('Student record not found.');
    }

    final studentId = studentResponse['StudentId'].toString();

    print('✅ Student authenticated: $userName (ID: $studentId)');

    await AuthService.saveLoginSession(
      email: email,
      role: 'student',
      userId: userId,
      userName: userName,
      studentId: studentId,
    );

    // Handle Remember Me
    if (rememberMe) {
      await AuthService.saveRememberedEmail(email: email, role: 'student');
    } else {
      await AuthService.clearRememberedEmail('student');
    }

    if (context.mounted) {
      setLoading(false);
      Navigator.pushReplacement(
        context,
        AdvancedSlidePageRoute(
          page: const StudentView(),
          direction: SlideDirection.left,
        ),
      );
    }
  }

  /// Handles faculty-specific authentication and navigation.
  static Future<void> _handleFacultyLogin({
    required BuildContext context,
    required dynamic supabase,
    required dynamic userId,
    required String email,
    required String userName,
    required bool rememberMe,
    required Function(bool) setLoading,
  }) async {
    final facultyResponse = await supabase
        .from('Faculty')
        .select('FacultyId, EmployeeCode, AcademicTitle')
        .eq('UserId', userId)
        .maybeSingle();

    if (facultyResponse == null) {
      throw Exception('Faculty record not found.');
    }

    final facultyId = facultyResponse['FacultyId'].toString();

    print('✅ Faculty authenticated: $userName (ID: $facultyId)');

    await AuthService.saveLoginSession(
      email: email,
      role: 'faculty',
      userId: userId,
      userName: userName,
      studentId: facultyId,
    );

    // Handle Remember Me
    if (rememberMe) {
      await AuthService.saveRememberedEmail(email: email, role: 'faculty');
    } else {
      await AuthService.clearRememberedEmail('faculty');
    }

    if (context.mounted) {
      setLoading(false);
      Navigator.pushReplacement(
        context,
        AdvancedSlidePageRoute(
          page: TeacherView(
            facultyName: userName,
            facultyEmail: email,
            facultyId: facultyId,
            role: 'faculty',
          ),
          direction: SlideDirection.left,
        ),
      );
    }
  }

  /// Handles teaching assistant-specific authentication and navigation.
  static Future<void> _handleTeacherAssistantLogin({
    required BuildContext context,
    required dynamic supabase,
    required dynamic userId,
    required String email,
    required String userName,
    required bool rememberMe,
    required Function(bool) setLoading,
  }) async {
    final taResponse = await supabase
        .from('TeacherAssistant')
        .select('TAId, EmployeeCode')
        .eq('UserId', userId)
        .maybeSingle();

    if (taResponse == null) {
      throw Exception('Teacher Assistant record not found.');
    }

    final taId = taResponse['TAId'].toString();

    print('✅ TA authenticated: $userName (ID: $taId)');

    await AuthService.saveLoginSession(
      email: email,
      role: 'teacher_assistant',
      userId: userId,
      userName: userName,
      studentId: taId,
    );

    // Handle Remember Me
    if (rememberMe) {
      await AuthService.saveRememberedEmail(
          email: email, role: 'teacher_assistant');
    } else {
      await AuthService.clearRememberedEmail('teacher_assistant');
    }

    if (context.mounted) {
      setLoading(false);
      Navigator.pushReplacement(
        context,
        AdvancedSlidePageRoute(
          page: TeacherView(
            facultyName: userName,
            facultyEmail: email,
            facultyId: taId,
            role: 'teacher_assistant',
          ),
          direction: SlideDirection.left,
        ),
      );
    }
  }

  /// Shows an error snackbar with retry action.
  static void showLoginError(
    BuildContext context,
    String errorMessage,
    VoidCallback onRetry,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                errorMessage.replaceAll('Exception: ', ''),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.accentRed,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: onRetry,
        ),
      ),
    );
  }
}
