import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../shared/utils/app_colors.dart';
import '../../viewmodels/attendance_history/attendance_history_cubit.dart';
import '../../viewmodels/attendance_history/attendance_history_state.dart';
import '../widgets/custom_app_bar.dart';

/// Attendance History Screen - View past attendance records.
///
/// Features:
/// - Search by course name or code
/// - Filter by week number
/// - Date range picker
/// - Theme-aware styling (light/dark mode)
/// - Modern card design for records
class AttendanceHistoryScreen extends StatefulWidget {
  final String? facultyId;

  const AttendanceHistoryScreen({
    super.key,
    this.facultyId,
  });

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  String? _selectedCourse;
  int? _selectedWeek;
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load attendance after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadAttendance();
      }
    });
  }

  void _loadAttendance() {
    context.read<AttendanceHistoryCubit>().loadAttendanceHistory(
          courseCode: _selectedCourse,
          weekNumber: _selectedWeek,
          startDate: _startDate,
          endDate: _endDate,
          facultyId: widget.facultyId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Attendance History',
        showBackButton: false,
      ),
      body: Column(
        children: [
          // Filters Section
          _buildFiltersSection(colorScheme, isDark),

          // Attendance List
          Expanded(
            child: BlocBuilder<AttendanceHistoryCubit, AttendanceHistoryState>(
              builder: (context, state) {
                if (state is AttendanceHistoryLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                      strokeWidth: 3,
                    ),
                  );
                } else if (state is AttendanceHistoryLoaded) {
                  if (state.records.isEmpty) {
                    return _buildEmptyState(colorScheme, isDark);
                  }

                  return _buildRecordsList(state, colorScheme, isDark);
                } else if (state is AttendanceHistoryError) {
                  return _buildErrorState(state.message, colorScheme, isDark);
                }
                return _buildInitialState(colorScheme, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surface.withOpacity(0.5)
            : AppColors.backgroundLight,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon:
                    Icon(Icons.search_rounded, color: AppColors.primaryBlue),
                hintText: 'Search by course name or code...',
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
                setState(
                    () => _selectedCourse = value.isNotEmpty ? value : null);
                _loadAttendance();
              },
            ),
          ),
          const SizedBox(height: 14),

          // Date Range and Week Number Row
          Row(
            children: [
              // Week Number Dropdown
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedWeek,
                  decoration: InputDecoration(
                    labelText: 'Week',
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
                      borderSide:
                          BorderSide(color: AppColors.primaryBlue, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  dropdownColor: colorScheme.surface,
                  items: [
                    DropdownMenuItem<int>(
                      value: null,
                      child: Text(
                        'All Weeks',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    ...List.generate(15, (i) => i + 1).map((week) {
                      return DropdownMenuItem<int>(
                        value: week,
                        child: Text(
                          'Week $week',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedWeek = value);
                    _loadAttendance();
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Date Range Button
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _selectDateRange,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? colorScheme.surface : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primaryBlue.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.date_range_rounded,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _startDate == null
                                  ? 'Date Range'
                                  : '${DateFormat('MMM d').format(_startDate!)} - ${_endDate != null ? DateFormat('MMM d').format(_endDate!) : 'Now'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Clear Filters Button
          if (_selectedCourse != null ||
              _selectedWeek != null ||
              _startDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedCourse = null;
                    _selectedWeek = null;
                    _startDate = null;
                    _endDate = null;
                    _searchController.clear();
                  });
                  _loadAttendance();
                },
                icon: Icon(Icons.clear_all_rounded, color: AppColors.accentRed),
                label: Text(
                  'Clear Filters',
                  style: TextStyle(
                    color: AppColors.accentRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecordsList(
      AttendanceHistoryLoaded state, ColorScheme colorScheme, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.records.length,
      itemBuilder: (context, index) {
        final record = state.records[index];
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
          child: _buildRecordCard(record, colorScheme, isDark),
        );
      },
    );
  }

  Widget _buildRecordCard(record, ColorScheme colorScheme, bool isDark) {
    final isPresent = record.status == 'Present';
    final statusColor = isPresent ? AppColors.accentGreen : AppColors.secondaryOrange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(18),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Status Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isPresent
                    ? Icons.check_circle_rounded
                    : Icons.schedule_rounded,
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Student Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.studentName ??
                        'Student ${record.studentCode ?? record.studentId}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      fontSize: 15,
                    ),
                  ),
                  if (record.courseTitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${record.courseCode ?? ''} - ${record.courseTitle}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, y - h:mm a').format(record.scanTime),
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      if (record.weekNumber != null) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue
                                .withOpacity(isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'W${record.weekNumber}',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Status Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                record.status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
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
              Icons.history_rounded,
              size: 56,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No attendance records found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
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
              Icons.history_rounded,
              size: 56,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading attendance history...',
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

  Widget _buildErrorState(String message, ColorScheme colorScheme, bool isDark) {
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
            onPressed: _loadAttendance,
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

  Future<void> _selectDateRange() async {
    final colorScheme = Theme.of(context).colorScheme;

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: colorScheme.copyWith(
              primary: AppColors.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadAttendance();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
