import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';

import '../blocs/SearchCuit.dart';
import 'course_details_page.dart';
import '../../../shared/utils/app_colors.dart';
import '../../../shared/utils/page_transitions.dart';
import '../../../shared/widgets/animated_gradient_background.dart';
import '../../../shared/widgets/hover_scale_widget.dart';
import '../../../shared/widgets/loading_animation.dart';

class CourseSearchPage extends StatefulWidget {
  const CourseSearchPage({super.key});

  @override
  State<CourseSearchPage> createState() => _CourseSearchPageState();
}

class _CourseSearchPageState extends State<CourseSearchPage> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    context.read<StudentSearchCubit>().loadAllCourses();
  }

  void _onChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final query = _controller.text.trim();
      context.read<StudentSearchCubit>().filterCourses(query);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Map<String, int> _calculateGradeDistribution(List courses) {
    final distribution = <String, int>{};
    for (var course in courses) {
      final grade = course.letterGrade ?? 'N/A';
      distribution[grade] = (distribution[grade] ?? 0) + 1;
    }
    return distribution;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.search_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              "My Courses",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: AnimatedGradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Modern Search Field
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: Opacity(
                        opacity: value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFDFE6ED),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFDFE6ED).withOpacity(0.6),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _controller,
                            style: theme.textTheme.bodyLarge,
                            decoration: InputDecoration(
                              hintText: "Search by course name or code...",
                              hintStyle: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                              prefixIcon: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    bottomLeft: Radius.circular(20),
                                  ),
                                ),
                                child: const Icon(Icons.search_rounded,
                                    color: Colors.white, size: 22),
                              ),
                              suffixIcon: _controller.text.isNotEmpty
                                  ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _controller.clear();
                                  context
                                      .read<StudentSearchCubit>()
                                      .filterCourses('');
                                },
                              )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFDFE6ED),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 18),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: BlocBuilder<StudentSearchCubit, StudentSearchState>(
                    builder: (context, state) {
                      // Loading State
                      if (state.isLoadingCourses && state.courses.isEmpty) {
                        return const Center(
                          child: LoadingAnimation(
                            color: AppColors.primaryBlue,
                            size: 50,
                          ),
                        );
                      }

                      // No Courses
                      if (!state.isLoadingCourses && state.courses.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.menu_book_rounded,
                                size: 64,
                                color: colorScheme.onSurface.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _controller.text.isEmpty
                                    ? "No courses enrolled"
                                    : "No matching courses found",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Courses Loaded
                      final gradeDistribution =
                      _calculateGradeDistribution(state.courses);
                      return Column(
                        children: [
                          // Grade Distribution Chart
                          Container(
                            height: 200,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDFE6ED),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFDFE6ED).withOpacity(0.6),
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
                                      child: const Icon(Icons.bar_chart_rounded,
                                          color: Colors.white, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      "Grade Distribution",
                                      style:
                                      theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF2C3E50),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Expanded(
                                  child: BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      maxY: gradeDistribution.values.isEmpty
                                          ? 5
                                          : (gradeDistribution.values
                                          .reduce((a, b) => a > b ? a : b)
                                          .toDouble() +
                                          2),
                                      barTouchData: BarTouchData(
                                        enabled: true,
                                        // touchTooltipData: BarTouchTooltipData(
                                        //   getTooltipColor: (group) => AppColors.primaryBlue,
                                        //   tooltipRoundedRadius: 8,
                                        // ),
                                      ),
                                      titlesData: FlTitlesData(
                                        show: true,
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, meta) {
                                              final grades =
                                              gradeDistribution.keys.toList();
                                              if (value.toInt() < grades.length) {
                                                return Padding(
                                                  padding: const EdgeInsets.only(
                                                      top: 8),
                                                  child: Text(
                                                    grades[value.toInt()],
                                                    style: const TextStyle(
                                                      color: AppColors.primaryBlue,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                );
                                              }
                                              return const Text('');
                                            },
                                          ),
                                        ),
                                        leftTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                        topTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                        rightTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                      ),
                                      gridData: const FlGridData(show: false),
                                      borderData: FlBorderData(show: false),
                                      barGroups: gradeDistribution.entries
                                          .map((entry) {
                                        final index = gradeDistribution.keys
                                            .toList()
                                            .indexOf(entry.key);
                                        return BarChartGroupData(
                                          x: index,
                                          barRods: [
                                            BarChartRodData(
                                              toY: entry.value.toDouble(),
                                              gradient: AppColors.primaryGradient,
                                              width: 24,
                                              borderRadius:
                                              const BorderRadius.vertical(
                                                  top: Radius.circular(8)),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Courses List
                          Expanded(
                            child: ListView.builder(
                              itemCount: state.courses.length,
                              itemBuilder: (context, index) {
                                final course = state.courses[index];
                                return TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: Duration(
                                      milliseconds: 400 + (index * 100)),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) {
                                    return Transform.translate(
                                      offset: Offset(0, 20 * (1 - value)),
                                      child: Opacity(
                                        opacity: value,
                                        child: HoverScaleWidget(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              AdvancedSlidePageRoute(
                                                page: CourseDetailsPage(
                                                    course: course),
                                                direction: SlideDirection.right,
                                              ),
                                            );
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 16),
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDFE6ED),
                                              borderRadius:
                                              BorderRadius.circular(20),
                                              border: Border.all(
                                                color: AppColors.primaryBlue
                                                    .withOpacity(0.2),
                                                width: 1.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFFDFE6ED)
                                                      .withOpacity(0.6),
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
                                                    gradient:
                                                    AppColors.primaryGradient,
                                                    borderRadius:
                                                    BorderRadius.circular(16),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      course.courseCode.isNotEmpty
                                                          ? course.courseCode[0]
                                                          .toUpperCase()
                                                          : '?',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 24,
                                                        fontWeight:
                                                        FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        course.courseCode,
                                                        style: theme.textTheme
                                                            .titleSmall
                                                            ?.copyWith(
                                                          fontWeight:
                                                          FontWeight.w700,
                                                          color: AppColors
                                                              .primaryBlue,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        course.courseName,
                                                        style: theme.textTheme
                                                            .titleMedium
                                                            ?.copyWith(
                                                          fontWeight:
                                                          FontWeight.w600,
                                                          color: const Color(
                                                              0xFF2C3E50),
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .calendar_today_rounded,
                                                            size: 14,
                                                            color: AppColors
                                                                .secondaryOrange,
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            '${course.semester} • ${course.academicYear}',
                                                            style: theme.textTheme
                                                                .bodySmall
                                                                ?.copyWith(
                                                              color: Colors
                                                                  .grey.shade700,
                                                            ),
                                                          ),
                                                          if (course.hasLab) ...[
                                                            const SizedBox(
                                                                width: 8),
                                                            Container(
                                                              padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                horizontal: 6,
                                                                vertical: 2,
                                                              ),
                                                              decoration:
                                                              BoxDecoration(
                                                                color: AppColors
                                                                    .accentGreen
                                                                    .withOpacity(
                                                                    0.2),
                                                                borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                    4),
                                                              ),
                                                              child: Text(
                                                                'Lab',
                                                                style: TextStyle(
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                                  color: AppColors
                                                                      .accentGreen,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (course.letterGrade != null)
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 16,
                                                        vertical: 8),
                                                    decoration: BoxDecoration(
                                                      gradient: AppColors
                                                          .secondaryGradient,
                                                      borderRadius:
                                                      BorderRadius.circular(
                                                          12),
                                                    ),
                                                    child: Text(
                                                      course.letterGrade!,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                        FontWeight.bold,
                                                        fontSize: 16,
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
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}