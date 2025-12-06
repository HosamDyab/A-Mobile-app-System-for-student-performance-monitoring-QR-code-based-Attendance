import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/utils/app_colors.dart';
import '../../viewmodels/students/students_bloc.dart';
import '../../viewmodels/students/students_state.dart';
import '../widgets/custom_app_bar.dart';
import 'widgets/student_card_widget.dart';

/// Students List Screen - View and manage students.
///
/// Features:
/// - Search by name, ID, or code
/// - Filter by level and attendance status
/// - Modern card design for student entries
/// - Theme-aware styling (light/dark mode)
/// - Works for both Faculty (lectures) and TA (sections)
class StudentsListScreen extends StatefulWidget {
  final String? facultyId;
  final String? role;

  const StudentsListScreen({
    super.key,
    this.facultyId,
    this.role,
  });

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  String? _selectedLevel;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    // Load students after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<StudentsBloc>().add(LoadStudentsEvent(
              facultyId: widget.facultyId,
              role: widget.role,
            ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Students',
        showBackButton: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar
            _buildSearchBar(colorScheme, isDark),
            const SizedBox(height: 16),

            // Filter Row
            _buildFilterRow(colorScheme, isDark),
            const SizedBox(height: 20),

            // Students List
            Expanded(
              child: BlocBuilder<StudentsBloc, StudentsState>(
                builder: (context, state) {
                  if (state is StudentsLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                        strokeWidth: 3,
                      ),
                    );
                  } else if (state is StudentsLoaded) {
                    if (state.students.isEmpty) {
                      return _buildEmptyState(colorScheme, isDark);
                    }
                    return _buildStudentsList(state, colorScheme, isDark);
                  } else if (state is StudentsError) {
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
          hintText: 'Search by Name, ID, or Code...',
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
          context.read<StudentsBloc>().add(SearchStudentsEvent(value));
        },
      ),
    );
  }

  Widget _buildFilterRow(ColorScheme colorScheme, bool isDark) {
    return Row(
      children: [
        // Level Dropdown
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedLevel,
            decoration: InputDecoration(
              labelText: 'Level',
              labelStyle: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: 13,
              ),
              filled: true,
              fillColor: isDark ? colorScheme.surface : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            dropdownColor: colorScheme.surface,
            items: ['All Levels', 'L1', 'L2', 'L3', 'L4'].map((level) {
              return DropdownMenuItem<String>(
                value: level == 'All Levels' ? null : level,
                child: Text(
                  level,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 13,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedLevel = value);
              context
                  .read<StudentsBloc>()
                  .add(FilterStudentsEvent(level: value));
            },
          ),
        ),
        const SizedBox(width: 12),

        // Attendance Status Dropdown
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: InputDecoration(
              labelText: 'Attendance',
              labelStyle: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: 13,
              ),
              filled: true,
              fillColor: isDark ? colorScheme.surface : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            dropdownColor: colorScheme.surface,
            items: ['All Status', 'Present', 'Absent', 'Late'].map((status) {
              return DropdownMenuItem<String>(
                value: status == 'All Status' ? null : status,
                child: Row(
                  children: [
                    if (status != 'All Status')
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          shape: BoxShape.circle,
                        ),
                      ),
                    Text(
                      status,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedStatus = value);
              context
                  .read<StudentsBloc>()
                  .add(FilterStudentsEvent(status: value));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsList(
      StudentsLoaded state, ColorScheme colorScheme, bool isDark) {
    return ListView.builder(
      itemCount: state.students.length,
      itemBuilder: (context, index) {
        final student = state.students[index];
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
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: StudentCard(student: student),
          ),
        );
      },
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
              Icons.people_outline_rounded,
              size: 56,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No students found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
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
              Icons.school_rounded,
              size: 56,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading students...',
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
            style: TextStyle(
              color: AppColors.accentRed,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<StudentsBloc>().add(LoadStudentsEvent());
            },
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Present':
        return AppColors.accentGreen;
      case 'Absent':
        return AppColors.accentRed;
      case 'Late':
        return AppColors.secondaryBlue;
      default:
        return AppColors.tertiaryLightGray;
    }
  }
}
