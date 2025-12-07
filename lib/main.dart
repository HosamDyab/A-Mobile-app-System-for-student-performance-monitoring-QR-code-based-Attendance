import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'Student/data/repo_imp/StudentRepositoryImpl.dart';
import 'Student/data/repo_imp/attendance_repository_impl.dart';
import 'Student/data/repo_imp/searchFeature/StudentRepositoryImpl.dart';
import 'Student/presentaion/blocs/DashboardCubit/DashboardCubit.dart';
import 'Student/presentaion/blocs/SearchCuit.dart';
import 'Student/presentaion/blocs/attendace_bloc/attendance_cubit.dart';
import 'Student/presentaion/blocs/gpa cubit.dart';
import 'Student/presentaion/blocs/profile_cubit/profile_cubit.dart';

// Teacher imports
import 'Teacher/viewmodels/live_attendance/live_attendance_cubit.dart';
import 'Teacher/services/repositories/live_attendance_repository_impl.dart';
import 'Teacher/services/datasources/live_attendance_remote_source.dart';
import 'Teacher/services/datasources/supabase/attendance_datasource.dart';
import 'Teacher/services/datasources/supabase/grade_datasource.dart';
import 'Teacher/services/datasources/supabase/student_datasource.dart';
import 'Teacher/services/repositories/attendance_repository.dart';
import 'Teacher/services/repositories/grade_repository.dart';
import 'Teacher/services/repositories/student_repository.dart';
import 'Teacher/services/usecases/generate_qr_code_usecase.dart';
import 'Teacher/services/usecases/get_students_usecase.dart';
import 'Teacher/services/usecases/mark_attendance_usecase.dart';
import 'Teacher/services/usecases/submit_grades_usecase.dart';
import 'Teacher/viewmodels/attendance/attendance_bloc.dart';
import 'Teacher/viewmodels/grade_entry/grade_entry_cubit.dart';
import 'Teacher/viewmodels/students/students_bloc.dart';
import 'Teacher/viewmodels/dashboard/teacher_dashboard_cubit.dart';
import 'Teacher/services/repositories/faculty_repository.dart';
import 'Teacher/services/datasources/supabase/faculty_datasource.dart';
import 'Teacher/services/datasources/supabase/teacher_assistant_datasource.dart';
import 'Teacher/services/datasources/supabase/attendance_history_datasource.dart';
import 'Teacher/viewmodels/teacher_assistant/teacher_assistant_cubit.dart';
import 'Teacher/viewmodels/attendance_history/attendance_history_cubit.dart';

import 'auth/screens/auth_wrapper.dart';
import 'helpers/supabase_remote_data_source.dart';
import 'shared/navigation/app_router.dart';
import 'shared/theme/app_theme.dart';
import 'shared/theme/app_theme_dark.dart';
import 'shared/theme/theme_manager.dart';
import 'ustils/supabase_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseManager.init();

  // Initialize GPA DB (if needed)
  // await LocalDb.initializeDatabaseFactory();

  final supabase = SupabaseRemoteDataSource();

  final attendanceRepo = AttendanceRepositoryImpl(supabase);
  final studentRepo = StudentRepositoryImpl(supabase);
  final searchRepo = StudentRepositorySearchImpl(supabase);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeManager(),
      child: MultiBlocProvider(
        providers: [
          // Student BLoCs
          BlocProvider(create: (_) => AttendanceCubit(attendanceRepo)),
          BlocProvider(create: (_) => GpaCubit()),
          BlocProvider(
              create: (_) => StudentSearchCubit(repository: searchRepo)),
          BlocProvider(create: (_) => StudentProfileCubit(studentRepo)),
          BlocProvider(create: (_) => DashboardCubit(supabase)),

          // Teacher BLoCs - Provided globally
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
          BlocProvider<AttendanceBloc>(
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
          BlocProvider<StudentsBloc>(
            create: (context) => StudentsBloc(
              GetStudentsUseCase(StudentRepository(StudentDataSource())),
            ),
          ),
          BlocProvider<GradeEntryCubit>(
            create: (context) => GradeEntryCubit(
              SubmitGradesUseCase(GradeRepository(GradeDataSource())),
            ),
          ),
          BlocProvider<TeacherAssistantCubit>(
            create: (context) => TeacherAssistantCubit(
              TeacherAssistantDataSource(),
            ),
          ),
          BlocProvider<AttendanceHistoryCubit>(
            create: (context) => AttendanceHistoryCubit(
              AttendanceHistoryDataSource(),
            ),
          ),
        ],
        child: const ClassTrackApp(),
      ),
    ),
  );
}

class ClassTrackApp extends StatelessWidget {
  const ClassTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);

    return MaterialApp(
      title: 'ClassTrack',
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppRouter.onGenerateRoute,
      theme: AppTheme.light(),
      darkTheme: AppThemeDark.dark(),
      themeMode: themeManager.themeMode,
      home: const AuthWrapper(),
    );
  }
}
