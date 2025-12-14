// Replace your current dashboard__buildCoursesList.dart with this

import 'package:flutter/material.dart';
import '../../../shared/utils/app_colors.dart';

class CoursesList extends StatelessWidget {
  final List<Map<String, dynamic>> courses;

  const CoursesList({
    super.key,
    required this.courses,
  });

  @override
  Widget build(BuildContext context) {
    print('\n📚 CoursesList Widget - Building with ${courses.length} courses');

    if (courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No courses found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];

        print('\n--- Building CourseCard $index ---');
        print('Full course data: $course');

        // Extract data with null safety - CORRECTED PATH
        final lectureCourseOffering = course['lecturecourseoffering'] as Map<String, dynamic>?;
        print('lecturecourseoffering: $lectureCourseOffering');

        final courseData = lectureCourseOffering?['course'] as Map<String, dynamic>?;
        print('course data: $courseData');

        final courseName = courseData?['coursename']?.toString() ?? 'Unknown Course';
        final courseCode = courseData?['coursecode']?.toString() ?? 'N/A';
        final credits = courseData?['credithours'] as int? ?? 0;
        final semester = lectureCourseOffering?['semester']?.toString() ?? 'N/A';
        final year = lectureCourseOffering?['academicyear']?.toString() ?? 'N/A';
        final hasLabValue = courseData?['haslab']?.toString().toUpperCase();
        final hasLab = hasLabValue == 'YES';

        print('📝 Extracted values:');
        print('  Code: $courseCode');
        print('  Name: $courseName');
        print('  Credits: $credits');
        print('  Semester: $semester');
        print('  Year: $year');
        print('  Has Lab: $hasLab');

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                print('🔔 Tapped on course: $courseCode - $courseName');
                // TODO: Navigate to course details page
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Course Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.book_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Course Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Course Code
                          Text(
                            courseCode,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Course Name
                          Text(
                            courseName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2C3E50),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),

                          // Semester & Credits Info
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: AppColors.primaryBlue.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$semester $year',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF34495E),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.school_rounded,
                                size: 14,
                                color: AppColors.primaryBlue.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$credits Credits',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF34495E),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Lab Badge & Arrow
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (hasLab)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.secondaryOrange,
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              'Lab',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondaryOrange,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.primaryBlue.withOpacity(0.5),
                          size: 24,
                        ),
                      ],
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