import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../shared/utils/app_colors.dart';
import '../../../services/image_service.dart';
import '../../services/statistics_service.dart';
import '../../viewmodels/dashboard/teacher_dashboard_cubit.dart';
import '../../viewmodels/dashboard/teacher_dashboard_state.dart';
import '../../viewmodels/live_attendance/live_attendance_cubit.dart';
import '../live_attendance/live_attendance_screen.dart';
import '../widgets/custom_app_bar.dart';

/// Responsive breakpoints
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// Teacher Dashboard Screen - Responsive main overview screen for teachers.
///
/// Features:
/// - Responsive layout that adapts to screen sizes
/// - Adaptive grid layouts for stats and courses
/// - Mobile, tablet, and desktop optimized views
/// - Welcome header with gradient (matches Student theme)
/// - Quick statistics cards with AppColors
/// - Today's lectures list with search
/// - QR code generation for attendance
/// - Theme-aware styling (light/dark mode)
/// - Modern animations and transitions
class TeacherDashboardScreen extends StatefulWidget {
  final String facultyName;
  final String facultyId;
  final String role; // 'faculty' or 'teacher_assistant'

  const TeacherDashboardScreen({
    super.key,
    required this.facultyName,
    required this.facultyId,
    required this.role,
  });

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final ImageService _imageService = ImageService();
  final StatisticsService _statisticsService = StatisticsService();

