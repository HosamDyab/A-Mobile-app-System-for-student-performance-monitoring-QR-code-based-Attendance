import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../shared/utils/page_transitions.dart';
import 'package:qra/Teacher/viewmodels/live_attendance/live_attendance_cubit.dart';
import 'package:qra/Teacher/services/repositories/live_attendance_repository_impl.dart';
import 'package:qra/Teacher/services/datasources/live_attendance_remote_source.dart';
import 'package:qra/Teacher/services/datasources/supabase/attendance_datasource.dart';
import 'package:qra/Teacher/services/datasources/supabase/grade_datasource.dart';
import 'package:qra/Teacher/services/datasources/supabase/student_datasource.dart';
import 'package:qra/Teacher/services/repositories/attendance_repository.dart';
import 'package:qra/Teacher/services/repositories/grade_repository.dart';
import 'package:qra/Teacher/services/repositories/student_repository.dart';
import 'package:qra/Teacher/services/usecases/generate_qr_code_usecase.dart';
import 'package:qra/Teacher/services/usecases/get_students_usecase.dart';
import 'package:qra/Teacher/services/usecases/mark_attendance_usecase.dart';
import 'package:qra/Teacher/services/usecases/submit_grades_usecase.dart';
import 'package:qra/Teacher/viewmodels/attendance/attendance_bloc.dart';
import 'package:qra/Teacher/viewmodels/grade_entry/grade_entry_cubit.dart';
import 'package:qra/Teacher/viewmodels/students/students_bloc.dart';
import 'package:qra/Teacher/viewmodels/dashboard/teacher_dashboard_cubit.dart';
import 'package:qra/Teacher/services/repositories/faculty_repository.dart';
import 'package:qra/Teacher/services/datasources/supabase/faculty_datasource.dart';
import 'package:qra/Teacher/services/datasources/supabase/teacher_assistant_datasource.dart';
import 'package:qra/Teacher/services/datasources/supabase/attendance_history_datasource.dart';
import 'package:qra/Teacher/viewmodels/teacher_assistant/teacher_assistant_cubit.dart';
import 'package:qra/Teacher/viewmodels/attendance_history/attendance_history_cubit.dart';
import 'package:qra/Teacher/views/dashboard/teacher_dashboard_screen.dart';
import 'package:qra/Teacher/views/students_list/students_list_screen.dart';
import 'package:qra/Teacher/views/teacher_assistants/teacher_assistant_list_screen.dart';
import 'package:qra/Teacher/views/attendance_history/attendance_history_screen.dart';
import 'package:qra/Teacher/views/manual_attendance/manual_attendance_screen.dart';
import 'package:qra/Teacher/views/manual_grades/manual_grade_entry_screen.dart';
import 'package:qra/Teacher/views/widgets/bottom_nav_bar.dart';
import 'package:qra/services/auth_service.dart';
import 'package:qra/auth/screens/welcome_screen.dart';

/// Teacher Portal View - Main entry point for teachers/faculty
class TeacherView extends StatelessWidget {
  final String facultyName;
  final String facultyEmail;
  final String facultyId;
  final String role; // 'faculty' or 'teacher_assistant'

  const TeacherView({
    super.key,
    required this.facultyName,
    required this.facultyEmail,
    required this.facultyId,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TeacherDashboardCubit>(
          create: (context) => TeacherDashboardCubit(
            FacultyRepository(FacultyDataSource()),
          ),
        ),
        BlocProvider<LiveAttendanceCubit>(
          create: (context) => LiveAttendanceCubit(
            LiveAttendanceRepositoryImpl(LiveAttendanceRemoteDataSource()),
          ),
        ),
        BlocProvider(
          create: (context) => AttendanceBloc(
            generateQRCodeUseCase: GenerateQRCodeUseCase(
              AttendanceRepository(AttendanceDataSource()),
            ),
            markAttendanceUseCase: MarkAttendanceUseCase(
              AttendanceRepository(AttendanceDataSource()),
            ),
            getStudentsUseCase: GetStudentsUseCase(
              StudentRepository(StudentDataSource()),
            ),
          ),
        ),
        BlocProvider(
          create: (context) => StudentsBloc(
            GetStudentsUseCase(StudentRepository(StudentDataSource())),
          ),
        ),
        BlocProvider(
          create: (context) => GradeEntryCubit(
            SubmitGradesUseCase(GradeRepository(GradeDataSource())),
          ),
        ),
        BlocProvider(
          create: (context) => TeacherAssistantCubit(
            TeacherAssistantDataSource(),
          ),
        ),
        BlocProvider(
          create: (context) => AttendanceHistoryCubit(
            AttendanceHistoryDataSource(),
          ),
        ),
      ],
      child: TeacherViewBody(
        facultyName: facultyName,
        facultyEmail: facultyEmail,
        facultyId: facultyId,
        role: role,
      ),
    );
  }
}

