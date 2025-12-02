import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qra/Student/data/repo_imp/StudentRepositoryImpl.dart';
import 'Student/data/repo_imp/searchFeature/StudentRepositoryImpl.dart';
import 'Student/presentaion/blocs/DashboardCubit/DashboardCubit.dart';
import 'Student/presentaion/blocs/SearchCuit.dart';
import 'Student/presentaion/blocs/gpa cubit.dart';
import 'Student/presentaion/blocs/profile_cubit/profile_cubit.dart';
import 'auth/screens/welcome_screen.dart';
import 'helpers/supabase_remote_data_source.dart';
import 'shared/utils/page_transitions.dart';
import 'shared/utils/app_colors.dart';
import 'services/auth_service.dart';
import 'Student/presentaion/screens/StudentView.dart';
import 'Teacher/TeacherView.dart';

import 'Student/data/repo_imp/attendance_repository_impl.dart';
import 'Student/presentaion/blocs/attendace_bloc/attendance_cubit.dart';
import 'ustils/supabase_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseManager.init();

  final repository = AttendanceRepositoryImpl(SupabaseRemoteDataSource());
  final supabaseRemoteDataSource = SupabaseRemoteDataSource();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AttendanceCubit(repository)),
        BlocProvider(create: (_) => GpaCubit()),
        BlocProvider(
            create: (_) => StudentSearchCubit(
                StudentRepositorySearchImpl(SupabaseRemoteDataSource()),
                "100002")),
        BlocProvider(
            create: (_) => StudentProfileCubit(
                StudentRepositoryImpl(SupabaseRemoteDataSource()))),
        BlocProvider(create: (_) => DashboardCubit(supabaseRemoteDataSource)),
      ],
      child: MaterialApp(
        title: 'ClassTrack',
        debugShowCheckedModeBanner: false,
        // Custom page transitions
        onGenerateRoute: (settings) {
          // Default slide transition for all routes
          return SlidePageRoute(
            page: _getPageForRoute(settings.name ?? '/'),
            direction: SlideDirection.right,
          );
        },
        theme: ThemeData(
          useMaterial3: true,
          // Modern gradient color scheme: Blue primary, Orange secondary, Black tertiary
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryBlue, // Modern blue
            brightness: Brightness.light,
          ).copyWith(
            primary: AppColors.primaryBlue, // Modern blue
            secondary: AppColors.secondaryOrange, // Vibrant orange
            tertiary: AppColors.tertiaryBlack, // Black tertiary
            surface: AppColors.backgroundWhite,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onTertiary: Colors.white,
            onSurface: AppColors.tertiaryBlack,
            error: AppColors.accentRed,
            onError: Colors.white,
          ),
          // Soft, modern background with gradient support
          scaffoldBackgroundColor: AppColors.backgroundLight,
          // AppBar with modern styling
          appBarTheme: AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.transparent,
            foregroundColor: const Color(0xFF1F2937),
            surfaceTintColor: Colors.transparent,
            titleTextStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: Color(0xFF1F2937),
            ),
            iconTheme: const IconThemeData(
              color: AppColors.primaryBlue,
              size: 24,
            ),
          ),
          // Icon theme with modern color
          iconTheme: const IconThemeData(
            color: AppColors.primaryBlue,
            size: 24,
          ),
          // Floating action button with gradient support
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          // Modern card design with subtle shadows
          cardTheme: CardTheme(
            color: Colors.white,
            elevation: 0,
            shadowColor: Colors.black.withOpacity(0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          // Elevated button with modern styling and gradient support
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          // Outlined button theme with modern colors
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              side: const BorderSide(color: AppColors.primaryBlue, width: 2),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          // Text button theme with modern colors
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Modern input fields
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            prefixIconColor: const Color(0xFF6366F1),
            suffixIconColor: const Color(0xFF9CA3AF),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            hintStyle: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 15,
            ),
          ),
          // Modern typography
          textTheme: const TextTheme(
            displayLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
              letterSpacing: -0.5,
            ),
            displayMedium: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
              letterSpacing: -0.3,
            ),
            headlineLarge: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
              letterSpacing: -0.2,
            ),
            headlineMedium: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
            headlineSmall: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
            titleLarge: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
            titleMedium: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
            titleSmall: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF374151),
              height: 1.5,
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
            bodySmall: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF9CA3AF),
            ),
            labelLarge: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: Color(0xFF1F2937),
            ),
            labelMedium: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            labelSmall: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          // Bottom navigation with modern styling and gradient accents
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.backgroundWhite,
            selectedItemColor: AppColors.primaryBlue,
            unselectedItemColor: AppColors.tertiaryLightGray,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            showUnselectedLabels: true,
            elevation: 12,
          ),
          // Chip theme with modern colors and gradients
          chipTheme: ChipThemeData(
            backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
            selectedColor: AppColors.primaryBlue,
            labelStyle: const TextStyle(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        home: const AuthWrapper(),
      ),
    ),
  );
}

// Helper function to get page for route
Widget _getPageForRoute(String route) {
  // This is a fallback - actual navigation should use explicit routes
  return const WelcomeScreen();
}

// Auth wrapper to check login status on app startup
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  Map<String, String?> _userData = {};

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    if (isLoggedIn) {
      final userData = await AuthService.getLoginData();
      setState(() {
        _isLoggedIn = true;
        _userData = userData;
      });
    } else {
      setState(() {
        _isLoggedIn = false;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.animatedGradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBlue,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Loading...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.tertiaryBlack,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isLoggedIn) {
      final role = _userData['role'] ?? '';
      final userName = _userData['userName'] ?? '';
      final email = _userData['email'] ?? '';

      if (role == 'student') {
        return const StudentView();
      } else if (role == 'faculty' || role == 'teacher_assistant') {
        final facultyId = _userData['studentId'] ?? '';
        return TeacherView(
          facultyName: userName,
          facultyEmail: email,
          facultyId: facultyId,
          role: role,
        );
      }
    }

    return const WelcomeScreen();
  }
}

//
// class QRCodeApp extends StatelessWidget {
//   const QRCodeApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Student Monitoring & Attendance',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       debugShowCheckedModeBanner: false,
//       home: const HomePage(),
//     );
//   }
// }
//