  String? _profileImageUrl;
  int _activeSessions = 0;
  int _totalStudents = 0;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TeacherDashboardCubit>().loadTodayCourses(
          widget.facultyId,
          widget.role,
        );
        _loadProfileAndStatistics();
      }
    });
  }

  Future<void> _loadProfileAndStatistics() async {
    try {
      final userResponse = await _imageService.supabase
          .from(widget.role == 'teacher_assistant'
          ? 'TeacherAssistant'
          : 'Faculty')
          .select('UserId')
          .eq(widget.role == 'teacher_assistant' ? 'TAId' : 'FacultyId',
          widget.facultyId)
          .maybeSingle();

      if (userResponse != null) {
        final userId = userResponse['UserId'];
        final imageUrl = await _imageService.getProfileImage(userId);

        if (mounted) {
          setState(() {
            _profileImageUrl = imageUrl;
          });
        }
      }

      final stats = await _statisticsService.getAllStatistics(
          widget.facultyId, widget.role);

      if (mounted) {
        setState(() {
          _activeSessions = stats['activeSessions'] ?? 0;
          _totalStudents = stats['totalStudents'] ?? 0;
          _loadingStats = false;
        });
      }
    } catch (e) {
      print('Error loading profile/stats: $e');
      if (mounted) {
        setState(() {
          _loadingStats = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Dashboard',
        showBackButton: false,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          color: AppColors.primaryBlue,
          backgroundColor: colorScheme.surface,
          onRefresh: () async {
            context.read<TeacherDashboardCubit>().loadTodayCourses(
              widget.facultyId,
              widget.role,
            );
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              return _buildResponsiveLayout(
                context,
                constraints,
                colorScheme,
                isDark,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveLayout(
      BuildContext context,
      BoxConstraints constraints,
      ColorScheme colorScheme,
      bool isDark,
      ) {
    final width = constraints.maxWidth;
    final isDesktop = width >= ResponsiveBreakpoints.desktop;
    final isTablet = width >= ResponsiveBreakpoints.tablet && !isDesktop;
    final isMobile = width < ResponsiveBreakpoints.tablet;

    // Responsive padding
    final horizontalPadding = isDesktop
        ? 32.0
        : isTablet
        ? 24.0
        : 16.0;

    if (isDesktop) {
      return _buildDesktopLayout(
        colorScheme,
        isDark,
        horizontalPadding,
      );
    } else {
      return _buildMobileTabletLayout(
        colorScheme,
        isDark,
        horizontalPadding,
        isTablet,
      );
    }
  }

  Widget _buildDesktopLayout(
      ColorScheme colorScheme,
      bool isDark,
      double horizontalPadding,
      ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header and Stats Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Header
                  Expanded(
                    flex: 2,
                    child: _buildWelcomeHeader(isDark, isCompact: false),
                  ),
                  const SizedBox(width: 24),
                  // Quick Statistics
                  Expanded(
                    flex: 1,
                    child: BlocBuilder<TeacherDashboardCubit,
                        TeacherDashboardState>(
                      builder: (context, state) {
                        if (state is TeacherDashboardLoaded) {
                          return _buildQuickStatsVertical(
                            state.courses.length,
                            isDark,
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Section Header and Search
              Row(
                children: [
                  Expanded(child: _buildSectionHeader(colorScheme)),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 400,
                    child: _buildSearchBar(colorScheme, isDark),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Courses Grid
              BlocBuilder<TeacherDashboardCubit, TeacherDashboardState>(
                builder: (context, state) {
                  if (state is TeacherDashboardLoading) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48.0),
                        child: CircularProgressIndicator(
                          color: AppColors.primaryBlue,
                          strokeWidth: 3,
                        ),
                      ),
                    );
                  } else if (state is TeacherDashboardLoaded) {
                    final activeCourses = state.courses;
                    final filteredCourses = _filterCourses(activeCourses);

                    if (filteredCourses.isEmpty) {
                      return _buildEmptyState(colorScheme, isDark);
                    }

                    return _buildCoursesGrid(
                      filteredCourses,
                      colorScheme,
                      isDark,
                      crossAxisCount: 2,
                    );
                  } else if (state is TeacherDashboardError) {
                    return _buildErrorState(state.message, colorScheme, isDark);
                  }
                  return const SizedBox();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileTabletLayout(
      ColorScheme colorScheme,
      bool isDark,
      double horizontalPadding,
      bool isTablet,
      ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          _buildWelcomeHeader(isDark, isCompact: !isTablet),
          const SizedBox(height: 24),

          // Quick Statistics
          BlocBuilder<TeacherDashboardCubit, TeacherDashboardState>(
            builder: (context, state) {
              if (state is TeacherDashboardLoaded) {
                return _buildQuickStats(
                  state.courses.length,
                  isDark,
                  isTablet: isTablet,
                );
              }
              return const SizedBox();
            },
          ),
          const SizedBox(height: 24),

          // Section Header
          _buildSectionHeader(colorScheme),
          const SizedBox(height: 12),

          // Search Bar
          _buildSearchBar(colorScheme, isDark),
          const SizedBox(height: 16),

          // Courses List/Grid
          BlocBuilder<TeacherDashboardCubit, TeacherDashboardState>(
            builder: (context, state) {
              if (state is TeacherDashboardLoading) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                      strokeWidth: 3,
                    ),
                  ),
                );
              } else if (state is TeacherDashboardLoaded) {
                final activeCourses = state.courses;
                final filteredCourses = _filterCourses(activeCourses);

                if (filteredCourses.isEmpty) {
                  return _buildEmptyState(colorScheme, isDark);
                }

                if (isTablet) {
                  return _buildCoursesGrid(
                    filteredCourses,
                    colorScheme,
                    isDark,
                    crossAxisCount: 2,
                  );
                } else {
                  return _buildCoursesList(
                    filteredCourses,
                    colorScheme,
                    isDark,
                  );
                }
              } else if (state is TeacherDashboardError) {
                return _buildErrorState(state.message, colorScheme, isDark);
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }

  List<dynamic> _filterCourses(List<dynamic> courses) {
    return courses.where((course) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return course.courseTitle.toLowerCase().contains(query) ||
          course.courseCode.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildWelcomeHeader(bool isDark, {required bool isCompact}) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Profile Image
              Container(
                width: isCompact ? 48 : 56,
                height: isCompact ? 48 : 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child:
                  _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                      ? _buildProfileImage(_profileImageUrl!)
                      : Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: isCompact ? 24 : 28,
                  ),
                ),
              ),
              SizedBox(width: isCompact ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: isCompact ? 12 : 14,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.facultyName,
                      style: TextStyle(
                        fontSize: isCompact ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 12 : 20),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                icon: Icons.calendar_today_rounded,
                text: DateFormat('EEE, MMM d').format(DateTime.now()),
                isCompact: isCompact,
              ),
              _buildInfoChip(
                icon: Icons.access_time_rounded,
                text: DateFormat('h:mm a').format(DateTime.now()),
                isCompact: isCompact,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    bool isCompact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 12,
        vertical: isCompact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: isCompact ? 14 : 16),
          SizedBox(width: isCompact ? 6 : 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: isCompact ? 11 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(int todayLectures, bool isDark,
      {bool isTablet = false}) {
    final isTA = widget.role == 'teacher_assistant';

    if (isTablet) {
      return Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.today_rounded,
              value: _loadingStats ? '--' : '$todayLectures',
              label: isTA ? 'Today\'s Sections' : 'Today\'s Lectures',
              color: AppColors.accentGreen,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.qr_code_scanner_rounded,
              value: _loadingStats ? '--' : '$_activeSessions',
              label: 'Active Sessions',
              color: AppColors.secondaryOrange,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.groups_rounded,
              value: _loadingStats ? '--' : '$_totalStudents',
              label: 'Students',
              color: AppColors.accentPurple,
              isDark: isDark,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.today_rounded,
            value: _loadingStats ? '--' : '$todayLectures',
            label: isTA ? 'Today\'s Sections' : 'Today\'s Lectures',
            color: AppColors.accentGreen,
            isDark: isDark,
            isCompact: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.qr_code_scanner_rounded,
            value: _loadingStats ? '--' : '$_activeSessions',
            label: 'Active Sessions',
            color: AppColors.secondaryOrange,
            isDark: isDark,
            isCompact: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.groups_rounded,
            value: _loadingStats ? '--' : '$_totalStudents',
            label: 'Students',
            color: AppColors.accentPurple,
            isDark: isDark,
            isCompact: true,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatsVertical(int todayLectures, bool isDark) {
    final isTA = widget.role == 'teacher_assistant';
    return Column(
      children: [
        _buildStatCard(
          icon: Icons.today_rounded,
          value: _loadingStats ? '--' : '$todayLectures',
          label: isTA ? 'Today\'s Sections' : 'Today\'s Lectures',
          color: AppColors.accentGreen,
          isDark: isDark,
          isVertical: true,
        ),
        const SizedBox(height: 16),
        _buildStatCard(
          icon: Icons.qr_code_scanner_rounded,
          value: _loadingStats ? '--' : '$_activeSessions',
          label: 'Active Sessions',
          color: AppColors.secondaryOrange,
          isDark: isDark,
          isVertical: true,
        ),
        const SizedBox(height: 16),
        _buildStatCard(
          icon: Icons.groups_rounded,
          value: _loadingStats ? '--' : '$_totalStudents',
          label: 'Students',
          color: AppColors.accentPurple,
          isDark: isDark,
          isVertical: true,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
    bool isCompact = false,
    bool isVertical = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: isVertical
          ? Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.3 : 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? Colors.grey[400]
                        : AppColors.tertiaryLightGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      )
          : Column(
        children: [
          Container(
            padding: EdgeInsets.all(isCompact ? 8 : 10),
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.3 : 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: isCompact ? 20 : 24),
          ),
          SizedBox(height: isCompact ? 8 : 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isCompact ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: isCompact ? 2 : 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isCompact ? 9 : 10,
              color:
              isDark ? Colors.grey[400] : AppColors.tertiaryLightGray,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ColorScheme colorScheme) {
    final isTA = widget.role == 'teacher_assistant';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              isTA ? 'Today\'s Sections' : 'Today\'s Lectures',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              context.read<TeacherDashboardCubit>().loadTodayCourses(
                widget.facultyId,
                widget.role,
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: AppColors.primaryBlue,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search_rounded,
              color: AppColors.primaryBlue,
              size: 24,
            ),
          ),
          hintText: widget.role == 'teacher_assistant'
              ? 'Search sections...'
              : 'Search courses...',
          hintStyle: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.4),
            fontSize: 14,
          ),
          filled: true,
          fillColor: isDark ? colorScheme.surface : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: AppColors.primaryBlue,
              width: 2,
            ),
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 14,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildCoursesList(
      List<dynamic> courses,
      ColorScheme colorScheme,
      bool isDark,
      ) {
    return Column(
      children: courses.asMap().entries.map((entry) {
        final index = entry.key;
        final course = entry.value;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 100)),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: _buildCourseCard(course, colorScheme, isDark),
        );
      }).toList(),
    );
  }

  Widget _buildCoursesGrid(
      List<dynamic> courses,
      ColorScheme colorScheme,
      bool isDark, {
        required int crossAxisCount,
      }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.4,
      ),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 100)),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: _buildCourseCard(course, colorScheme, isDark, isGrid: true),
        );
      },
    );
  }

  Widget _buildCourseCard(
      dynamic course,
      ColorScheme colorScheme,
      bool isDark, {
        bool isGrid = false,
      }) {
    return Container(
      margin: isGrid ? EdgeInsets.zero : const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(isDark ? 0.1 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSessionConfigDialog(
            context,
            course.lectureOfferingId,
            course.courseTitle,
            course.courseCode,
          ),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: isGrid
                ? _buildCourseCardContentVertical(
                course, colorScheme, isDark)
                : _buildCourseCardContentHorizontal(
                course, colorScheme, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCardContentHorizontal(
      dynamic course,
      ColorScheme colorScheme,
      bool isDark,
      ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryBlue.withOpacity(isDark ? 0.3 : 0.15),
                AppColors.accentPurple.withOpacity(isDark ? 0.2 : 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.menu_book_rounded,
            color: AppColors.primaryBlue,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course.courseTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.secondaryOrange
                      .withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  course.courseCode,
                  style: TextStyle(
                    color: AppColors.secondaryOrange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      course.schedule,
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: AppColors.secondaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondaryOrange.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.qr_code_2_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCardContentVertical(
      dynamic course,
      ColorScheme colorScheme,
      bool isDark,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlue.withOpacity(isDark ? 0.3 : 0.15),
                    AppColors.accentPurple.withOpacity(isDark ? 0.2 : 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                color: AppColors.primaryBlue,
                size: 24,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppColors.secondaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondaryOrange.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          course.courseTitle,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
            letterSpacing: -0.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.secondaryOrange.withOpacity(isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            course.courseCode,
            style: TextStyle(
              color: AppColors.secondaryOrange,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 14,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                course.schedule,
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryBlue.withOpacity(isDark ? 0.2 : 0.1),
                    AppColors.accentPurple.withOpacity(isDark ? 0.15 : 0.08),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _searchQuery.isEmpty
                    ? Icons.event_busy_rounded
                    : Icons.search_off_rounded,
                size: 56,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty
                  ? 'No lectures scheduled for today'
                  : 'No lectures found',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Enjoy your day off! 🎉'
                  : 'Try different search terms',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
      String message, ColorScheme colorScheme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.accentRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.accentRed,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<TeacherDashboardCubit>().loadTodayCourses(
                  widget.facultyId,
                  widget.role,
                );
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSessionConfigDialog(
      BuildContext context,
      String lectureOfferingId,
      String courseTitle,
      String courseCode,
      ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final durationController = TextEditingController(text: '10');
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < ResponsiveBreakpoints.tablet;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: colorScheme.surface,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16 : 40,
          vertical: 24,
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Start Session',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  fontSize: isSmallScreen ? 18 : 20,
                ),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isSmallScreen ? double.infinity : 400,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryBlue.withOpacity(isDark ? 0.15 : 0.08),
                      AppColors.accentPurple.withOpacity(isDark ? 0.1 : 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courseTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryOrange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        courseCode,
                        style: TextStyle(
                          color: AppColors.secondaryOrange,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'QR Code Validity (Minutes)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g., 10',
                  prefixIcon: Icon(
                    Icons.timer_outlined,
                    color: AppColors.primaryBlue,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AppColors.primaryBlue,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor:
                  isDark ? colorScheme.surface : AppColors.backgroundLight,
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          if (isSmallScreen)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    final duration =
                        int.tryParse(durationController.text) ?? 10;
                    Navigator.pop(ctx);
                    _startSession(
                        context, lectureOfferingId, courseTitle, duration);
                  },
                  icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                  label: const Text('Generate QR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          else ...[
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final duration = int.tryParse(durationController.text) ?? 10;
                Navigator.pop(ctx);
                _startSession(context, lectureOfferingId, courseTitle, duration);
              },
              icon: const Icon(Icons.qr_code_2_rounded, size: 20),
              label: const Text('Generate QR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _startSession(BuildContext context, String lectureOfferingId,
      String courseTitle, int durationMinutes) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final sessionId = 'LINST-${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();
      final expiresAt = now.add(Duration(minutes: durationMinutes));

      await _imageService.supabase.from('LectureInstance').insert({
        'InstanceId': sessionId,
        'LectureOfferingId': lectureOfferingId,
        'MeetingDate': now.toIso8601String().split('T')[0],
        'StartTime':
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00',
        'EndTime':
        '${expiresAt.hour.toString().padLeft(2, '0')}:${expiresAt.minute.toString().padLeft(2, '0')}:00',
        'Topic': 'Live Session - $courseTitle',
        'QRCode': sessionId,
        'QRExpiresAt': expiresAt.toUtc().toIso8601String(),
        'IsCancelled': false,
      });

      if (context.mounted) {
        Navigator.pop(context);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<LiveAttendanceCubit>(),
              child: LiveAttendanceScreen(
                sessionId: sessionId,
                courseTitle: courseTitle,
                durationMinutes: durationMinutes,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildProfileImage(String base64Image) {
    try {
      final base64Data = base64Image.contains('base64,')
          ? base64Image.split('base64,')[1]
          : base64Image;

      return Image.memory(
        base64Decode(base64Data),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 28,
          );
        },
      );
    } catch (e) {
      return const Icon(
        Icons.person_rounded,
        color: Colors.white,
        size: 28,
      );
    }
  }
}