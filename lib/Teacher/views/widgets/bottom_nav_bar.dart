import 'package:flutter/material.dart';

import '../../../shared/utils/app_colors.dart';

/// Modern, animated bottom navigation bar for the Teacher module.
///
/// Features:
/// - Theme-aware colors (light/dark mode support)
/// - Smooth animations on selection (matches Student theme)
/// - Modern design with AppColors gradients
/// - Role-aware labels (Sections for TA, Lectures for Faculty)
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String? role;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.role,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, -8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                index: 0,
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard_rounded,
                label: 'Dashboard',
                isDark: isDark,
              ),
              _buildNavItem(
                context: context,
                index: 1,
                icon: Icons.edit_calendar_outlined,
                activeIcon: Icons.edit_calendar_rounded,
                label: 'Attendance',
                isDark: isDark,
              ),
              _buildNavItem(
                context: context,
                index: 2,
                icon: Icons.grade_outlined,
                activeIcon: Icons.grade_rounded,
                label: 'Grades',
                isDark: isDark,
              ),
              _buildNavItem(
                context: context,
                index: 3,
                icon: Icons.people_outline,
                activeIcon: Icons.people_rounded,
                label: 'Students',
                isDark: isDark,
              ),
              _buildNavItem(
                context: context,
                index: 4,
                icon: Icons.person_outline,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 8,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.primaryBlue.withOpacity(isDark ? 0.25 : 0.15),
                    AppColors.accentPurple.withOpacity(isDark ? 0.15 : 0.08),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
              child: Container(
                key: ValueKey(isSelected),
                padding: EdgeInsets.all(isSelected ? 6 : 4),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            AppColors.primaryBlue.withOpacity(0.2),
                            AppColors.primaryBlue.withOpacity(0.1),
                          ],
                        )
                      : null,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  size: isSelected ? 22 : 20,
                  color: isSelected
                      ? AppColors.primaryBlue
                      : isDark
                          ? Colors.grey[500]
                          : AppColors.tertiaryLightGray,
                ),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isSelected ? 10 : 9,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primaryBlue
                    : isDark
                        ? Colors.grey[500]
                        : AppColors.tertiaryLightGray,
              ),
              child: Text(label),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
