import 'package:flutter/material.dart';

import '../../../auth/screens/welcome_screen.dart';
import '../../../services/auth_service.dart';
import '../../../shared/utils/app_colors.dart';
import '../../../shared/utils/page_transitions.dart';
import '../../../shared/widgets/theme_toggle_button.dart';

/// Modern, theme-aware custom app bar for the Teacher module.
///
/// Features:
/// - Gradient accent styling (matches Student theme)
/// - Theme toggle button integration
/// - Smooth animations
/// - Modern design with AppColors
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showThemeToggle;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool centerTitle;
  final double elevation;

  const CustomAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.showThemeToggle = true,
    this.showBackButton = true,
    this.onBackPressed,
    this.centerTitle = false,
    this.elevation = 0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              // Leading / Back Button
              if (leading != null)
                leading!
              else if (showBackButton)
                _buildBackButton(context, isDark),

              const SizedBox(width: 8),

              // Title
              Expanded(
                child: _buildTitle(theme, colorScheme),
              ),

              // Actions
              ..._buildActions(context, colorScheme, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onBackPressed ?? () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(10),
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
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primaryBlue,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(ThemeData theme, ColorScheme colorScheme) {
    return Row(
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
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActions(
      BuildContext context, ColorScheme colorScheme, bool isDark) {
    final List<Widget> allActions = [];

    // Add custom actions first
    if (actions != null) {
      allActions.addAll(actions!);
    }

    // Add logout icon button
    allActions.add(
      Container(
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.secondaryOrange.withOpacity(isDark ? 0.2 : 0.1),
              AppColors.secondaryOrange.withOpacity(isDark ? 0.15 : 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.secondaryOrange.withOpacity(0.3),
          ),
        ),
        child: IconButton(
          onPressed: () => _showLogoutDialog(context, isDark),
          icon: const Icon(Icons.logout_rounded),
          color: AppColors.secondaryOrange,
          iconSize: 20,
          tooltip: 'Logout',
        ),
      ),
    );

    // Add theme toggle button
    if (showThemeToggle) {
      allActions.add(
        Container(
          margin: const EdgeInsets.only(right: 4),
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
      );
    }

    return allActions;
  }

  void _showLogoutDialog(BuildContext context, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;

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
                  color:
                      AppColors.secondaryOrange.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: AppColors.secondaryOrange,
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
              onPressed: () async {
                Navigator.pop(dialogContext);
                await AuthService.clearLoginSession();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    FadePageRoute(page: const WelcomeScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryOrange,
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
}

/// Enhanced app bar with gradient header for special screens
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const GradientAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(90);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (showBackButton)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: onBackPressed ?? () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (actions != null) ...actions!,
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const ThemeToggleButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
