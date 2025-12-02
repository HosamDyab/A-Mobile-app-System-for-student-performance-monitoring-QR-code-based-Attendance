import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dashboard_page.dart';
import 'QR_scan_page.dart';
import 'GpaCalcView.dart';
import 'ProfilePage.dart';
import '../blocs/DashboardCubit/DashboardCubit.dart';
import '../../../services/auth_service.dart';
import '../../../shared/utils/student_utils.dart';
import '../../../shared/widgets/modern_bottom_nav_bar.dart';
import '../../../shared/widgets/loading_animation.dart';
import '../../../shared/utils/app_colors.dart';

class StudentView extends StatefulWidget {
  const StudentView({super.key});

  @override
  State<StudentView> createState() => _StudentViewState();
}

class _StudentViewState extends State<StudentView> {
  String? _studentId;
  bool _isLoading = true;
  int _currentIndex = 0;

  final List<Widget> _pages = [];

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
        _studentId = savedStudentId;
      } else if (email.isNotEmpty) {
        _studentId = StudentUtils.getStudentIdFromEmail(email);
      }

      if (_studentId != null && _studentId!.isNotEmpty && mounted) {
        // Load dashboard data
        context.read<DashboardCubit>().loadDashboard(_studentId!);

        // Initialize pages
        _pages.addAll([
          const DashboardPage(),
          ScanQRScreen(studentId: _studentId!),
          const GpaCalcView(),
          ProfilePage(studentId: _studentId!),
        ]);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onNavTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _studentId == null || _studentId!.isEmpty) {
      return Scaffold(
        body: Center(
          child: LoadingAnimation(
            color: AppColors.primaryBlue,
            size: 50,
          ),
        ),
      );
    }

    if (_pages.isEmpty) {
      return Scaffold(
        body: Center(
          child: LoadingAnimation(
            color: AppColors.primaryBlue,
            size: 50,
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: ModernBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTapped,
        items: const [
          NavBarItem(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
          ),
          NavBarItem(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Scan QR',
          ),
          NavBarItem(
            icon: Icons.calculate_rounded,
            label: 'GPA Calc',
          ),
          NavBarItem(
            icon: Icons.person_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
