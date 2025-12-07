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
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AttendanceCubit>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    final isDesktop = size.width >= 1024;
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
      onPopInvokedWithResult: (didPop, result) {
        // Prevent back navigation - stay in app
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 10 : 8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.event_available_rounded,
                  color: Colors.white,
                  size: isTablet ? 24 : 20,
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Text(
                'Attendance',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: isTablet ? 28 : null,
                ),
              ),
            ],
          ),
          centerTitle: false,
          actions: const [
            ThemeToggleButton(),
          ],
        ),
        body: AnimatedGradientBackground(
          child: SafeArea(
            child: BlocBuilder<AttendanceCubit, AttendanceState>(
              builder: (context, state) {
                if (state is AttendanceLoading) {
                  return Center(
                    child: LoadingAnimation(
                      color: AppColors.primaryBlue,
                      size: isTablet ? 70 : 50,
                    ),
                  );
                } else if (state is AttendanceLoaded) {
                  final records = state.attendances;

                  if (records.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(isTablet ? 32 : 24),
                            decoration: BoxDecoration(
                              gradient: AppColors.secondaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.event_busy_rounded,
                              color: Colors.white,
                              size: isTablet ? 64 : 48,
                            ),
                          ),
                          SizedBox(height: isTablet ? 32 : 24),
                          Text(
                            "No attendance records found.",
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                              fontSize: isTablet ? 24 : null,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Calculate statistics
                  final presentCount = records
                      .where((r) => r.status.toLowerCase() == 'present')
                      .length;
                  final absentCount = records.length - presentCount;
                  final attendanceRate = records.isEmpty
                      ? 0.0
                      : (presentCount / records.length) * 100;

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(isDesktop ? 40 : isTablet ? 28 : 20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isDesktop ? 1200 : double.infinity,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Statistics Section
                            LayoutBuilder(
                              builder: (context, constraints) {
                                if (isDesktop) {
                                  // Desktop: 3 columns
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatCard(
                                          context: context,
                                          icon: Icons.check_circle_rounded,
                                          title: "Present",
                                          value: presentCount.toString(),
                                          color: AppColors.accentGreen,
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.accentGreen,
                                              AppColors.accentGreen.withOpacity(0.7)
                                            ],
                                          ),
                                          isTablet: isTablet,
                                        ),
                                      ),
                                      SizedBox(width: isTablet ? 20 : 16),
                                      Expanded(
                                        child: _buildStatCard(
                                          context: context,
                                          icon: Icons.cancel_rounded,
                                          title: "Absent",
                                          value: absentCount.toString(),
                                          color: AppColors.accentRed,
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.accentRed,
                                              AppColors.accentRed.withOpacity(0.7)
                                            ],
                                          ),
                                          isTablet: isTablet,
                                        ),
                                      ),
                                      SizedBox(width: isTablet ? 20 : 16),
                                      Expanded(
                                        child: _buildAttendanceRateCard(
                                          context: context,
                                          attendanceRate: attendanceRate,
                                          totalRecords: records.length,
                                          isTablet: isTablet,
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  // Mobile/Tablet: 2 columns + full width rate
                                  return Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildStatCard(
                                              context: context,
                                              icon: Icons.check_circle_rounded,
                                              title: "Present",
                                              value: presentCount.toString(),
                                              color: AppColors.accentGreen,
                                              gradient: LinearGradient(
                                                colors: [
                                                  AppColors.accentGreen,
                                                  AppColors.accentGreen.withOpacity(0.7)
                                                ],
                                              ),
                                              isTablet: isTablet,
                                            ),
                                          ),
                                          SizedBox(width: isTablet ? 20 : 16),
                                          Expanded(
                                            child: _buildStatCard(
                                              context: context,
                                              icon: Icons.cancel_rounded,
                                              title: "Absent",
                                              value: absentCount.toString(),
                                              color: AppColors.accentRed,
                                              gradient: LinearGradient(
                                                colors: [
                                                  AppColors.accentRed,
                                                  AppColors.accentRed.withOpacity(0.7)
                                                ],
                                              ),
                                              isTablet: isTablet,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: isTablet ? 20 : 16),
                                      _buildAttendanceRateCard(
                                        context: context,
                                        attendanceRate: attendanceRate,
                                        totalRecords: records.length,
                                        isTablet: isTablet,
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                            SizedBox(height: isTablet ? 32 : 24),

                            // Chart Section
                            Container(
                              height: isDesktop ? 350 : isTablet ? 300 : 250,
                              padding: EdgeInsets.all(isTablet ? 28 : 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryBlue.withOpacity(0.1),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(isTablet ? 10 : 8),
                                        decoration: BoxDecoration(
                                          gradient: AppColors.secondaryGradient,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.trending_up_rounded,
                                          color: Colors.white,
                                          size: isTablet ? 24 : 20,
                                        ),
                                      ),
                                      SizedBox(width: isTablet ? 16 : 12),
                                      Text(
                                        "Attendance Trend",
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: isTablet ? 24 : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isTablet ? 28 : 20),
                                  Expanded(
                                    child: PieChart(
                                      PieChartData(
                                        sectionsSpace: 2,
                                        centerSpaceRadius: isDesktop ? 70 : isTablet ? 60 : 50,
                                        sections: [
                                          PieChartSectionData(
                                            value: presentCount.toDouble(),
                                            title: '${((presentCount / records.length) * 100).toStringAsFixed(1)}%',
                                            color: AppColors.accentGreen,
                                            radius: isDesktop ? 70 : isTablet ? 60 : 50,
                                            titleStyle: TextStyle(
                                              fontSize: isTablet ? 16 : 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          PieChartSectionData(
                                            value: absentCount.toDouble(),
                                            title: absentCount > 0
                                                ? '${((absentCount / records.length) * 100).toStringAsFixed(1)}%'
                                                : '',
                                            color: AppColors.accentRed,
                                            radius: isDesktop ? 70 : isTablet ? 60 : 50,
                                            titleStyle: TextStyle(
                                              fontSize: isTablet ? 16 : 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: isTablet ? 32 : 24),

                            // Section Title
                            Row(
                              children: [
                                Container(
                                  width: isTablet ? 5 : 4,
                                  height: isTablet ? 28 : 24,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                SizedBox(width: isTablet ? 16 : 12),
                                Text(
                                  'Recent Records',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: isTablet ? 26 : null,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isTablet ? 20 : 16),

                            // Records List (Grid on desktop/tablet)
                            if (isTablet)
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isDesktop ? 2 : 1,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 20,
                                  childAspectRatio: isDesktop ? 3.5 : 4,
                                ),
                                itemCount: records.length > 10 ? 10 : records.length,
                                itemBuilder: (context, index) {
                                  final r = records[index];
                                  return _buildAttendanceCard(
                                    context: context,
                                    record: r,
                                    index: index,
                                    theme: theme,
                                    colorScheme: colorScheme,
                                    isTablet: isTablet,
                                  );
                                },
                              )
                            else
                              ...records.take(10).map((r) {
                                final index = records.indexOf(r);
                                return _buildAttendanceCard(
                                  context: context,
                                  record: r,
                                  index: index,
                                  theme: theme,
                                  colorScheme: colorScheme,
                                  isTablet: isTablet,
                                );
                              }),
                          ],
                        ),
                      ),
                    ),
                  );
                } else if (state is AttendanceError) {
                  return Center(
                    child: Container(
                      padding: EdgeInsets.all(isTablet ? 32 : 24),
                      margin: EdgeInsets.all(isTablet ? 28 : 20),
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 500 : double.infinity,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accentRed.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: isTablet ? 64 : 48,
                            color: AppColors.accentRed,
                          ),
                          SizedBox(height: isTablet ? 20 : 16),
                          Text(
                            state.message,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.accentRed,
                              fontSize: isTablet ? 20 : null,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Center(
                    child: Text(
                      "Load attendance data...",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontSize: isTablet ? 20 : null,
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
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
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Icon(
            Icons.refresh_rounded,
            color: Colors.white,
            size: isTablet ? 24 : 20,
          ),
          label: Text(
            "Refresh",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: isTablet ? 16 : 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Gradient gradient,
    required bool isTablet,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: isTablet ? 32 : 28),
          SizedBox(height: isTablet ? 16 : 12),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontSize: isTablet ? 16 : null,
            ),
          ),
          SizedBox(height: isTablet ? 6 : 4),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: isTablet ? 36 : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceRateCard({
    required BuildContext context,
    required double attendanceRate,
    required int totalRecords,
    required bool isTablet,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Attendance Rate",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isTablet ? 18 : null,
                  ),
                ),
                SizedBox(height: isTablet ? 12 : 8),
                Text(
                  "${attendanceRate.toStringAsFixed(1)}%",
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: isTablet ? 48 : null,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: isTablet ? 100 : 80,
            height: isTablet ? 100 : 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                "$totalRecords",
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 32 : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard({
    required BuildContext context,
    required dynamic record,
    required int index,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required bool isTablet,
  }) {
    final formattedTime = DateFormat('MMM dd, yyyy • hh:mm a')
        .format(record.scanTime.toLocal());
    final isPresent = record.status.toLowerCase() == 'present';

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
                margin: EdgeInsets.only(bottom: isTablet ? 20 : 16),
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
                  border: Border.all(
                    color: isPresent
                        ? AppColors.accentGreen.withOpacity(0.2)
                        : AppColors.accentRed.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isPresent
                          ? AppColors.accentGreen
                          : AppColors.accentRed)
                          .withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: isTablet ? 70 : 60,
                      height: isTablet ? 70 : 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
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
                        borderRadius: BorderRadius.circular(isTablet ? 18 : 16),
                      ),
                      child: Icon(
                        isPresent
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: Colors.white,
                        size: isTablet ? 36 : 32,
                      ),
                    ),
                    SizedBox(width: isTablet ? 20 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Session: ${record.instanceId}",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: isTablet ? 18 : null,
                            ),
                          ),
                          SizedBox(height: isTablet ? 6 : 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: isTablet ? 16 : 14,
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                              SizedBox(width: isTablet ? 6 : 4),
                              Flexible(
                                child: Text(
                                  formattedTime,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(0.6),
                                    fontSize: isTablet ? 14 : null,
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
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 16 : 12,
                        vertical: isTablet ? 8 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: isPresent
                            ? AppColors.accentGreen.withOpacity(0.1)
                            : AppColors.accentRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        record.status,
                        style: TextStyle(
                          color: isPresent
                              ? AppColors.accentGreen
                              : AppColors.accentRed,
                          fontWeight: FontWeight.bold,
                          fontSize: isTablet ? 14 : 12,
                        ),
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
}