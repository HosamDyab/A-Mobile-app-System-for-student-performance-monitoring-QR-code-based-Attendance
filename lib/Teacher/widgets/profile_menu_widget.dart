import 'package:flutter/material.dart';

/// Profile Menu Widget - Popup menu with profile actions
///
/// Provides a clean popup menu with options for:
/// - Manual attendance entry
/// - Manual grade entry
/// - Teacher assistants management (faculty only)
/// - Logout
class ProfileMenuWidget extends StatelessWidget {
  final String facultyId;
  final String role;
  final VoidCallback onManualAttendance;
  final VoidCallback onManualGrades;
  final VoidCallback onTeacherAssistants;
  final VoidCallback onLogout;

  const ProfileMenuWidget({
    super.key,
    required this.facultyId,
    required this.role,
    required this.onManualAttendance,
    required this.onManualGrades,
    required this.onTeacherAssistants,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (value) {
        switch (value) {
          case 'manual_attendance':
            onManualAttendance();
            break;
          case 'manual_grades':
            onManualGrades();
            break;
          case 'tas':
            onTeacherAssistants();
            break;
          case 'logout':
            onLogout();
            break;
        }
      },
      itemBuilder: (context) => [
        // Manual Attendance
        PopupMenuItem(
          value: 'manual_attendance',
          child: _buildMenuItem(
            icon: Icons.edit_note,
            label: 'Manual Attendance',
            color: colorScheme.primary,
          ),
        ),

        // Manual Grades
        PopupMenuItem(
          value: 'manual_grades',
          child: _buildMenuItem(
            icon: Icons.grade,
            label: 'Manual Grade Entry',
            color: colorScheme.primary,
          ),
        ),

        // Divider
        const PopupMenuItem(
          enabled: false,
          child: Divider(),
        ),

        // Teacher Assistants (Faculty only)
        if (role == 'faculty')
          PopupMenuItem(
            value: 'tas',
            child: _buildMenuItem(
              icon: Icons.supervisor_account,
              label: 'My Teacher Assistants',
              color: colorScheme.secondary,
            ),
          ),

        // Logout
        PopupMenuItem(
          value: 'logout',
          child: _buildMenuItem(
            icon: Icons.logout,
            label: 'Logout',
            color: colorScheme.error,
          ),
        ),
      ],
    );
  }

  /// Builds a menu item with icon and label
  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

