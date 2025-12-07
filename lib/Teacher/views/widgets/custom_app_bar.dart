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
/// - Fully responsive and adaptive
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
    final size = MediaQuery.of(context).size;

    // Responsive breakpoints
    final isSmallScreen = size.width < 360;
    final isCompact = size.width < 400;

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
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 4 : 8,
            vertical: 8,
          ),
          child: Row(
            children: [
              // Leading / Back Button
              if (leading != null)
                leading!
              else if (showBackButton)
                _buildBackButton(context, isDark, isCompact),

              SizedBox(width: isCompact ? 4 : 8),

              // Title
              Expanded(
                child: _buildTitle(theme, colorScheme, isSmallScreen, isCompact),
              ),

              // Actions
              ..._buildActions(context, colorScheme, isDark, isSmallScreen, isCompact),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context, bool isDark, bool isCompact) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onBackPressed ?? () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
        child: Container(
          padding: EdgeInsets.all(isCompact ? 8 : 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryBlue.withOpacity(isDark ? 0.2 : 0.1),
                AppColors.accentPurple.withOpacity(isDark ? 0.15 : 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
            border: Border.all(
              color: AppColors.primaryBlue.withOpacity(0.2),
            ),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primaryBlue,
            size: isCompact ? 18 : 20,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(ThemeData theme, ColorScheme colorScheme, bool isSmallScreen, bool isCompact) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isCompact ? 3 : 4,
          height: isSmallScreen ? 20 : 24,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: isCompact ? 8 : 12),
        Flexible(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              letterSpacing: -0.5,
              fontSize: isSmallScreen ? 16 : (isCompact ? 18 : 20),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActions(
      BuildContext context, ColorScheme colorScheme, bool isDark, bool isSmallScreen, bool isCompact) {
    final List<Widget> allActions = [];

    // Add custom actions first (with responsive sizing)
    if (actions != null) {
      allActions.addAll(actions!.map((action) {
        // If action is IconButton, wrap it with responsive sizing
        if (action is IconButton) {
          return SizedBox(
            width: isCompact ? 36 : 44,
            height: isCompact ? 36 : 44,
            child: action,
          );
        }
        return action;
      }));
    }

    // On very small screens, show menu button instead of all actions
    if (isSmallScreen) {
      allActions.clear();
      allActions.add(_buildMenuButton(context, isDark, isCompact));
    } else {
      // Add logout icon button
      allActions.add(
        Container(
          margin: EdgeInsets.only(right: isCompact ? 4 : 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.secondaryOrange.withOpacity(isDark ? 0.2 : 0.1),
                AppColors.secondaryOrange.withOpacity(isDark ? 0.15 : 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
            border: Border.all(
              color: AppColors.secondaryOrange.withOpacity(0.3),
            ),
          ),
          child: IconButton(
            onPressed: () => _showLogoutDialog(context, isDark),
            icon: const Icon(Icons.logout_rounded),
            color: AppColors.secondaryOrange,
            iconSize: isCompact ? 18 : 20,
            padding: EdgeInsets.all(isCompact ? 8 : 10),
            constraints: BoxConstraints(
              minWidth: isCompact ? 36 : 44,
              minHeight: isCompact ? 36 : 44,
            ),
            tooltip: 'Logout',
          ),
        ),
      );

      // Add theme toggle button
      if (showThemeToggle) {
        allActions.add(
          Container(
            margin: EdgeInsets.only(right: isCompact ? 2 : 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue.withOpacity(isDark ? 0.2 : 0.1),
                  AppColors.accentPurple.withOpacity(isDark ? 0.15 : 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(0.2),
              ),
            ),
            child: SizedBox(
              width: isCompact ? 36 : 44,
              height: isCompact ? 36 : 44,
              child: const ThemeToggleButton(),
            ),
          ),
        );
      }
    }

    return allActions;
  }

  Widget _buildMenuButton(BuildContext context, bool isDark, bool isCompact) {
    return Container(
      margin: EdgeInsets.only(right: isCompact ? 2 : 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withOpacity(isDark ? 0.2 : 0.1),
            AppColors.accentPurple.withOpacity(isDark ? 0.15 : 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.2),
        ),
      ),
      child: IconButton(
        onPressed: () => _showMobileMenu(context, isDark),
        icon: const Icon(Icons.more_vert_rounded),
        color: AppColors.primaryBlue,
        iconSize: isCompact ? 18 : 20,
        padding: EdgeInsets.all(isCompact ? 8 : 10),
        constraints: BoxConstraints(
          minWidth: isCompact ? 36 : 44,
          minHeight: isCompact ? 36 : 44,
        ),
        tooltip: 'Menu',
      ),
    );
  }

  void _showMobileMenu(BuildContext context, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Theme Toggle
              if (showThemeToggle)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                  ),
                  title: const Text('Toggle Theme'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    // Trigger theme toggle
                  },
                ),

              // Logout
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: AppColors.secondaryOrange,
                    size: 20,
                  ),
                ),
                title: const Text('Logout'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showLogoutDialog(context, isDark);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context, bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;

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
                padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                decoration: BoxDecoration(
                  color:
                  AppColors.secondaryOrange.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: AppColors.secondaryOrange,
                  size: isSmallScreen ? 20 : 24,
                ),
              ),
              const SizedBox(width: 14),
              Flexible(
                child: Text(
                  'Logout',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    fontSize: isSmallScreen ? 16 : 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 15,
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          actionsPadding: EdgeInsets.fromLTRB(
            isSmallScreen ? 16 : 24,
            0,
            isSmallScreen ? 16 : 24,
            isSmallScreen ? 16 : 20,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallScreen ? 13 : 14,
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
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : 24,
                  vertical: isSmallScreen ? 10 : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallScreen ? 13 : 14,
                ),
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
  Size get preferredSize {
    // Dynamic height based on subtitle presence
    return subtitle != null
        ? const Size.fromHeight(100)
        : const Size.fromHeight(80);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Responsive breakpoints
    final isSmallScreen = size.width < 360;
    final isCompact = size.width < 400;
    final isTablet = size.width >= 600;

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
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : (isTablet ? 20 : 16),
            vertical: isCompact ? 10 : 12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showBackButton)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
                  ),
                  child: IconButton(
                    onPressed: onBackPressed ?? () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: isSmallScreen ? 18 : 20,
                    ),
                    padding: EdgeInsets.all(isCompact ? 8 : 10),
                    constraints: BoxConstraints(
                      minWidth: isCompact ? 36 : 44,
                      minHeight: isCompact ? 36 : 44,
                    ),
                  ),
                ),
              SizedBox(width: isCompact ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 18 : (isCompact ? 20 : (isTablet ? 24 : 22)),
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: isCompact ? 2 : 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: isSmallScreen ? 12 : (isCompact ? 13 : 14),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),

              // Actions
              if (actions != null && !isSmallScreen)
                ...actions!.map((action) => Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: action,
                ))
              else if (isSmallScreen && (actions != null && actions!.isNotEmpty))
                _buildCompactActionsMenu(context, isCompact),

              // Theme toggle
              Container(
                margin: EdgeInsets.only(left: isCompact ? 4 : 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
                ),
                child: SizedBox(
                  width: isCompact ? 36 : 44,
                  height: isCompact ? 36 : 44,
                  child: const ThemeToggleButton(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactActionsMenu(BuildContext context, bool isCompact) {
    return Container(
      margin: EdgeInsets.only(left: isCompact ? 4 : 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
      ),
      child: IconButton(
        onPressed: () => _showActionsMenu(context),
        icon: const Icon(Icons.more_vert_rounded),
        color: Colors.white,
        iconSize: 20,
        padding: EdgeInsets.all(isCompact ? 8 : 10),
        constraints: BoxConstraints(
          minWidth: isCompact ? 36 : 44,
          minHeight: isCompact ? 36 : 44,
        ),
      ),
    );
  }

  void _showActionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Add custom actions here
              if (actions != null)
                ...actions!.map((action) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: action,
                )),
            ],
          ),
        );
      },
    );
  }
}