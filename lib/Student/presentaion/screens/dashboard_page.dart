import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'dart:convert'; // Add this for JSON formatting

import '../blocs/DashboardCubit/DashboardCubit.dart';
import '../blocs/DashboardCubit/DashboardState.dart';
import '../widgets/dashboard__buildCoursesList.dart';
import '../widgets/dashboard_buildProfileCard.dart';
import '../widgets/dashboard_buildSectionTitle.dart';
import '../widgets/dashbourd_buildScoreChart.dart';
import '../../../shared/widgets/animated_gradient_background.dart';
import '../../../shared/widgets/staggered_animation_list.dart';
import '../../../shared/utils/app_colors.dart';
import '../../../shared/widgets/loading_animation.dart';
import '../../../services/auth_service.dart';
import '../../../shared/utils/student_utils.dart';
import '../../../shared/widgets/theme_toggle_button.dart';
import 'StudentSearchPage.dart';
import 'faculty_search_page.dart';
import '../../../shared/utils/page_transitions.dart';
import '../../../shared/widgets/logout_button.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String? _studentId;
  String? _studentName;
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadStudentData() async {
    try {
      final loginData = await AuthService.getLoginData();
      final email = loginData['email'] ?? '';
      final savedStudentId = loginData['studentId'];
      final savedUserName = loginData['userName'];

      // Get student ID from email or saved data
      if (savedStudentId != null && savedStudentId.isNotEmpty) {
        _studentId = savedStudentId;
      } else if (email.isNotEmpty) {
        _studentId = StudentUtils.getStudentIdFromEmail(email);
      }

      // Get student name
      if (savedUserName != null && savedUserName.isNotEmpty) {
        _studentName = savedUserName;
      } else if (email.isNotEmpty) {
        _studentName = StudentUtils.getStudentNameFromEmail(email);
      }

      if (_studentId != null && _studentId!.isNotEmpty && mounted) {
        // Load dashboard data
        context.read<DashboardCubit>().loadDashboard(_studentId!);
      }
    } catch (e) {
      print('Error loading student data: $e');
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading) {
          return Scaffold(
            body: AnimatedGradientBackground(
              colors: AppColors.animatedGradientColors,
              child: Center(
                child: LoadingAnimation(
                  size: 50,
                  color: colorScheme.primary,
                ),
              ),
            ),
          );
        }

        if (state is DashboardError) {
          return Scaffold(
            body: AnimatedGradientBackground(
              colors: AppColors.animatedGradientColors,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.error.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: colorScheme.error,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Error: ${state.msg}",
                        style: TextStyle(
                          color: colorScheme.error,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // Update the DashboardLoaded section in your DashboardPage

        if (state is DashboardLoaded) {
          final profile = state.profile;
          // ✅ FIX: Cast to proper type
          final courses = List<Map<String, dynamic>>.from(state.courses);

          // ============= DEBUG PRINTS START =============
          print('\n=== DASHBOARD DEBUG INFO ===');
          print('Total courses returned: ${courses.length}');
          print('\n--- Raw Courses Data ---');

          // Print formatted JSON for each course
          for (int i = 0; i < courses.length; i++) {
            print('\n--- Course $i ---');
            try {
              // Pretty print the JSON
              final prettyJson = JsonEncoder.withIndent('  ').convert(courses[i]);
              print(prettyJson);
            } catch (e) {
              // Fallback to regular print if JSON encoding fails
              print(courses[i]);
            }
          }

          // Print the structure/keys of first course (if exists)
          if (courses.isNotEmpty) {
            print('\n--- First Course Structure ---');
            print('Top-level keys: ${courses[0].keys.toList()}');

            if (courses[0].containsKey('lecturecourseoffering')) {
              print('lecturecourseoffering keys: ${courses[0]['lecturecourseoffering']?.keys.toList()}');

              if (courses[0]['lecturecourseoffering']?['course'] != null) {
                print('course keys: ${courses[0]['lecturecourseoffering']['course']?.keys.toList()}');
              }
            }
          }

          print('\n=== END DEBUG INFO ===\n');
          // ============= DEBUG PRINTS END =============

          // ✅ FIX: Explicitly type the filtered courses
          final List<Map<String, dynamic>> filteredCourses =
          _searchQuery != null && _searchQuery!.isNotEmpty
              ? courses.where((course) {
            print('Filtering course: ${course}');

            final courseTitle = course['lecturecourseoffering']
            ?['course']?['coursename']
                ?.toString()
                .toLowerCase() ?? '';

            print('Course title extracted: "$courseTitle"');

            return courseTitle.contains(_searchQuery!.toLowerCase());
          }).toList()
              : courses;

          print('\nFiltered courses count: ${filteredCourses.length}');

          return PopScope(
            canPop: false,
            onPopInvoked: (didPop) {
              // Prevent back navigation to login - user stays in app
            },
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.dashboard_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Dashboard",
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (_studentName != null)
                            Text(
                              "Welcome, $_studentName!",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  const ThemeToggleButton(),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.search_rounded,
                          color: Colors.white, size: 20),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (context) => _buildSearchSheet(context),
                      );
                    },
                    tooltip: 'Search',
                  ),
                  LogoutButton(showAsIcon: true),
                ],
              ),
              body: AnimatedGradientBackground(
                colors: AppColors.animatedGradientColors,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: StaggeredAnimationList(
                    staggerDuration: const Duration(milliseconds: 100),
                    children: [
                      ProfileCard(profile: profile),
                      const SizedBox(height: 30),
                      SectionTitle(
                        title: "Scores Chart",
                        icon: Icons.bar_chart_rounded,
                      ),
                      const SizedBox(height: 12),
                      ScoreChart(courses: filteredCourses),
                      const SizedBox(height: 30),
                      SectionTitle(
                        title: _searchQuery != null && _searchQuery!.isNotEmpty
                            ? "Search Results"
                            : "My Courses",
                        icon: Icons.menu_book_rounded,
                      ),
                      const SizedBox(height: 12),
                      CoursesList(courses: filteredCourses),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          body: AnimatedGradientBackground(
            colors: AppColors.animatedGradientColors,
            child: const Center(child: Text("Loading...")),
          ),
        );
      },
    );
  }

  Widget _buildSearchSheet(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.98),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, -10),
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Search',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 20),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildQuickAction(
                  context,
                  icon: Icons.search_rounded,
                  label: 'Courses',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      AdvancedSlidePageRoute(
                        page: const CourseSearchPage(),
                        direction: SlideDirection.right,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickAction(
                  context,
                  icon: Icons.person_search_rounded,
                  label: 'Faculty',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      AdvancedSlidePageRoute(
                        page: const FacultySearchPage(),
                        direction: SlideDirection.right,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onTap,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.secondaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondaryOrange.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}