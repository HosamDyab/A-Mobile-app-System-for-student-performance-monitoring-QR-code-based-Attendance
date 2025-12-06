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
          BlocProvider(create: (_) => AttendanceCubit(attendanceRepo)),
          BlocProvider(create: (_) => GpaCubit()),
          BlocProvider(create: (_) => StudentSearchCubit(repository: searchRepo)),
          BlocProvider(create: (_) => StudentProfileCubit(studentRepo)),
          BlocProvider(create: (_) => DashboardCubit(supabase)),
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
