// Replace your current dashbourd_buildScoreChart.dart with this

import 'package:flutter/material.dart';
import '../../../shared/utils/app_colors.dart';

class ScoreChart extends StatelessWidget {
  final List<Map<String, dynamic>> courses;

  const ScoreChart({
    super.key,
    required this.courses,
  });

  @override
  Widget build(BuildContext context) {
    print('\n📊 ScoreChart Widget - Building with ${courses.length} courses');

    if (courses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFDFE6ED),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFDFE6ED).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                'No score data available',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFDFE6ED),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDFE6ED).withOpacity(0.4),
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
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Course Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Course Bars
          ...courses.asMap().entries.map((entry) {
            final index = entry.key;
            final course = entry.value;

            print('\n--- Building Chart Bar $index ---');

            // Extract data with proper null safety - CORRECTED PATH
            final lectureCourseOffering = course['lecturecourseoffering'] as Map<String, dynamic>?;
            final courseData = lectureCourseOffering?['course'] as Map<String, dynamic>?;

            final courseName = courseData?['coursename']?.toString() ?? 'Unknown';
            final courseCode = courseData?['coursecode']?.toString() ?? 'N/A';
            final credits = courseData?['credithours'] as int? ?? 0;

            print('📊 Chart - Code: $courseCode, Name: $courseName, Credits: $credits');

            // Generate mock score (TODO: Replace with real data from evaluationsheet)
            final mockScore = 75 + (index * 10) % 25;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              courseCode,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              courseName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C3E50),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: _getGradientForScore(mockScore),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: _getColorForScore(mockScore).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '$mockScore%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: mockScore / 100,
                      minHeight: 10,
                      backgroundColor: Colors.white.withOpacity(0.5),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getColorForScore(mockScore),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Scores are updated after each evaluation',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF2C3E50).withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForScore(int score) {
    if (score >= 85) return Colors.green.shade600;
    if (score >= 70) return AppColors.primaryBlue;
    if (score >= 60) return AppColors.secondaryOrange;
    return AppColors.accentRed;
  }

  LinearGradient _getGradientForScore(int score) {
    if (score >= 85) {
      return LinearGradient(
        colors: [Colors.green.shade600, Colors.green.shade400],
      );
    }
    if (score >= 70) {
      return AppColors.primaryGradient;
    }
    if (score >= 60) {
      return AppColors.secondaryGradient;
    }
    return LinearGradient(
      colors: [AppColors.accentRed, AppColors.accentRed.withOpacity(0.8)],
    );
  }
}