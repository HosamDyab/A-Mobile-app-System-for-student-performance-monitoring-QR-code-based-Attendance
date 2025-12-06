import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../viewmodels/live_attendance/live_attendance_cubit.dart';
import '../services/repositories/live_attendance_repository_impl.dart';
import '../services/datasources/live_attendance_remote_source.dart';
import '../services/datasources/supabase/attendance_datasource.dart';
import '../services/datasources/supabase/grade_datasource.dart';
import '../services/datasources/supabase/student_datasource.dart';
import '../services/repositories/attendance_repository.dart';
import '../services/repositories/grade_repository.dart';
import '../services/repositories/student_repository.dart';
import '../services/usecases/generate_qr_code_usecase.dart';
import '../services/usecases/get_students_usecase.dart';
import '../services/usecases/mark_attendance_usecase.dart';
import '../services/usecases/submit_grades_usecase.dart';
import '../viewmodels/attendance/attendance_bloc.dart';
import '../viewmodels/grade_entry/grade_entry_cubit.dart';
import '../viewmodels/students/students_bloc.dart';
import '../viewmodels/dashboard/teacher_dashboard_cubit.dart';
import '../services/repositories/faculty_repository.dart';
import '../services/datasources/supabase/faculty_datasource.dart';
import '../services/datasources/supabase/teacher_assistant_datasource.dart';
import '../services/datasources/supabase/attendance_history_datasource.dart';
import '../viewmodels/teacher_assistant/teacher_assistant_cubit.dart';
import '../viewmodels/attendance_history/attendance_history_cubit.dart';
import 'teacher_main_screen.dart';

/// Teacher Portal View Wrapper - Provides all necessary BLoC providers
///
/// This widget sets up the dependency injection and state management for the
/// entire teacher module. It creates and provides all necessary repositories,
/// use cases, and cubits/blocs.
///
/// Features:
/// - Clean separation of concerns
/// - Dependency injection at the root level
/// - Proper state management setup
/// - Easy to test and maintain
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
    return MultiBlocProvider(
      providers: _buildBlocProviders(),
      // Use Builder to ensure BLoCs are available before TeacherMainScreen is built
      child: Builder(
        builder: (context) => TeacherMainScreen(
          facultyName: facultyName,
          facultyEmail: facultyEmail,
          facultyId: facultyId,
          role: role,
        ),
      ),
    );
  }

  /// Builds all BLoC providers for the teacher module
  List<BlocProvider> _buildBlocProviders() {
    return [
      // Dashboard Cubit
      BlocProvider<TeacherDashboardCubit>(
        create: (context) => TeacherDashboardCubit(
          FacultyRepository(FacultyDataSource()),
        ),
      ),

      // Live Attendance Cubit
      BlocProvider<LiveAttendanceCubit>(
        create: (context) => LiveAttendanceCubit(
          LiveAttendanceRepositoryImpl(LiveAttendanceRemoteDataSource()),
        ),
      ),

      // Attendance Bloc
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

      // Students Bloc
      BlocProvider(
        create: (context) => StudentsBloc(
          GetStudentsUseCase(StudentRepository(StudentDataSource())),
        ),
      ),

      // Grade Entry Cubit
      BlocProvider(
        create: (context) => GradeEntryCubit(
          SubmitGradesUseCase(GradeRepository(GradeDataSource())),
        ),
      ),

      // Teacher Assistant Cubit
      BlocProvider(
        create: (context) => TeacherAssistantCubit(
          TeacherAssistantDataSource(),
        ),
      ),

      // Attendance History Cubit
      BlocProvider(
        create: (context) => AttendanceHistoryCubit(
          AttendanceHistoryDataSource(),
        ),
      ),
    ];
  }
}

