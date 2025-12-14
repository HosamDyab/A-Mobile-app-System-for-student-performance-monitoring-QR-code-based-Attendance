// student_card_widget.dart

import 'package:flutter/material.dart';
import '../../../../shared/utils/app_colors.dart';
import '../../../models/student_entity.dart';

class StudentCard extends StatelessWidget {
  final StudentEntity student;

  const StudentCard({
    super.key,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to student details or show bottom sheet
            _showStudentDetails(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Avatar
                _buildAvatar(isDark),
                const SizedBox(width: 16),

                // Student Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        student.fullName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),

                      // Email
                      Text(
                        student.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Level, Major, ID
                      Row(
                        children: [
                          _buildInfoChip(
                            student.academicLevelString,
                            AppColors.primaryBlue,
                            isDark,
                          ),
                          const SizedBox(width: 8),
                          if (student.major != null)
                            _buildInfoChip(
                              student.major!,
                              AppColors.accentPurple,
                              isDark,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // GPA Badge
                _buildGpaBadge(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isDark) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withOpacity(isDark ? 0.3 : 0.2),
            AppColors.accentPurple.withOpacity(isDark ? 0.25 : 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          _getInitials(student.fullName),
          style: TextStyle(
            color: AppColors.primaryBlue,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildGpaBadge(bool isDark) {
    final gpa = student.currentGpa;
    final gpaText = gpa != null ? gpa.toStringAsFixed(2) : 'N/A';
    final gpaColor = _getGpaColor(gpa);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: gpaColor.withOpacity(isDark ? 0.2 : 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: gpaColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'GPA',
            style: TextStyle(
              fontSize: 10,
              color: gpaColor.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            gpaText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: gpaColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getGpaColor(double? gpa) {
    if (gpa == null) return AppColors.tertiaryLightGray;
    if (gpa >= 3.5) return AppColors.accentGreen;
    if (gpa >= 3.0) return AppColors.primaryBlue;
    if (gpa >= 2.5) return AppColors.secondaryBlue;
    return AppColors.accentRed;
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return '${parts[0].substring(0, 1)}${parts[parts.length - 1].substring(0, 1)}'.toUpperCase();
  }

  void _showStudentDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Student Name
            Text(
              student.fullName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),

            // Email
            Row(
              children: [
                Icon(Icons.email_outlined,
                    size: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6)),
                const SizedBox(width: 8),
                Text(
                  student.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Details Grid
            _buildDetailRow('Student ID', student.studentId, context),
            const SizedBox(height: 12),
            _buildDetailRow(
                'Level', student.academicLevelString, context),
            const SizedBox(height: 12),
            if (student.major != null)
              _buildDetailRow('Major', student.major!, context),
            if (student.major != null) const SizedBox(height: 12),
            _buildDetailRow(
              'GPA',
              student.currentGpa?.toStringAsFixed(2) ?? 'N/A',
              context,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Credits Earned',
              '${student.totalCreditHoursEarned} hrs',
              context,
            ),
            if (student.entryYear != null) const SizedBox(height: 12),
            if (student.entryYear != null)
              _buildDetailRow('Entry Year', student.entryYear!, context),
            const SizedBox(height: 24),

            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color:
            Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}