/// Teacher Portal Body - Home screen with bottom navigation
class TeacherViewBody extends StatefulWidget {
  final String facultyName;
  final String facultyEmail;
  final String facultyId;
  final String role;

  const TeacherViewBody({
    super.key,
    required this.facultyName,
    required this.facultyEmail,
    required this.facultyId,
    required this.role,
  });

  @override
  State<TeacherViewBody> createState() => _TeacherViewBodyState();
}

class _TeacherViewBodyState extends State<TeacherViewBody> {
  int _currentIndex = 0;

  /// List of screens corresponding to bottom navigation items
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      TeacherDashboardScreen(
        facultyName: widget.facultyName,
        facultyId: widget.facultyId,
        role: widget.role,
      ),
      ManualAttendanceScreen(
        facultyId: widget.facultyId,
        role: widget.role,
      ),
      // Attendance History Screen
      AttendanceHistoryScreen(
        facultyId: widget.facultyId,
      ),
      const StudentsListScreen(),
      TeacherProfileScreen(
        facultyName: widget.facultyName,
        facultyEmail: widget.facultyEmail,
        role: widget.role,
        facultyId: widget.facultyId,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index != _currentIndex) {
            setState(() {
              _currentIndex = index;
            });
          }
        },
      ),
    );
  }
}

/// Teacher Profile Screen
class TeacherProfileScreen extends StatelessWidget {
  final String facultyName;
  final String facultyEmail;
  final String role;
  final String facultyId;

  const TeacherProfileScreen({
    super.key,
    required this.facultyName,
    required this.facultyEmail,
    required this.role,
    required this.facultyId,
  });

  Future<void> _handleLogout(BuildContext context) async {
    await AuthService.clearLoginSession();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        FadePageRoute(page: const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _handleLogout(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'tas') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<TeacherAssistantCubit>(),
                      child: TeacherAssistantListScreen(
                        facultyId: role == 'faculty' ? facultyId : null,
                      ),
                    ),
                  ),
                );
              } else if (value == 'manual_attendance') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ManualAttendanceScreen(
                      facultyId: facultyId,
                      role: role,
                    ),
                  ),
                );
              } else if (value == 'manual_grades') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ManualGradeEntryScreen(
                      facultyId: facultyId,
                      role: role,
                    ),
                  ),
                );
              } else if (value == 'logout') {
                _showLogoutDialog(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'manual_attendance',
                child: Row(
                  children: [
                    Icon(Icons.edit_note, size: 20, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text('Manual Attendance'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'manual_grades',
                child: Row(
                  children: [
                    Icon(Icons.grade, size: 20, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text('Manual Grade Entry'),
                  ],
                ),
              ),
              const PopupMenuItem(
                enabled: false,
                child: Divider(),
              ),
              if (role == 'faculty')
                const PopupMenuItem(
                  value: 'tas',
                  child: Row(
                    children: [
                      Icon(Icons.supervisor_account, size: 20),
                      SizedBox(width: 8),
                      Text('My Teacher Assistants'),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: colorScheme.error),
                    const SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: colorScheme.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: colorScheme.primary,
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                facultyName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                facultyEmail,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              Chip(
                label: Text(role == 'faculty' ? 'Faculty' : 'Teacher Assistant'),
                backgroundColor: colorScheme.primary,
                labelStyle: const TextStyle(color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
