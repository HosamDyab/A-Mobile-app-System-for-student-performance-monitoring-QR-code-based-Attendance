import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/screens/welcome_screen.dart';
import '../../services/auth_service.dart';
import '../../shared/utils/app_colors.dart';
import '../../shared/utils/page_transitions.dart';
import '../../shared/widgets/theme_toggle_button.dart';
import '../viewmodels/teacher_assistant/teacher_assistant_cubit.dart';
import '../views/manual_attendance/manual_attendance_screen.dart';
import '../views/manual_grades/manual_grade_entry_screen.dart';
import '../views/teacher_assistants/teacher_assistant_list_screen.dart';
import '../widgets/profile_header_widget.dart';

/// Teacher Profile Screen - Enhanced with Student theme colors.
///
/// Features:
/// - Profile header with avatar and info
/// - Quick action cards with AppColors gradients
/// - Theme toggle button
/// - Modern, theme-aware design
/// - Logout functionality
class TeacherProfileScreen extends StatelessWidget {
  final String facultyName;
  final String facultyEmail;
  final String role;
  final String facultyId;

  const TeacherProfileScreen({
    super.key,
    required this.facultyName,
    required this.facultyEmail,
    required this.role,
    required this.facultyId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
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
              'Profile',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          // Theme Toggle Button
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue.withOpacity(isDark ? 0.2 : 0.1),
                  AppColors.accentPurple.withOpacity(isDark ? 0.15 : 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(0.2),
              ),
            ),
            child: const ThemeToggleButton(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Profile Header with image upload
            ProfileHeaderWidget(
              facultyName: facultyName,
              facultyEmail: facultyEmail,
              role: role,
              facultyId: facultyId,
            ),
            const SizedBox(height: 36),

            // Quick Actions Section
            _buildSectionTitle('Quick Actions', colorScheme),
            const SizedBox(height: 16),
            _buildQuickActionsGrid(context, colorScheme, isDark),
            const SizedBox(height: 32),

            // Settings Section
            _buildSectionTitle('Settings', colorScheme),
            const SizedBox(height: 16),
            _buildSettingsCard(context, colorScheme, isDark),
            const SizedBox(height: 32),

            // Logout Button
            _buildLogoutButton(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme colorScheme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
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
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(
      BuildContext context, ColorScheme colorScheme, bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.25,
      children: [
        _buildActionCard(
          context: context,
          icon: Icons.edit_calendar_rounded,
          title: 'Manual\nAttendance',
          gradient: LinearGradient(
            colors: [
              AppColors.primaryBlue.withOpacity(isDark ? 0.25 : 0.12),
              AppColors.accentPurple.withOpacity(isDark ? 0.15 : 0.08),
            ],
          ),
          iconColor: AppColors.primaryBlue,
          isDark: isDark,
          onTap: () => _navigateToManualAttendance(context),
        ),
        _buildActionCard(
          context: context,
          icon: Icons.grade_rounded,
          title: 'Manual\nGrades',
          gradient: LinearGradient(
            colors: [
              AppColors.secondaryBlue.withOpacity(isDark ? 0.25 : 0.12),
              AppColors.accentCyan.withOpacity(isDark ? 0.15 : 0.08),
            ],
          ),
          iconColor: AppColors.secondaryBlue,
          isDark: isDark,
          onTap: () => _navigateToManualGrades(context),
        ),
        if (role == 'faculty')
          _buildActionCard(
            context: context,
            icon: Icons.supervisor_account_rounded,
            title: 'Teacher\nAssistants',
            gradient: LinearGradient(
              colors: [
                AppColors.accentPurple.withOpacity(isDark ? 0.25 : 0.12),
                AppColors.accentCyan.withOpacity(isDark ? 0.15 : 0.08),
              ],
            ),
            iconColor: AppColors.accentPurple,
            isDark: isDark,
            onTap: () => _navigateToTeacherAssistants(context),
          ),
        _buildActionCard(
          context: context,
          icon: Icons.analytics_rounded,
          title: 'Statistics',
          gradient: LinearGradient(
            colors: [
              AppColors.accentGreen.withOpacity(isDark ? 0.25 : 0.12),
              AppColors.accentCyan.withOpacity(isDark ? 0.15 : 0.08),
            ],
          ),
          iconColor: AppColors.accentGreen,
          isDark: isDark,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    const Text('Statistics coming soon!'),
                  ],
                ),
                backgroundColor: AppColors.primaryBlue,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Gradient gradient,
    required Color iconColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: iconColor.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: iconColor.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(isDark ? 0.3 : 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: iconColor,
                  height: 1.2,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
      BuildContext context, ColorScheme colorScheme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(22),
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
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.notifications_rounded,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            color: AppColors.secondaryBlue,
            colorScheme: colorScheme,
            isDark: isDark,
            onTap: () {},
          ),
          Divider(
            height: 1,
            color: colorScheme.outline.withOpacity(0.15),
            indent: 70,
          ),
          _buildSettingsTile(
            icon: Icons.security_rounded,
            title: 'Privacy & Security',
            subtitle: 'Manage your account security',
            color: AppColors.primaryBlue,
            colorScheme: colorScheme,
            isDark: isDark,
            onTap: () {},
          ),
          Divider(
            height: 1,
            color: colorScheme.outline.withOpacity(0.15),
            indent: 70,
          ),
          _buildSettingsTile(
            icon: Icons.help_outline_rounded,
            title: 'Help & Support',
            subtitle: 'Get help or contact support',
            color: AppColors.accentGreen,
            colorScheme: colorScheme,
            isDark: isDark,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required ColorScheme colorScheme,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.chevron_right_rounded,
          color: colorScheme.onSurface.withOpacity(0.5),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryOrange.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutDialog(context),
        icon: const Icon(Icons.logout_rounded),
        label: const Text(
          'Logout',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryOrange, // Orange like student
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  void _navigateToManualAttendance(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManualAttendanceScreen(
          facultyId: facultyId,
          role: role,
        ),
      ),
    );
  }

  void _navigateToManualGrades(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManualGradeEntryScreen(
          facultyId: facultyId,
          role: role,
        ),
      ),
    );
  }

  void _navigateToTeacherAssistants(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<TeacherAssistantCubit>(),
          child: TeacherAssistantListScreen(
          //  facultyId: role == 'faculty' ? facultyId : null,
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          backgroundColor: colorScheme.surface,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentRed.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: AppColors.accentRed,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              fontSize: 15,
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _handleLogout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentRed,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await AuthService.clearLoginSession();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        FadePageRoute(page: const WelcomeScreen()),
        (route) => false,
      );
    }
  }
}
