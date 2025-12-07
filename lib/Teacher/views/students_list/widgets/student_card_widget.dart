import 'package:flutter/material.dart';

import '../../../models/student_entity.dart';

/// Student Card Widget - Modern, theme-aware student card.
///
/// Features:
/// - Avatar with initials
/// - Student info (name, major, level, GPA)
/// - Action buttons (view, edit, message)
/// - Theme-aware styling (light/dark mode)
class StudentCard extends StatelessWidget {
  final StudentEntity student;

  const StudentCard({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          _buildAvatar(colorScheme, isDark),
          const SizedBox(width: 14),

          // Student Info
          Expanded(
            child: _buildStudentInfo(colorScheme, isDark),
          ),

          // Action Buttons
          _buildActionButtons(colorScheme),
        ],
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme, bool isDark) {
    final name = student.fullName ?? student.studentCode;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStudentInfo(ColorScheme colorScheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name
        Text(
          student.fullName ?? student.studentCode,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: colorScheme.onSurface,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),

        // Major and Level Row
        Row(
          children: [
            // Major Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                student.major,
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Level
            Text(
              student.academicLevel,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // GPA
        Row(
          children: [
            Icon(
              Icons.stars_rounded,
              size: 14,
              color: colorScheme.secondary,
            ),
            const SizedBox(width: 4),
            Text(
              'GPA: ${student.currentGpa.toStringAsFixed(2)}',
              style: TextStyle(
                color: colorScheme.secondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: Icons.visibility_rounded,
          color: colorScheme.primary,
          onPressed: () {
            // TODO: Navigate to student details
          },
          tooltip: 'View Details',
        ),
        _buildActionButton(
          icon: Icons.edit_rounded,
          color: colorScheme.secondary,
          onPressed: () {
            // TODO: Edit student
          },
          tooltip: 'Edit',
        ),
        _buildActionButton(
          icon: Icons.message_rounded,
          color: Colors.blue,
          onPressed: () {
            // TODO: Message student
          },
          tooltip: 'Message',
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}
