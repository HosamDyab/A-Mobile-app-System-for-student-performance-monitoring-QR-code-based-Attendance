import 'package:flutter/material.dart';

import '../views/dashboard/teacher_dashboard_screen.dart';
import '../views/manual_attendance/manual_attendance_screen.dart';
import '../views/manual_grades/manual_grade_entry_screen.dart';
import '../views/students_list/students_list_screen.dart';
import '../views/widgets/bottom_nav_bar.dart';
import 'teacher_profile_screen.dart';

/// Teacher Portal Main Screen - Home screen with bottom navigation
///
/// This screen manages the bottom navigation and displays different screens
/// based on the selected tab. Works for both Faculty and Teacher Assistants.
///
/// Navigation tabs:
/// 1. Dashboard - Overview and quick actions
/// 2. Attendance - Manual attendance entry
/// 3. Grades - Grade entry for students
/// 4. Students - View and manage students
/// 5. Profile - User profile and settings
class TeacherMainScreen extends StatefulWidget {
  final String facultyName;
  final String facultyEmail;
  final String facultyId;
  final String role; // 'faculty' or 'teacher_assistant'

  const TeacherMainScreen({
    super.key,
    required this.facultyName,
    required this.facultyEmail,
    required this.facultyId,
    required this.role,
  });

  @override
  State<TeacherMainScreen> createState() => _TeacherMainScreenState();
}

class _TeacherMainScreenState extends State<TeacherMainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentScreen(context),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        role: widget.role,
        onTap: (index) {
          if (index != _currentIndex) {
            setState(() => _currentIndex = index);
          }
        },
      ),
    );
  }

  /// Builds the current screen based on selected index
  Widget _buildCurrentScreen(BuildContext context) {
    switch (_currentIndex) {
      case 0:
        // Dashboard - shows today's lectures/sections
        return TeacherDashboardScreen(
          facultyName: widget.facultyName,
          facultyId: widget.facultyId,
          role: widget.role,
        );
      case 1:
        // Manual Attendance - works for both Faculty and TA
        return ManualAttendanceScreen(
          facultyId: widget.facultyId,
          role: widget.role,
        );
      case 2:
        // Grade Entry - works for both Faculty and TA
        return ManualGradeEntryScreen(
          facultyId: widget.facultyId,
          role: widget.role,
        );
      case 3:
        // Students List - BLoCs are available from MultiBlocProvider via Builder
        return StudentsListScreen(
          facultyId: widget.facultyId,
          role: widget.role,
        );
      case 4:
        // Profile - BLoCs are available from MultiBlocProvider via Builder
        return TeacherProfileScreen(
          facultyName: widget.facultyName,
          facultyEmail: widget.facultyEmail,
          role: widget.role,
          facultyId: widget.facultyId,
        );
      default:
        return TeacherDashboardScreen(
          facultyName: widget.facultyName,
          facultyId: widget.facultyId,
          role: widget.role,
        );
    }
  }
}
