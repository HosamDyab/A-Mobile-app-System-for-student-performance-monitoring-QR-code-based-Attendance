// lib/presentation/views/student_view.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dashboard_page.dart';
import 'QR_scan_page.dart';
import 'GpaCalcView.dart';
import 'ProfilePage.dart';
import 'view_attendance.dart';

import '../blocs/DashboardCubit/DashboardCubit.dart';
import '../blocs/SearchCuit.dart'; // assuming this is the cubit file path
import '../../../services/auth_service.dart';
import '../../../shared/utils/student_utils.dart';
import '../../../shared/widgets/curved_bottom_nav_with_fab.dart';
import '../../../shared/widgets/loading_animation.dart';
import '../../../shared/utils/app_colors.dart';

/// Student View - Main entry point for students
class StudentView extends StatefulWidget {
  const StudentView({super.key});

  @override
  State<StudentView> createState() => _StudentViewState();
}

class _StudentViewState extends State<StudentView> {
  String? _studentId;
  bool _isLoading = true;
  int _currentIndex = 0;

  /// Pages for bottom navigation
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  /// Loads student data from AuthService and initializes pages
  Future<void> _loadStudentData() async {
    try {
      final loginData = await AuthService.getLoginData();
      final email = (loginData['email'] ?? '');
      final savedStudentId = loginData['studentId'];

      // Determine studentId from saved data or email
      if (savedStudentId != null && savedStudentId.isNotEmpty) {
        _studentId = savedStudentId;
      } else if (email.isNotEmpty) {
        _studentId = StudentUtils.getStudentIdFromEmail(email);
      }

      if (_studentId != null && _studentId!.isNotEmpty && mounted) {
        // Set studentId in StudentSearchCubit if available
        try {
          final searchCubit = context.read<StudentSearchCubit>();
          searchCubit.setStudentId(_studentId!);
        } catch (_) {}

        // Request dashboard data if DashboardCubit exists
        try {
          context.read<DashboardCubit>().loadDashboard(_studentId!);
        } catch (_) {}

        // Initialize pages safely
        _pages.clear();
        _pages.addAll([
          const DashboardPage(),
          const AttendanceHistoryScreen(),
          const GpaCalcView(),
          ProfilePage(studentId: _studentId!),
        ]);
      }
    } catch (e, st) {
      debugPrint('Error loading student data: $e\n$st');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Handles navigation tab changes
  void _onNavTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  /// Opens QR scanner screen (FAB action)
  void _openQRScanner() {
    if (_studentId != null && _studentId!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ScanQRScreen(studentId: _studentId!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student ID not available.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: LoadingAnimation(
            color: AppColors.primaryBlue,
            size: 50,
          ),
        ),
      );
    }

    // Friendly error if studentId not found
    if (_studentId == null || _studentId!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Student View')),
        body: const Center(
          child: Text('Unable to determine student ID. Please login again.'),
        ),
      );
    }

    // Defensive: show loader if pages are not ready
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

    // Main UI with bottom navigation
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: CurvedBottomNavWithFAB(
        currentIndex: _currentIndex,
        onTap: _onNavTapped,
        items: const [
          NavBarItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
          NavBarItem(icon: Icons.event_available_rounded, label: 'Attendance'),
          NavBarItem(icon: Icons.calculate_rounded, label: 'GPA Calc'),
          NavBarItem(icon: Icons.person_rounded, label: 'Profile'),
        ],
        onFABPressed: _openQRScanner,
        fabIcon: Icons.qr_code_scanner_rounded,
        fabTooltip: 'Scan QR Code for Attendance',
      ),
    );
  }
}
