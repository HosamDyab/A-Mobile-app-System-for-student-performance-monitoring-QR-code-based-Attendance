import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../QRCode/presentaion/pages/view_attendance.dart';
import '../blocs/DashboardCubit/DashboardCubit.dart';
import 'GpaCalcView.dart';
import 'ProfilePage.dart';
import 'QR_scan_page.dart';
import 'StudentSearchPage.dart';
import 'dashboard_page.dart';
import 'faculty_search_page.dart';
import '../../../shared/utils/page_transitions.dart';
import '../../../services/auth_service.dart';
import '../../../auth/screens/welcome_screen.dart';
import '../../../shared/utils/student_utils.dart';

class StudentViewBody extends StatefulWidget {
  const StudentViewBody({super.key});

  @override
  State<StudentViewBody> createState() => _StudentViewBodyState();
}

class _StudentViewBodyState extends State<StudentViewBody> {
  String? studentId;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    try {
      final loginData = await AuthService.getLoginData();
      final email = loginData['email'] ?? '';
      final savedStudentId = loginData['studentId'];

      // Get student ID from email or saved data
      if (savedStudentId != null && savedStudentId.isNotEmpty) {
        studentId = savedStudentId;
      } else if (email.isNotEmpty) {
        studentId = StudentUtils.getStudentIdFromEmail(email);
      }

      if (studentId != null && studentId!.isNotEmpty && mounted) {
        context.read<DashboardCubit>().loadDashboard(studentId!);
      }
    } catch (e) {
      print('Error loading student data: $e');
    }
  }

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (studentId == null) return;

    switch (index) {
      case 0:
        Navigator.push(
          context,
          SlidePageRoute(
            page: ScanQRScreen(studentId: studentId!),
            direction: SlideDirection.right,
          ),
        );
        break;
      case 1:
        Navigator.push(
          context,
          SlidePageRoute(
            page: const CourseSearchPage(),
            direction: SlideDirection.right,
          ),
        );
        break;
      case 2:
        Navigator.push(
          context,
          SlidePageRoute(
            page: const FacultySearchPage(),
            direction: SlideDirection.right,
          ),
        );
        break;
      case 3:
        Navigator.push(
          context,
          SlidePageRoute(
            page: const DashboardPage(),
            direction: SlideDirection.right,
          ),
        );
        break;
      case 4:
        if (studentId != null) {
          Navigator.push(
            context,
            SlidePageRoute(
              page: ProfilePage(studentId: studentId!),
              direction: SlideDirection.right,
            ),
          );
        }
        break;
      case 5:
        Navigator.push(
          context,
          SlidePageRoute(
            page: const GpaCalcView(),
            direction: SlideDirection.right,
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_rounded, color: colorScheme.primary, size: 28),
            const SizedBox(width: 8),
            Text(
              "Student Portal",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout_rounded, color: colorScheme.error),
            onPressed: () => _showLogoutDialog(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.waving_hand_rounded,
                    color: colorScheme.secondary, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Welcome Back!",
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: colorScheme.onSurface.withOpacity(0.6), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Here's your dashboard to manage courses, attendance, and GPA.",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildActionCard(
                  context: context,
                  icon: Icons.qr_code_scanner_rounded,
                  title: "Scan QR",
                  subtitle: "Register attendance",
                  color: colorScheme.primary,
                  onTap: () {
                    if (studentId != null) {
                      Navigator.push(
                        context,
                        SlidePageRoute(
                          page: ScanQRScreen(studentId: studentId!),
                          direction: SlideDirection.right,
                        ),
                      );
                    }
                  },
                ),
                _buildActionCard(
                  context: context,
                  icon: Icons.search_rounded,
                  title: "Course Search",
                  subtitle: "Find your courses",
                  color: colorScheme.primary,
                  onTap: () => Navigator.push(
                    context,
                    SlidePageRoute(
                      page: const CourseSearchPage(),
                      direction: SlideDirection.right,
                    ),
                  ),
                ),
                _buildActionCard(
                  context: context,
                  icon: Icons.person_search_rounded,
                  title: "Faculty Search",
                  subtitle: "Faculty info & contacts",
                  color: colorScheme.secondary,
                  onTap: () => Navigator.push(
                    context,
                    SlidePageRoute(
                      page: const FacultySearchPage(),
                      direction: SlideDirection.right,
                    ),
                  ),
                ),
                _buildActionCard(
                  context: context,
                  icon: Icons.dashboard_rounded,
                  title: "Dashboard",
                  subtitle: "Performance overview",
                  color: colorScheme.secondary,
                  onTap: () => Navigator.push(
                    context,
                    SlidePageRoute(
                      page: const DashboardPage(),
                      direction: SlideDirection.right,
                    ),
                  ),
                ),
                _buildActionCard(
                  context: context,
                  icon: Icons.person_rounded,
                  title: "Profile",
                  subtitle: "View & edit profile",
                  color: colorScheme.primary,
                  onTap: () {
                    if (studentId != null) {
                      Navigator.push(
                        context,
                        SlidePageRoute(
                          page: ProfilePage(studentId: studentId!),
                          direction: SlideDirection.right,
                        ),
                      );
                    }
                  },
                ),
                _buildActionCard(
                  context: context,
                  icon: Icons.calculate_rounded,
                  title: "GPA Calculator",
                  subtitle: "Track your GPA",
                  color: colorScheme.secondary,
                  onTap: () => Navigator.push(
                    context,
                    SlidePageRoute(
                      page: const GpaCalcView(),
                      direction: SlideDirection.right,
                    ),
                  ),
                ),
                _buildActionCard(
                  context: context,
                  icon: Icons.event_available_rounded,
                  title: "View Attendance",
                  subtitle: "Show your Attendance",
                  color: colorScheme.primary,
                  onTap: () => Navigator.push(
                    context,
                    SlidePageRoute(
                      page: const AttendanceHistoryScreen(),
                      direction: SlideDirection.right,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTapped,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
        showUnselectedLabels: true,
        backgroundColor: colorScheme.surface,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_rounded),
            label: "QR Scan",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            label: "Course",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_search_rounded),
            label: "Faculty",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: "Profile",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate_rounded),
            label: "GPA Calc",
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: MediaQuery.of(context).size.width / 2 - 32,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.logout_rounded, color: colorScheme.error, size: 28),
              const SizedBox(width: 12),
              const Text('Logout'),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: colorScheme.onSurface),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await AuthService.clearLoginSession();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    FadePageRoute(page: const WelcomeScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
