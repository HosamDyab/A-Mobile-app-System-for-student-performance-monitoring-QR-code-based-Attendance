import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../blocs/attendace_bloc/attendance_cubit.dart';
import '../../../shared/utils/app_colors.dart';
import '../../../shared/widgets/animated_gradient_background.dart';
import '../../../shared/widgets/hover_scale_widget.dart';
import '../../../shared/widgets/loading_animation.dart';
import '../../../shared/widgets/theme_toggle_button.dart';
import '../../../services/auth_service.dart';
import '../../../shared/utils/student_utils.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late Animation<double> _headerAnimation;

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerAnimation = CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutCubic,
    );
    _headerAnimationController.forward();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    super.dispose();
  }

  // Responsive breakpoint helper
  DeviceType _getDeviceType(double width) {
    if (width >= 1200) return DeviceType.desktop;
    if (width >= 900) return DeviceType.tablet;
    if (width >= 600) return DeviceType.largeMobile;
    return DeviceType.mobile;
  }

  // Responsive spacing
  EdgeInsets _getResponsivePadding(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.desktop:
        return const EdgeInsets.all(40);
      case DeviceType.tablet:
        return const EdgeInsets.all(28);
      case DeviceType.largeMobile:
        return const EdgeInsets.all(20);
      case DeviceType.mobile:
        return const EdgeInsets.all(16);
    }
  }

  double _getResponsiveSpacing(DeviceType deviceType, {bool large = false}) {
    if (large) {
      switch (deviceType) {
        case DeviceType.desktop:
          return 32;
        case DeviceType.tablet:
          return 28;
        case DeviceType.largeMobile:
          return 24;
        case DeviceType.mobile:
          return 20;
      }
    }
    switch (deviceType) {
      case DeviceType.desktop:
        return 20;
      case DeviceType.tablet:
        return 16;
      case DeviceType.largeMobile:
        return 14;
      case DeviceType.mobile:
        return 12;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AttendanceCubit>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final deviceType = _getDeviceType(size.width);
    final orientation = MediaQuery.of(context).orientation;
    String? studentId;

    // Get student ID dynamically
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final loginData = await AuthService.getLoginData();
      final email = loginData['email'] ?? '';
      final savedStudentId = loginData['studentId'];

      if (savedStudentId != null && savedStudentId.isNotEmpty) {
        studentId = savedStudentId;
      } else if (email.isNotEmpty) {
        studentId = StudentUtils.getStudentIdFromEmail(email);
      }

      if (studentId != null && studentId!.isNotEmpty) {
        cubit.fetchStudentAttendance(studentId!);
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: AnimatedGradientBackground(
          child: SafeArea(
            child: BlocBuilder<AttendanceCubit, AttendanceState>(
              builder: (context, state) {
                if (state is AttendanceLoading) {
                  return Center(
                    child: LoadingAnimation(
                      color: AppColors.primaryBlue,
                      size: deviceType == DeviceType.desktop ? 70 : 50,
                    ),
                  );
                } else if (state is AttendanceLoaded) {
                  final records = state.attendances;

                  if (records.isEmpty) {
                    return _buildEmptyState(
                        context, deviceType, theme, colorScheme);
                  }

                  // Calculate statistics
                  final presentCount = records
                      .where((r) => r.status.toLowerCase() == 'present')
                      .length;
                  final absentCount = records.length - presentCount;
                  final attendanceRate = records.isEmpty
                      ? 0.0
                      : (presentCount / records.length) * 100;

                  return CustomScrollView(
                    slivers: [
                      // Custom App Bar
                      _buildSliverAppBar(context, deviceType, theme),

                      SliverToBoxAdapter(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: deviceType == DeviceType.desktop
                                      ? 1400
                                      : double.infinity,
                                ),
                                child: Padding(
                                  padding: _getResponsivePadding(deviceType),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      // Hero Statistics Card
                                      _buildHeroStatsCard(
                                        context: context,
                                        attendanceRate: attendanceRate,
                                        presentCount: presentCount,
                                        absentCount: absentCount,
                                        totalRecords: records.length,
                                        deviceType: deviceType,
                                        orientation: orientation,
                                      ),
                                      SizedBox(
                                          height: _getResponsiveSpacing(
                                              deviceType,
                                              large: true)),

                                      // Quick Stats Grid
                                      // _buildQuickStatsGrid(
                                      //   context: context,
                                      //   presentCount: presentCount,
                                      //   absentCount: absentCount,
                                      //   records: records,
                                      //   deviceType: deviceType,
                                      //   orientation: orientation,
                                      // ),
                                      SizedBox(
                                          height: _getResponsiveSpacing(
                                              deviceType,
                                              large: true)),

                                      // Chart Section with improved design
                                      _buildEnhancedChartSection(
                                        context: context,
                                        presentCount: presentCount,
                                        absentCount: absentCount,
                                        records: records,
                                        deviceType: deviceType,
                                        orientation: orientation,
                                        theme: theme,
                                      ),
                                      SizedBox(
                                          height: _getResponsiveSpacing(
                                              deviceType,
                                              large: true)),

                                      // Section Title with animation
                                      _buildSectionTitle(
                                        context: context,
                                        title: 'Recent Activity',
                                        icon: Icons.history_rounded,
                                        deviceType: deviceType,
                                        theme: theme,
                                      ),
                                      SizedBox(
                                          height: _getResponsiveSpacing(
                                              deviceType)),

                                      // Records List
                                      _buildRecordsList(
                                        context: context,
                                        records: records,
                                        theme: theme,
                                        colorScheme: colorScheme,
                                        deviceType: deviceType,
                                        orientation: orientation,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                } else if (state is AttendanceError) {
                  return _buildErrorState(
                      context, state.message, deviceType, theme);
                } else {
                  return Center(
                    child: Text(
                      "Load attendance data...",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ),
        floatingActionButton: _buildFAB(context, cubit, deviceType),
      ),
    );
  }

  Widget _buildSliverAppBar(
      BuildContext context, DeviceType deviceType, ThemeData theme) {
    final expandedHeight = deviceType == DeviceType.desktop
        ? 180.0
        : deviceType == DeviceType.tablet
        ? 160.0
        : deviceType == DeviceType.largeMobile
        ? 140.0
        : 120.0;

    final iconSize =
    deviceType == DeviceType.desktop || deviceType == DeviceType.tablet
        ? 28.0
        : 24.0;
    final titleFontSize = deviceType == DeviceType.desktop
        ? 32.0
        : deviceType == DeviceType.tablet
        ? 28.0
        : 24.0;
    final subtitleFontSize =
    deviceType == DeviceType.desktop || deviceType == DeviceType.tablet
        ? 16.0
        : 14.0;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: FadeTransition(
          opacity: _headerAnimation,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryBlue.withOpacity(0.1),
                  AppColors.secondaryOrange.withOpacity(0.05),
                ],
              ),
            ),
            padding: EdgeInsets.only(
              left: _getResponsivePadding(deviceType).left,
              right: _getResponsivePadding(deviceType).right,
              top: 60,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(
                          deviceType == DeviceType.mobile ? 10 : 14),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.event_available_rounded,
                        color: Colors.white,
                        size: iconSize,
                      ),
                    ),
                    SizedBox(width: _getResponsiveSpacing(deviceType)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attendance',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: titleFontSize,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Track your presence',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                              theme.colorScheme.onSurface.withOpacity(0.6),
                              fontSize: subtitleFontSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 8),
          child: ThemeToggleButton(),
        ),
      ],
    );
  }

  Widget _buildHeroStatsCard({
    required BuildContext context,
    required double attendanceRate,
    required int presentCount,
    required int absentCount,
    required int totalRecords,
    required DeviceType deviceType,
    required Orientation orientation,
  }) {
    final theme = Theme.of(context);
    final padding = deviceType == DeviceType.desktop
        ? 40.0
        : deviceType == DeviceType.tablet
        ? 32.0
        : deviceType == DeviceType.largeMobile
        ? 24.0
        : 20.0;

    final percentageFontSize = deviceType == DeviceType.desktop
        ? 72.0
        : deviceType == DeviceType.tablet
        ? 64.0
        : deviceType == DeviceType.largeMobile
        ? 56.0
        : 48.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryBlue,
                    AppColors.primaryBlue.withOpacity(0.8),
                    AppColors.secondaryOrange.withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(
                    deviceType == DeviceType.mobile ? 20 : 32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Overall Attendance",
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontSize:
                                deviceType == DeviceType.mobile ? 14 : 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(
                                height:
                                deviceType == DeviceType.mobile ? 8 : 16),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: attendanceRate),
                              duration: const Duration(milliseconds: 1200),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) {
                                return Text(
                                  "${value.toStringAsFixed(1)}%",
                                  style: theme.textTheme.displayLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: percentageFontSize,
                                    height: 1,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(
                            deviceType == DeviceType.mobile ? 10 : 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.trending_up_rounded,
                          color: Colors.white,
                          size: deviceType == DeviceType.mobile ? 28 : 40,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: deviceType == DeviceType.mobile ? 16 : 24),
                  Container(
                    padding: EdgeInsets.all(
                        deviceType == DeviceType.mobile ? 12 : 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: orientation == Orientation.portrait ||
                        deviceType == DeviceType.mobile
                        ? Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceAround,
                          children: [
                            _buildMiniStat(
                              icon: Icons.check_circle_outline_rounded,
                              label: "Present",
                              value: presentCount.toString(),
                              deviceType: deviceType,
                            ),
                            Container(
                              width: 1,
                              height: deviceType == DeviceType.mobile
                                  ? 28
                                  : 40,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            _buildMiniStat(
                              icon: Icons.cancel_outlined,
                              label: "Absent",
                              value: absentCount.toString(),
                              deviceType: deviceType,
                            ),
                          ],
                        ),
                        if (deviceType == DeviceType.mobile) ...[
                          const SizedBox(height: 12),
                          _buildMiniStat(
                            icon: Icons.calendar_today_rounded,
                            label: "Total",
                            value: totalRecords.toString(),
                            deviceType: deviceType,
                          ),
                        ],
                      ],
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMiniStat(
                          icon: Icons.check_circle_outline_rounded,
                          label: "Present",
                          value: presentCount.toString(),
                          deviceType: deviceType,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        _buildMiniStat(
                          icon: Icons.cancel_outlined,
                          label: "Absent",
                          value: absentCount.toString(),
                          deviceType: deviceType,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        _buildMiniStat(
                          icon: Icons.calendar_today_rounded,
                          label: "Total",
                          value: totalRecords.toString(),
                          deviceType: deviceType,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String label,
    required String value,
    required DeviceType deviceType,
  }) {
    final iconSize = deviceType == DeviceType.mobile ? 20.0 : 28.0;
    final valueFontSize = deviceType == DeviceType.mobile ? 18.0 : 24.0;
    final labelFontSize = deviceType == DeviceType.mobile ? 11.0 : 14.0;

    return Column(
      children: [
        Icon(icon, color: Colors.white, size: iconSize),
        SizedBox(height: deviceType == DeviceType.mobile ? 4 : 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: valueFontSize,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: labelFontSize,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatsGrid({
    required BuildContext context,
    required int presentCount,
    required int absentCount,
    required List records,
    required DeviceType deviceType,
    required Orientation orientation,
  }) {
    final lastWeekRecords = records.where((r) {
      final diff = DateTime.now().difference(r.scanTime.toLocal()).inDays;
      return diff <= 7;
    }).length;

    final stats = [
      {
        'icon': Icons.insights_rounded,
        'label': 'This Week',
        'value': lastWeekRecords.toString(),
        'color': AppColors.secondaryOrange,
      },
      {
        'icon': Icons.local_fire_department_rounded,
        'label': 'Streak',
        'value': _calculateStreak(records).toString(),
        'color': AppColors.accentRed,
      },
      {
        'icon': Icons.star_rounded,
        'label': 'Best Month',
        'value': _getBestMonth(records),
        'color': AppColors.accentGreen,
      },
    ];

    // Determine grid layout based on device type and orientation
    int crossAxisCount;
    double childAspectRatio;

    if (deviceType == DeviceType.desktop) {
      crossAxisCount = 3;
      childAspectRatio = 1.2;
    } else if (deviceType == DeviceType.tablet) {
      crossAxisCount = 3;
      childAspectRatio = orientation == Orientation.portrait ? 1.1 : 1.3;
    } else if (deviceType == DeviceType.largeMobile) {
      crossAxisCount = 3;
      childAspectRatio = orientation == Orientation.portrait ? 0.95 : 1.2;
    } else {
      crossAxisCount = orientation == Orientation.portrait ? 3 : 3;
      childAspectRatio = orientation == Orientation.portrait ? 0.85 : 1.1;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: _getResponsiveSpacing(deviceType),
        mainAxisSpacing: _getResponsiveSpacing(deviceType),
        childAspectRatio: childAspectRatio,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 100)),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                padding:
                EdgeInsets.all(deviceType == DeviceType.mobile ? 12 : 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                      deviceType == DeviceType.mobile ? 14 : 20),
                  boxShadow: [
                    BoxShadow(
                      color: (stat['color'] as Color).withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(
                          deviceType == DeviceType.mobile ? 8 : 12),
                      decoration: BoxDecoration(
                        color: (stat['color'] as Color).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        stat['icon'] as IconData,
                        color: stat['color'] as Color,
                        size: deviceType == DeviceType.mobile ? 20 : 28,
                      ),
                    ),
                    SizedBox(height: deviceType == DeviceType.mobile ? 6 : 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        stat['value'] as String,
                        style: TextStyle(
                          fontSize: deviceType == DeviceType.mobile ? 18 : 24,
                          fontWeight: FontWeight.w800,
                          color: stat['color'] as Color,
                        ),
                      ),
                    ),
                    SizedBox(height: deviceType == DeviceType.mobile ? 2 : 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        stat['label'] as String,
                        style: TextStyle(
                          fontSize: deviceType == DeviceType.mobile ? 10 : 13,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  int _calculateStreak(List records) {
    if (records.isEmpty) return 0;

    final sortedRecords = records
        .where((r) => r.status.toLowerCase() == 'present')
        .map((r) => r.scanTime.toLocal())
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (sortedRecords.isEmpty) return 0;

    int streak = 1;
    for (int i = 0; i < sortedRecords.length - 1; i++) {
      final diff = sortedRecords[i].difference(sortedRecords[i + 1]).inDays;
      if (diff <= 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  String _getBestMonth(List records) {
    if (records.isEmpty) return 'N/A';

    final monthCounts = <String, int>{};
    for (final record in records) {
      if (record.status.toLowerCase() == 'present') {
        final month = DateFormat('MMM').format(record.scanTime.toLocal());
        monthCounts[month] = (monthCounts[month] ?? 0) + 1;
      }
    }

    if (monthCounts.isEmpty) return 'N/A';

    final best =
    monthCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
    return best.key;
  }

  Widget _buildEnhancedChartSection({
    required BuildContext context,
    required int presentCount,
    required int absentCount,
    required List records,
    required DeviceType deviceType,
    required Orientation orientation,
    required ThemeData theme,
  }) {
    final padding = deviceType == DeviceType.desktop
        ? 32.0
        : deviceType == DeviceType.tablet
        ? 28.0
        : deviceType == DeviceType.largeMobile
        ? 24.0
        : 20.0;

    final chartHeight = deviceType == DeviceType.desktop
        ? 280.0
        : deviceType == DeviceType.tablet
        ? 240.0
        : deviceType == DeviceType.largeMobile
        ? 200.0
        : 180.0;

    final centerRadius = deviceType == DeviceType.desktop
        ? 80.0
        : deviceType == DeviceType.tablet
        ? 70.0
        : deviceType == DeviceType.largeMobile
        ? 60.0
        : 50.0;

    final pieRadius = deviceType == DeviceType.desktop
        ? 80.0
        : deviceType == DeviceType.tablet
        ? 70.0
        : deviceType == DeviceType.largeMobile
        ? 60.0
        : 50.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(deviceType == DeviceType.mobile ? 20 : 28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(
                        deviceType == DeviceType.mobile ? 8 : 12),
                    decoration: BoxDecoration(
                      gradient: AppColors.secondaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.pie_chart_rounded,
                      color: Colors.white,
                      size: deviceType == DeviceType.mobile ? 18 : 24,
                    ),
                  ),
                  SizedBox(width: _getResponsiveSpacing(deviceType)),
                  Text(
                    "Distribution",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: deviceType == DeviceType.mobile ? 18 : 24,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: deviceType == DeviceType.mobile ? 20 : 32),

          // Adaptive layout for chart and legend
          if (deviceType == DeviceType.desktop &&
              orientation == Orientation.landscape)
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: chartHeight,
                    child: _buildPieChart(presentCount, absentCount, records,
                        centerRadius, pieRadius, deviceType),
                  ),
                ),
                const SizedBox(width: 40),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem(
                        color: AppColors.accentGreen,
                        label: 'Present Days',
                        value: presentCount,
                        percentage: (presentCount / records.length) * 100,
                        deviceType: deviceType,
                      ),
                      const SizedBox(height: 20),
                      _buildLegendItem(
                        color: AppColors.accentRed,
                        label: 'Absent Days',
                        value: absentCount,
                        percentage: (absentCount / records.length) * 100,
                        deviceType: deviceType,
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                SizedBox(
                  height: chartHeight,
                  child: _buildPieChart(presentCount, absentCount, records,
                      centerRadius, pieRadius, deviceType),
                ),
                SizedBox(height: deviceType == DeviceType.mobile ? 16 : 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildLegendItem(
                        color: AppColors.accentGreen,
                        label: 'Present',
                        value: presentCount,
                        percentage: (presentCount / records.length) * 100,
                        deviceType: deviceType,
                        compact: true,
                      ),
                    ),
                    SizedBox(width: _getResponsiveSpacing(deviceType)),
                    Expanded(
                      child: _buildLegendItem(
                        color: AppColors.accentRed,
                        label: 'Absent',
                        value: absentCount,
                        percentage: (absentCount / records.length) * 100,
                        deviceType: deviceType,
                        compact: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPieChart(int presentCount, int absentCount, List records,
      double centerRadius, double pieRadius, DeviceType deviceType) {
    final fontSize = deviceType == DeviceType.mobile ? 14.0 : 18.0;

    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: centerRadius,
        sections: [
          PieChartSectionData(
            value: presentCount.toDouble(),
            title:
            '${((presentCount / records.length) * 100).toStringAsFixed(0)}%',
            color: AppColors.accentGreen,
            radius: pieRadius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            badgeWidget: presentCount > absentCount
                ? Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.star,
                color: AppColors.accentGreen,
                size: deviceType == DeviceType.mobile ? 14 : 20,
              ),
            )
                : null,
            badgePositionPercentageOffset: 1.2,
          ),
          PieChartSectionData(
            value: absentCount.toDouble(),
            title: absentCount > 0
                ? '${((absentCount / records.length) * 100).toStringAsFixed(0)}%'
                : '',
            color: AppColors.accentRed,
            radius: pieRadius * 0.95,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required int value,
    required double percentage,
    required DeviceType deviceType,
    bool compact = false,
  }) {
    final padding = deviceType == DeviceType.mobile ? 10.0 : 16.0;
    final labelFontSize =
    deviceType == DeviceType.mobile ? 12.0 : (compact ? 14.0 : 16.0);
    final valueFontSize = deviceType == DeviceType.mobile ? 18.0 : 24.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: compact
          ? Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: deviceType == DeviceType.mobile ? 6 : 8),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      )
          : Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$value days (${percentage.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: deviceType == DeviceType.mobile ? 11 : 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required BuildContext context,
    required String title,
    required IconData icon,
    required DeviceType deviceType,
    required ThemeData theme,
  }) {
    final iconPadding = deviceType == DeviceType.mobile ? 8.0 : 10.0;
    final iconSize = deviceType == DeviceType.mobile ? 18.0 : 22.0;
    final titleFontSize = deviceType == DeviceType.mobile ? 20.0 : 26.0;
    final badgeFontSize = deviceType == DeviceType.mobile ? 10.0 : 12.0;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(iconPadding),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: iconSize,
          ),
        ),
        SizedBox(width: _getResponsiveSpacing(deviceType)),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: titleFontSize,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: deviceType == DeviceType.mobile ? 8 : 12,
            vertical: deviceType == DeviceType.mobile ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Latest',
            style: TextStyle(
              fontSize: badgeFontSize,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordsList({
    required BuildContext context,
    required List records,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required DeviceType deviceType,
    required Orientation orientation,
  }) {
    // Determine grid layout
    if (deviceType == DeviceType.desktop) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: orientation == Orientation.landscape ? 2 : 1,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: orientation == Orientation.landscape ? 3.5 : 4,
        ),
        itemCount: records.length > 10 ? 10 : records.length,
        itemBuilder: (context, index) {
          final r = records[index];
          return _buildEnhancedAttendanceCard(
            context: context,
            record: r,
            index: index,
            theme: theme,
            colorScheme: colorScheme,
            deviceType: deviceType,
          );
        },
      );
    } else if (deviceType == DeviceType.tablet &&
        orientation == Orientation.landscape) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 3.2,
        ),
        itemCount: records.length > 10 ? 10 : records.length,
        itemBuilder: (context, index) {
          final r = records[index];
          return _buildEnhancedAttendanceCard(
            context: context,
            record: r,
            index: index,
            theme: theme,
            colorScheme: colorScheme,
            deviceType: deviceType,
          );
        },
      );
    } else {
      return Column(
        children: records.take(10).map((r) {
          final index = records.indexOf(r);
          return _buildEnhancedAttendanceCard(
            context: context,
            record: r,
            index: index,
            theme: theme,
            colorScheme: colorScheme,
            deviceType: deviceType,
          );
        }).toList(),
      );
    }
  }

  Widget _buildEnhancedAttendanceCard({
    required BuildContext context,
    required dynamic record,
    required int index,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required DeviceType deviceType,
  }) {
    final formattedDate =
    DateFormat('MMM dd, yyyy').format(record.scanTime.toLocal());
    final formattedTime =
    DateFormat('hh:mm a').format(record.scanTime.toLocal());
    final isPresent = record.status.toLowerCase() == 'present';

    final borderRadius = deviceType == DeviceType.mobile ? 14.0 : 20.0;
    final padding = deviceType == DeviceType.mobile ? 14.0 : 20.0;
    final iconSize = deviceType == DeviceType.mobile ? 48.0 : 64.0;
    final iconInnerSize = deviceType == DeviceType.mobile ? 24.0 : 32.0;
    final marginBottom = deviceType == DeviceType.mobile ? 10.0 : 16.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: HoverScaleWidget(
              child: Container(
                margin: EdgeInsets.only(bottom: marginBottom),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: isPresent
                        ? AppColors.accentGreen.withOpacity(0.3)
                        : AppColors.accentRed.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isPresent
                          ? AppColors.accentGreen
                          : AppColors.accentRed)
                          .withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Gradient accent on the left
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: isPresent
                                ? [
                              AppColors.accentGreen,
                              AppColors.accentGreen.withOpacity(0.5)
                            ]
                                : [
                              AppColors.accentRed,
                              AppColors.accentRed.withOpacity(0.5)
                            ],
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(borderRadius),
                            bottomLeft: Radius.circular(borderRadius),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(padding),
                      child: Row(
                        children: [
                          // Status Icon
                          Container(
                            width: iconSize,
                            height: iconSize,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isPresent
                                    ? [
                                  AppColors.accentGreen,
                                  AppColors.accentGreen.withOpacity(0.7)
                                ]
                                    : [
                                  AppColors.accentRed,
                                  AppColors.accentRed.withOpacity(0.7)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(
                                  deviceType == DeviceType.mobile ? 12 : 16),
                              boxShadow: [
                                BoxShadow(
                                  color: (isPresent
                                      ? AppColors.accentGreen
                                      : AppColors.accentRed)
                                      .withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              isPresent
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              color: Colors.white,
                              size: iconInnerSize,
                            ),
                          ),
                          SizedBox(
                              width: deviceType == DeviceType.mobile ? 10 : 16),

                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "Session ${record.instanceId}",
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize:
                                          deviceType == DeviceType.mobile
                                              ? 14
                                              : 17,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal:
                                        deviceType == DeviceType.mobile
                                            ? 8
                                            : 12,
                                        vertical:
                                        deviceType == DeviceType.mobile
                                            ? 4
                                            : 6,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: isPresent
                                              ? [
                                            AppColors.accentGreen
                                                .withOpacity(0.2),
                                            AppColors.accentGreen
                                                .withOpacity(0.1),
                                          ]
                                              : [
                                            AppColors.accentRed
                                                .withOpacity(0.2),
                                            AppColors.accentRed
                                                .withOpacity(0.1),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isPresent
                                              ? AppColors.accentGreen
                                              .withOpacity(0.3)
                                              : AppColors.accentRed
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        record.status.toUpperCase(),
                                        style: TextStyle(
                                          color: isPresent
                                              ? AppColors.accentGreen
                                              : AppColors.accentRed,
                                          fontWeight: FontWeight.w800,
                                          fontSize:
                                          deviceType == DeviceType.mobile
                                              ? 9
                                              : 11,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                    height: deviceType == DeviceType.mobile
                                        ? 6
                                        : 10),
                                Wrap(
                                  spacing:
                                  deviceType == DeviceType.mobile ? 8 : 12,
                                  runSpacing: 4,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          size: deviceType == DeviceType.mobile
                                              ? 12
                                              : 15,
                                          color: colorScheme.onSurface
                                              .withOpacity(0.6),
                                        ),
                                        SizedBox(
                                            width:
                                            deviceType == DeviceType.mobile
                                                ? 4
                                                : 6),
                                        Text(
                                          formattedDate,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: colorScheme.onSurface
                                                .withOpacity(0.7),
                                            fontSize:
                                            deviceType == DeviceType.mobile
                                                ? 11
                                                : 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: deviceType == DeviceType.mobile
                                              ? 12
                                              : 15,
                                          color: colorScheme.onSurface
                                              .withOpacity(0.6),
                                        ),
                                        SizedBox(
                                            width:
                                            deviceType == DeviceType.mobile
                                                ? 4
                                                : 6),
                                        Text(
                                          formattedTime,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: colorScheme.onSurface
                                                .withOpacity(0.7),
                                            fontSize:
                                            deviceType == DeviceType.mobile
                                                ? 11
                                                : 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, DeviceType deviceType,
      ThemeData theme, ColorScheme colorScheme) {
    final iconSize = deviceType == DeviceType.mobile ? 56.0 : 80.0;
    final titleFontSize = deviceType == DeviceType.mobile ? 20.0 : 28.0;
    final subtitleFontSize = deviceType == DeviceType.mobile ? 13.0 : 16.0;

    return Center(
      child: Padding(
        padding: _getResponsivePadding(deviceType),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: EdgeInsets.all(
                        deviceType == DeviceType.mobile ? 28 : 40),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.secondaryOrange.withOpacity(0.2),
                          AppColors.primaryBlue.withOpacity(0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.event_busy_rounded,
                      color: AppColors.secondaryOrange,
                      size: iconSize,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: deviceType == DeviceType.mobile ? 20 : 32),
            Text(
              "No Records Yet",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: titleFontSize,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: deviceType == DeviceType.mobile ? 8 : 12),
            Text(
              "Your attendance history will appear here",
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: subtitleFontSize,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message,
      DeviceType deviceType, ThemeData theme) {
    final padding = deviceType == DeviceType.mobile ? 24.0 : 40.0;
    final iconSize = deviceType == DeviceType.mobile ? 40.0 : 64.0;
    final titleFontSize = deviceType == DeviceType.mobile ? 18.0 : 24.0;
    final messageFontSize = deviceType == DeviceType.mobile ? 13.0 : 16.0;

    return Center(
      child: Container(
        padding: EdgeInsets.all(padding),
        margin: _getResponsivePadding(deviceType),
        constraints: BoxConstraints(
          maxWidth: deviceType == DeviceType.desktop ? 500 : double.infinity,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(deviceType == DeviceType.mobile ? 20 : 28),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentRed.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
              EdgeInsets.all(deviceType == DeviceType.mobile ? 14 : 20),
              decoration: BoxDecoration(
                color: AppColors.accentRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: iconSize,
                color: AppColors.accentRed,
              ),
            ),
            SizedBox(height: deviceType == DeviceType.mobile ? 16 : 24),
            Text(
              "Oops!",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: titleFontSize,
              ),
            ),
            SizedBox(height: deviceType == DeviceType.mobile ? 8 : 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.accentRed.withOpacity(0.8),
                fontSize: messageFontSize,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(
      BuildContext context, AttendanceCubit cubit, DeviceType deviceType) {
    final iconSize = deviceType == DeviceType.mobile ? 20.0 : 24.0;
    final fontSize = deviceType == DeviceType.mobile ? 14.0 : 16.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: FloatingActionButton.extended(
            onPressed: () async {
              final loginData = await AuthService.getLoginData();
              final email = loginData['email'] ?? '';
              final savedStudentId = loginData['studentId'];

              String? id;
              if (savedStudentId != null && savedStudentId.isNotEmpty) {
                id = savedStudentId;
              } else if (email.isNotEmpty) {
                id = StudentUtils.getStudentIdFromEmail(email);
              }

              if (id != null && id.isNotEmpty) {
                cubit.fetchStudentAttendance(id);
              }
            },
            backgroundColor: AppColors.secondaryOrange,
            elevation: 12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  deviceType == DeviceType.mobile ? 16 : 20),
            ),
            icon: Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: iconSize,
            ),
            label: Text(
              "Refresh",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: fontSize,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      },
    );
  }
}

enum DeviceType {
  mobile,
  largeMobile,
  tablet,
  desktop,
}
