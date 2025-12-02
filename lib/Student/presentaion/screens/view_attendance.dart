import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../blocs/attendace_bloc/attendance_cubit.dart';
import '../../../shared/utils/app_colors.dart';
import '../../../shared/widgets/animated_gradient_background.dart';
import '../../../shared/widgets/hover_scale_widget.dart';
import '../../../shared/widgets/loading_animation.dart';
import '../../../services/auth_service.dart';
import '../../../shared/utils/student_utils.dart';

class AttendanceHistoryScreen extends StatelessWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AttendanceCubit>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.secondaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.event_available_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Attendance',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: BlocBuilder<AttendanceCubit, AttendanceState>(
            builder: (context, state) {
              if (state is AttendanceLoading) {
                return Center(
                  child: LoadingAnimation(
                    color: AppColors.primaryBlue,
                    size: 50,
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
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: AppColors.secondaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.event_busy_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "No attendance records found.",
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
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

                // Group by date
                final recordsByDate = <String, List>{};
                for (var record in records) {
                  final date = DateFormat('yyyy-MM-dd')
                      .format(record.scanTime.toLocal());
                  if (!recordsByDate.containsKey(date)) {
                    recordsByDate[date] = [];
                  }
                  recordsByDate[date]!.add(record);
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Statistics Cards
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
                            ),
                          ),
                          const SizedBox(width: 16),
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
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Attendance Rate Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Attendance Rate",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "${attendanceRate.toStringAsFixed(1)}%",
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  "${records.length}",
                                  style:
                                      theme.textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Attendance Chart
                      Container(
                        height: 250,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
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
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.secondaryGradient,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.trending_up_rounded,
                                      color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Attendance Trend",
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 50,
                                  sections: [
                                    PieChartSectionData(
                                      value: presentCount.toDouble(),
                                      title:
                                          '${((presentCount / records.length) * 100).toStringAsFixed(1)}%',
                                      color: AppColors.accentGreen,
                                      radius: 50,
                                      titleStyle: const TextStyle(
                                        fontSize: 14,
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
                                      radius: 50,
                                      titleStyle: const TextStyle(
                                        fontSize: 14,
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
                      const SizedBox(height: 24),
                      // Section Title
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Recent Records',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Records List
                      ...records.take(10).map((r) {
                        final formattedTime =
                            DateFormat('MMM dd, yyyy • hh:mm a')
                                .format(r.scanTime.toLocal());
                        final isPresent = r.status.toLowerCase() == 'present';
                        final index = records.indexOf(r);

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
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isPresent
                                            ? AppColors.accentGreen
                                                .withOpacity(0.2)
                                            : AppColors.accentRed
                                                .withOpacity(0.2),
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
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: isPresent
                                                  ? [
                                                      AppColors.accentGreen,
                                                      AppColors.accentGreen
                                                          .withOpacity(0.7)
                                                    ]
                                                  : [
                                                      AppColors.accentRed,
                                                      AppColors.accentRed
                                                          .withOpacity(0.7)
                                                    ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Icon(
                                            isPresent
                                                ? Icons.check_circle_rounded
                                                : Icons.cancel_rounded,
                                            color: Colors.white,
                                            size: 32,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Session: ${r.instanceId}",
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.access_time_rounded,
                                                    size: 14,
                                                    color: colorScheme.onSurface
                                                        .withOpacity(0.6),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    formattedTime,
                                                    style: theme
                                                        .textTheme.bodySmall
                                                        ?.copyWith(
                                                      color: colorScheme
                                                          .onSurface
                                                          .withOpacity(0.6),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isPresent
                                                ? AppColors.accentGreen
                                                    .withOpacity(0.1)
                                                : AppColors.accentRed
                                                    .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            r.status,
                                            style: TextStyle(
                                              color: isPresent
                                                  ? AppColors.accentGreen
                                                  : AppColors.accentRed,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
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
                      }).toList(),
                    ],
                  ),
                );
              } else if (state is AttendanceError) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
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
                          size: 48,
                          color: AppColors.accentRed,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.accentRed,
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
        icon: const Icon(Icons.refresh_rounded, color: Colors.white),
        label: const Text(
          "Refresh",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
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
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
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
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
