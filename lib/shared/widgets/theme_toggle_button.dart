import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/theme_manager.dart';
import '../utils/app_colors.dart';

/// Button widget for toggling between light and dark theme.
///
/// Displays a sun icon for light mode and moon icon for dark mode,
/// with smooth animated transition.
class ThemeToggleButton extends StatelessWidget {
  final bool showAsIcon;
  final bool showLabel;

  const ThemeToggleButton({
    super.key,
    this.showAsIcon = true,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDark = themeManager.isDarkMode;

    if (showAsIcon) {
      return IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return RotationTransition(
              turns: animation,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            key: ValueKey(isDark),
            color: isDark ? Colors.amber : AppColors.primaryBlue,
          ),
        ),
        onPressed: () => themeManager.toggleTheme(),
        tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
      );
    }

    return TextButton.icon(
      onPressed: () => themeManager.toggleTheme(),
      icon: Icon(
        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        color: isDark ? Colors.amber : AppColors.primaryBlue,
        size: 20,
      ),
      label: showLabel
          ? Text(
              isDark ? 'Light Mode' : 'Dark Mode',
              style: TextStyle(
                color: isDark ? Colors.amber : AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            )
          : const SizedBox.shrink(),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

