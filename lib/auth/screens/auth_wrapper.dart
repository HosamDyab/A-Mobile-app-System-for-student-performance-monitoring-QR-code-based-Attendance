import 'package:flutter/material.dart';

import '../../Student/presentaion/screens/StudentView.dart';
import '../../Teacher/TeacherView.dart';
import '../../services/auth_service.dart';
import '../../shared/utils/app_colors.dart';
import 'welcome_screen.dart';

/// Decides which first screen to show based on authentication state and role.
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


