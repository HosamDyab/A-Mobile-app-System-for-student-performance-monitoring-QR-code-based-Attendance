import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/attendance_history/attendance_history_cubit.dart';
import '../../viewmodels/attendance_history/attendance_history_state.dart';
import '../widgets/custom_app_bar.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final String? facultyId;

  const AttendanceHistoryScreen({
    super.key,
    this.facultyId,
  });

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
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
    _loadAttendance();
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
    return Scaffold(
      appBar: CustomAppBar(title: 'Attendance History'),
      body: Column(
        children: [
          // Filters Section
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search by course name or code...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _selectedCourse = value.isNotEmpty ? value : null);
                    _loadAttendance();
                  },
                ),
                const SizedBox(height: 12),
                
                // Date Range and Week Number Row
                Row(
                  children: [
                    // Week Number Dropdown
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedWeek,
                        decoration: InputDecoration(
                          labelText: 'Week',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('All Weeks'),
                          ),
                          ...List.generate(15, (i) => i + 1).map((week) {
                            return DropdownMenuItem<int>(
                              value: week,
                              child: Text('Week $week'),
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
                      child: OutlinedButton.icon(
                        onPressed: _selectDateRange,
                        icon: const Icon(Icons.date_range),
                        label: Text(
                          _startDate == null
                              ? 'Date Range'
                              : '${DateFormat('MMM d').format(_startDate!)} - ${_endDate != null ? DateFormat('MMM d').format(_endDate!) : 'Now'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
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
                    padding: const EdgeInsets.only(top: 8),
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
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Clear Filters'),
                    ),
                  ),
              ],
            ),
          ),
          
          // Attendance List
          Expanded(
            child: BlocBuilder<AttendanceHistoryCubit, AttendanceHistoryState>(
              builder: (context, state) {
                if (state is AttendanceHistoryLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is AttendanceHistoryLoaded) {
                  if (state.records.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No attendance records found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.records.length,
                    itemBuilder: (context, index) {
                      final record = state.records[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: record.status == 'Present'
                                ? Colors.green
                                : Colors.orange,
                            child: Icon(
                              record.status == 'Present'
                                  ? Icons.check
                                  : Icons.schedule,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            record.studentName ?? 'Student ${record.studentCode ?? record.studentId}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              if (record.courseTitle != null)
                                Text(
                                  '${record.courseCode ?? ''} - ${record.courseTitle}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, 
                                    size: 12, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('MMM d, y - h:mm a').format(record.scanTime),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (record.weekNumber != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'W${record.weekNumber}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.blue[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing: Chip(
                            label: Text(
                              record.status,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: record.status == 'Present'
                                ? Colors.green[50]
                                : Colors.orange[50],
                            labelStyle: TextStyle(
                              color: record.status == 'Present'
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                } else if (state is AttendanceHistoryError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${state.message}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadAttendance,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
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
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFD88A2D),
              onPrimary: Colors.white,
              onSurface: Colors.black,
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

