import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/utils/app_colors.dart';
import '../../viewmodels/teacher_assistant/teacher_assistant_cubit.dart';
import '../../viewmodels/teacher_assistant/teacher_assistant_state.dart';
import '../widgets/custom_app_bar.dart';

/// Teacher Assistant List Screen - View and manage teacher assistants.
///
/// Features:
/// - Search by name or email
/// - Filter by department or course
/// - Modern card design for TA entries
/// - Theme-aware styling (light/dark mode)
class TeacherAssistantListScreen extends StatefulWidget {
  final String? departmentCode;
  final String? courseCode;

  const TeacherAssistantListScreen({
    super.key,
    this.departmentCode,
    this.courseCode,
  });

  @override
  State<TeacherAssistantListScreen> createState() =>
      _TeacherAssistantListScreenState();
}

class _TeacherAssistantListScreenState
    extends State<TeacherAssistantListScreen> {
  @override
  void initState() {
    super.initState();
    // Load TAs after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadTeacherAssistants();
      }
    });
  }

  void _loadTeacherAssistants() {
    if (widget.courseCode != null) {
      context
          .read<TeacherAssistantCubit>()
          .loadTeacherAssistantsByCourse(widget.courseCode!);
    } else if (widget.departmentCode != null) {
      context
          .read<TeacherAssistantCubit>()
          .loadTeacherAssistantsByDepartment(widget.departmentCode!);
    } else {
      context.read<TeacherAssistantCubit>().loadAllTeacherAssistants();
    }
  }

  String get _title {
    if (widget.courseCode != null) return 'Course T.As';
    if (widget.departmentCode != null) return 'Department T.As';
    return 'Teacher Assistants';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(title: _title),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            _buildSearchBar(colorScheme, isDark),
            const SizedBox(height: 20),

            // T.A. List
            Expanded(
              child: BlocBuilder<TeacherAssistantCubit, TeacherAssistantState>(
                builder: (context, state) {
                  if (state is TeacherAssistantLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                        strokeWidth: 3,
                      ),
                    );
                  } else if (state is TeacherAssistantLoaded) {
                    if (state.teacherAssistants.isEmpty) {
                      return _buildEmptyState(colorScheme, isDark);
                    }
                    return _buildTAList(state, colorScheme, isDark);
                  } else if (state is TeacherAssistantError) {
                    return _buildErrorState(state.message, colorScheme, isDark);
                  }
                  return _buildInitialState(colorScheme, isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.primaryBlue),
          hintText: 'Search by name or email...',
          hintStyle: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.4),
            fontSize: 14,
          ),
          filled: true,
          fillColor: isDark ? colorScheme.surface : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
        onChanged: (value) {
          context.read<TeacherAssistantCubit>().searchTeacherAssistants(value);
        },
      ),
    );
  }

  Widget _buildTAList(
      TeacherAssistantLoaded state, ColorScheme colorScheme, bool isDark) {
    return ListView.builder(
      itemCount: state.teacherAssistants.length,
      itemBuilder: (context, index) {
        final ta = state.teacherAssistants[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 200 + (index * 50)),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: _buildTACard(ta, colorScheme, isDark),
        );
      },
    );
  }

  Widget _buildTACard(dynamic ta, ColorScheme colorScheme, bool isDark) {
    final initials = ta.fullName
        .split(' ')
        .map((n) => n.isNotEmpty ? n[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(isDark ? 0.1 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTADetails(context, ta, colorScheme),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.transparent,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // TA Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ta.fullName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.email_rounded,
                            size: 14,
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              ta.email,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue
                              .withOpacity(isDark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ID: ${ta.taId}',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                    AppColors.primaryBlue.withOpacity(isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue.withOpacity(isDark ? 0.2 : 0.1),
                  AppColors.accentPurple.withOpacity(isDark ? 0.15 : 0.08),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_search_rounded,
              size: 56,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No teacher assistants found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState(ColorScheme colorScheme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue.withOpacity(isDark ? 0.2 : 0.1),
                  AppColors.accentPurple.withOpacity(isDark ? 0.15 : 0.08),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_rounded,
              size: 56,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading teacher assistants...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
      String message, ColorScheme colorScheme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.accentRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: AppColors.accentRed,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Error: $message',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.accentRed),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadTeacherAssistants,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  void _showTADetails(
      BuildContext context, dynamic ta, ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                ta.fullName,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              'Email',
              ta.email,
              Icons.email_rounded,
              colorScheme,
              isDark,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'TA ID',
              ta.taId,
              Icons.badge_rounded,
              colorScheme,
              isDark,
            ),
            if (ta.depCode != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                'Department',
                ta.depCode!,
                Icons.business_rounded,
                colorScheme,
                isDark,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      String label,
      String value,
      IconData icon,
      ColorScheme colorScheme,
      bool isDark,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}