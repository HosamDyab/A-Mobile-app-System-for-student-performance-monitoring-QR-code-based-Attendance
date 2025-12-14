import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../../shared/utils/app_colors.dart';
import '../widgets/custom_app_bar.dart';

/// Manual Attendance Screen - Record attendance manually for students.
///
/// FIXES:
/// 1. Proper status storage (Present/Absent only, matching ispresent boolean)
/// 2. Week number based on academic year (FALL = weeks 1-17, SPRING = weeks 1-17)
/// 3. Time information properly set from course schedule
/// 4. Date selection restricted to scheduled course days only
/// 5. Proper upsert to handle duplicates
/// 6. Clear academic year context
class ManualAttendanceScreen extends StatefulWidget {
  final String facultyId;
  final String role;

  const ManualAttendanceScreen({
    super.key,
    required this.facultyId,
    required this.role,
  });

  @override
  State<ManualAttendanceScreen> createState() => _ManualAttendanceScreenState();
}

class _ManualAttendanceScreenState extends State<ManualAttendanceScreen> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  List<String> _selectedStudents = [];

  String? _selectedCourse;
  String? _selectedAcademicYear;
  String? _selectedSemester;
  Map<String, dynamic>? _selectedCourseSchedule;

  DateTime _selectedDate = DateTime.now();
  String _selectedStatus = 'Present';
  bool _isLoading = false;
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);

    try {
      if (widget.role == 'faculty') {
        final response = await _supabase
            .from('lecturecourseoffering')
            .select('''
              lectureofferingid, 
              coursecode, 
              academicyear, 
              semester,
              slotid,
              roomid,
              course(coursecode, coursename),
              timeslot(slotid, dayofweek, starttime, endtime)
            ''')
            .eq('facultysnn', widget.facultyId);

        setState(() {
          _courses = List<Map<String, dynamic>>.from(response as List);
          _isLoading = false;
        });
      } else {
        final response = await _supabase
            .from('sectionta')
            .select('''
              sectionofferingid,
              sectioncourseoffering(
                sectionofferingid,
                coursecode,
                slotid,
                roomid,
                course(coursecode, coursename),
                timeslot(slotid, dayofweek, starttime, endtime)
              )
            ''')
            .eq('tasnn', widget.facultyId);

        setState(() {
          _courses = List<Map<String, dynamic>>.from(response as List);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnackBar('Error loading courses: $e', isError: true);
      }
      debugPrint('Error loading courses: $e');
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedCourse == null) return;

    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> studentsList = [];

      if (widget.role == 'faculty') {
        try {
          final studentsResponse = await _supabase
              .from('lectureenrollment')
              .select('studentid, student(studentid, fullname, email)')
              .eq('lectureofferingid', _selectedCourse!);

          studentsList = List<Map<String, dynamic>>.from(studentsResponse as List);
        } catch (e) {
          debugPrint('Lecture enrollment query failed: $e');
        }
      } else {
        try {
          final response = await _supabase
              .from('sectionenrollment')
              .select('studentid, student(studentid, fullname, email)')
              .eq('sectionofferingid', _selectedCourse!);

          studentsList = List<Map<String, dynamic>>.from(response as List);
        } catch (e) {
          debugPrint('Section enrollment query failed: $e');
        }
      }

      setState(() {
        _allStudents = studentsList;
        _filteredStudents = studentsList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnackBar('Error loading students: $e', isError: true);
      }
      debugPrint('Error loading students: $e');
    }
  }

  void _filterStudents(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredStudents = _allStudents;
      } else {
        _filteredStudents = _allStudents.where((student) {
          final studentData = student['student'] as Map<String, dynamic>?;
          final name = (studentData?['fullname'] ?? '').toString().toLowerCase();
          final email = (studentData?['email'] ?? '').toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || email.contains(searchLower);
        }).toList();
      }
    });
  }

  int _calculateWeekNumber(DateTime date, String semester) {
    // Academic year calendar:
    // FALL semester: September-December (weeks 1-17)
    // SPRING semester: January-May (weeks 1-17)

    if (semester == 'FALL') {
      // Fall semester starts in September
      final semesterStart = DateTime(date.year, 9, 1);
      if (date.isBefore(semesterStart)) {
        // If date is before September, it might be summer or previous spring
        return 1;
      }
      final daysDiff = date.difference(semesterStart).inDays;
      return (daysDiff / 7).floor() + 1;
    } else if (semester == 'SPRING') {
      // Spring semester starts in January
      final semesterStart = DateTime(date.year, 1, 1);
      final daysDiff = date.difference(semesterStart).inDays;
      return (daysDiff / 7).floor() + 1;
    } else {
      // BOTH or unknown - default calculation
      final yearStart = DateTime(date.year, 1, 1);
      final daysDiff = date.difference(yearStart).inDays;
      return (daysDiff / 7).floor() + 1;
    }
  }

  bool _isDateMatchingSchedule(DateTime date) {
    if (_selectedCourseSchedule == null) return true;

    final timeslot = _selectedCourseSchedule!['timeslot'] as Map<String, dynamic>?;
    if (timeslot == null) return true;

    final scheduledDay = timeslot['dayofweek']?.toString().toUpperCase();
    if (scheduledDay == null) return true;

    // Map DateTime weekday to day name
    final weekdayNames = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
    final selectedDay = weekdayNames[date.weekday - 1];

    return scheduledDay == selectedDay;
  }

  String _getScheduledDayName() {
    if (_selectedCourseSchedule == null) return 'N/A';

    final timeslot = _selectedCourseSchedule!['timeslot'] as Map<String, dynamic>?;
    if (timeslot == null) return 'N/A';

    final dayOfWeek = timeslot['dayofweek']?.toString();
    if (dayOfWeek == null) return 'N/A';

    // Capitalize first letter, rest lowercase
    return dayOfWeek[0].toUpperCase() + dayOfWeek.substring(1).toLowerCase();
  }

  DateTime _findMostRecentScheduledDate() {
    final now = DateTime.now();

    // Start from today and go backwards to find the most recent matching day
    for (int i = 0; i <= 7; i++) {
      final checkDate = now.subtract(Duration(days: i));
      if (_isDateMatchingSchedule(checkDate)) {
        return checkDate;
      }
    }

    // Fallback to today if no match found in the last week
    return now;
  }

  Future<void> _submitAttendance() async {
    if (_selectedCourse == null || _selectedStudents.isEmpty) {
      _showSnackBar('Please select course and students', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dateStr = _selectedDate.toIso8601String().split('T')[0];
      final isFaculty = widget.role == 'faculty';
      final isPresentStatus = _selectedStatus == 'Present';
      final weekNumber = _calculateWeekNumber(_selectedDate, _selectedSemester ?? 'FALL');

      debugPrint('=== SUBMIT ATTENDANCE DEBUG ===');
      debugPrint('Role: ${widget.role}');
      debugPrint('Selected Course: $_selectedCourse');
      debugPrint('Selected Date: $dateStr');
      debugPrint('Week Number: $weekNumber');
      debugPrint('Semester: $_selectedSemester');
      debugPrint('Status: $_selectedStatus (ispresent: $isPresentStatus)');
      debugPrint('Selected Students: $_selectedStudents');

      String finalInstanceId;

      if (isFaculty) {
        // === FACULTY: Use lectureinstance and lectureattendance ===

        // Get time information from course schedule
        TimeOfDay? startTime;
        TimeOfDay? endTime;

        if (_selectedCourseSchedule != null) {
          final timeslot = _selectedCourseSchedule!['timeslot'] as Map<String, dynamic>?;
          if (timeslot != null) {
            final startTimeStr = timeslot['starttime']?.toString();
            final endTimeStr = timeslot['endtime']?.toString();

            if (startTimeStr != null) {
              final parts = startTimeStr.split(':');
              startTime = TimeOfDay(
                hour: int.parse(parts[0]),
                minute: int.parse(parts[1]),
              );
            }

            if (endTimeStr != null) {
              final parts = endTimeStr.split(':');
              endTime = TimeOfDay(
                hour: int.parse(parts[0]),
                minute: int.parse(parts[1]),
              );
            }
          }
        }

        // Check if lecture instance already exists
        final existingInstance = await _supabase
            .from('lectureinstance')
            .select('linstanceid')
            .eq('lectureofferingid', _selectedCourse!)
            .eq('meetingdate', dateStr)
            .maybeSingle();

        if (existingInstance == null) {
          // Create new lecture instance with time information
          final generatedInstanceId = 'LI-$_selectedCourse-$dateStr';

          final instanceData = <String, dynamic>{
            'linstanceid': generatedInstanceId,
            'lectureofferingid': _selectedCourse,
            'meetingdate': dateStr,
            'weeknumber': weekNumber,
          };

          // Add time information if available
          if (startTime != null) {
            instanceData['starttime'] = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00';
          }
          if (endTime != null) {
            instanceData['endtime'] = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00';
          }

          final insertResponse = await _supabase
              .from('lectureinstance')
              .insert(instanceData)
              .select('linstanceid')
              .single();

          finalInstanceId = insertResponse['linstanceid'];
          debugPrint('Created new lecture instance: $finalInstanceId');
        } else {
          finalInstanceId = existingInstance['linstanceid'];
          debugPrint('Using existing lecture instance: $finalInstanceId');
        }

        // Upsert attendance records (handles both insert and update)
        final attendanceRecords = _selectedStudents.map((studentId) {
          return {
            'studentid': studentId,
            'linstanceid': finalInstanceId,
            'ispresent': isPresentStatus,
            'scannedat': DateTime.now().toIso8601String(),
          };
        }).toList();

        await _supabase.from('lectureattendance').upsert(
          attendanceRecords,
          onConflict: 'studentid,linstanceid',
        );

        debugPrint('Upserted ${attendanceRecords.length} attendance records');

        if (mounted) {
          _showSnackBar(
            'Attendance recorded for ${attendanceRecords.length} students',
            isError: false,
          );
        }
      } else {
        // === TA: Use sectioninstance and sectionattendance ===

        // Check if section instance already exists
        final existingInstance = await _supabase
            .from('sectioninstance')
            .select('sinstanceid')
            .eq('sectionofferingid', _selectedCourse!)
            .eq('meetingdate', dateStr)
            .maybeSingle();

        if (existingInstance == null) {
          // Create new section instance
          final generatedSectionInstanceId = 'SI-$_selectedCourse-$dateStr';

          final instanceData = {
            'sinstanceid': generatedSectionInstanceId,
            'sectionofferingid': _selectedCourse,
            'meetingdate': dateStr,
            'weeknumber': weekNumber,
          };

          final insertResponse = await _supabase
              .from('sectioninstance')
              .insert(instanceData)
              .select('sinstanceid')
              .single();

          finalInstanceId = insertResponse['sinstanceid'];
          debugPrint('Created new section instance: $finalInstanceId');
        } else {
          finalInstanceId = existingInstance['sinstanceid'];
          debugPrint('Using existing section instance: $finalInstanceId');
        }

        // Upsert attendance records
        final attendanceRecords = _selectedStudents.map((studentId) {
          return {
            'studentid': studentId,
            'sinstanceid': finalInstanceId,
            'ispresent': isPresentStatus,
            'scannedat': DateTime.now().toIso8601String(),
          };
        }).toList();

        await _supabase.from('sectionattendance').upsert(
          attendanceRecords,
          onConflict: 'studentid,sinstanceid',
        );

        debugPrint('Upserted ${attendanceRecords.length} attendance records');

        if (mounted) {
          _showSnackBar(
            'Attendance recorded for ${attendanceRecords.length} students',
            isError: false,
          );
        }
      }

      setState(() {
        _isLoading = false;
        _selectedStudents.clear();
      });

      debugPrint('=== ATTENDANCE SUBMISSION COMPLETED ===');

    } catch (e, stackTrace) {
      setState(() => _isLoading = false);
      debugPrint('=== ERROR SUBMITTING ATTENDANCE ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        _showSnackBar('Error submitting attendance: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppColors.accentRed : AppColors.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _getStudentName(Map<String, dynamic> student) {
    final studentData = student['student'] as Map<String, dynamic>?;
    return studentData?['fullname'] ?? 'Unknown Student';
  }

  String _getStudentCode(Map<String, dynamic> student) {
    final studentData = student['student'] as Map<String, dynamic>?;
    return studentData?['studentid'] ?? 'N/A';
  }

  String _getStudentId(Map<String, dynamic> student) {
    return student['studentid']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    final isSmallScreen = size.width < 360;
    final isCompact = size.width < 400;
    final isTablet = size.width >= 600;
    final isDesktop = size.width >= 1024;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 24.0 : (isCompact ? 12.0 : 16.0));
    final verticalPadding = isTablet ? 24.0 : 16.0;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Manual Attendance'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : isLandscape && isTablet
          ? _buildLandscapeLayout(context, colorScheme, isDark, isSmallScreen, isCompact, horizontalPadding)
          : _buildPortraitLayout(context, colorScheme, isDark, isSmallScreen, isCompact, isTablet, isDesktop, horizontalPadding, verticalPadding),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, ColorScheme colorScheme, bool isDark, bool isSmallScreen, bool isCompact, double horizontalPadding) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(colorScheme, isDark, isSmallScreen, isCompact),
                const SizedBox(height: 24),
                _buildCourseSelection(colorScheme, isDark, isSmallScreen, isCompact),
                const SizedBox(height: 20),
                _buildDateSelection(colorScheme, isDark, isSmallScreen, isCompact),
                const SizedBox(height: 20),
                _buildStatusSelection(colorScheme, isDark, isSmallScreen, isCompact),
                if (_selectedCourseSchedule != null) ...[
                  const SizedBox(height: 20),
                  _buildScheduleInfo(colorScheme, isDark, isSmallScreen, isCompact),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_allStudents.isNotEmpty) ...[
                  _buildStudentSearch(colorScheme, isDark, isSmallScreen, isCompact),
                  const SizedBox(height: 16),
                  _buildStudentListHeader(colorScheme, isSmallScreen, isCompact),
                  const SizedBox(height: 12),
                  _buildStudentList(colorScheme, isDark, isSmallScreen, isCompact),
                  const SizedBox(height: 24),
                  _buildSubmitButton(isSmallScreen, isCompact),
                ],
                if (_selectedCourse != null && _allStudents.isEmpty && !_isLoading)
                  _buildEmptyStudentsState(colorScheme, isDark, isSmallScreen, isCompact),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout(BuildContext context, ColorScheme colorScheme, bool isDark, bool isSmallScreen, bool isCompact, bool isTablet, bool isDesktop, double horizontalPadding, double verticalPadding) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 900 : (isTablet ? 700 : double.infinity),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(colorScheme, isDark, isSmallScreen, isCompact),
              SizedBox(height: isTablet ? 28 : 24),
              _buildCourseSelection(colorScheme, isDark, isSmallScreen, isCompact),
              SizedBox(height: isTablet ? 24 : 20),
              _buildDateStatusRow(colorScheme, isDark, isSmallScreen, isCompact, isTablet),
              if (_selectedCourseSchedule != null) ...[
                SizedBox(height: isTablet ? 20 : 16),
                _buildScheduleInfo(colorScheme, isDark, isSmallScreen, isCompact),
              ],
              SizedBox(height: isTablet ? 28 : 24),

              if (_allStudents.isNotEmpty) ...[
                _buildStudentSearch(colorScheme, isDark, isSmallScreen, isCompact),
                const SizedBox(height: 16),
                _buildStudentListHeader(colorScheme, isSmallScreen, isCompact),
                const SizedBox(height: 12),
                _buildStudentList(colorScheme, isDark, isSmallScreen, isCompact),
                const SizedBox(height: 24),
                _buildSubmitButton(isSmallScreen, isCompact),
              ],

              if (_selectedCourse != null && _allStudents.isEmpty && !_isLoading)
                _buildEmptyStudentsState(colorScheme, isDark, isSmallScreen, isCompact),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(ColorScheme colorScheme, bool isDark, bool isSmallScreen, bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 14 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withOpacity(isDark ? 0.2 : 0.1),
            AppColors.accentPurple.withOpacity(isDark ? 0.15 : 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.edit_calendar_rounded,
              color: Colors.white,
              size: isSmallScreen ? 22 : 26,
            ),
          ),
          SizedBox(width: isCompact ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manual Attendance Entry',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 15 : (isCompact ? 16 : 17),
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: isCompact ? 2 : 4),
                Text(
                  'Record attendance for students manually',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 13,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseSelection(ColorScheme colorScheme, bool isDark, bool isSmallScreen, bool isCompact) {
    final isTA = widget.role == 'teacher_assistant';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isTA ? 'Select Section' : 'Select Course',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 15,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCourse,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
            hintText: isTA ? 'Choose a section' : 'Choose a course',
            hintStyle: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.4),
              fontSize: isSmallScreen ? 13 : 14,
            ),
            filled: true,
            fillColor: isDark ? colorScheme.surface : Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isCompact ? 12 : 16,
              vertical: isCompact ? 12 : 14,
            ),
          ),
          dropdownColor: colorScheme.surface,
          style: TextStyle(
            fontSize: isSmallScreen ? 13 : 14,
            color: colorScheme.onSurface,
          ),
          items: _courses.map((course) {
            Map<String, dynamic>? courseData;
            String? id;
            String? academicYear;
            String? semester;
            Map<String, dynamic>? schedule;

            if (widget.role == 'faculty') {
              courseData = course['course'] as Map<String, dynamic>?;
              id = course['lectureofferingid']?.toString();
              academicYear = course['academicyear']?.toString();
              semester = course['semester']?.toString();
              schedule = course;
            } else {
              final sectionOffering = course['sectioncourseoffering'] as Map<String, dynamic>?;
              courseData = sectionOffering?['course'] as Map<String, dynamic>?;
              id = sectionOffering?['sectionofferingid']?.toString();
              schedule = sectionOffering;
            }

            final displayText = courseData != null
                ? '${courseData['coursecode']} - ${courseData['coursename']}${academicYear != null ? ' ($academicYear ${semester ?? ''})' : ''}'
                : 'Unknown Course';

            return DropdownMenuItem<String>(
              value: id,
              child: Text(
                displayText,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCourse = value;
              _allStudents.clear();
              _filteredStudents.clear();
              _selectedStudents.clear();
              _searchController.clear();
              _searchQuery = '';

              // Store academic year, semester, and schedule info
              if (widget.role == 'faculty') {
                final selectedCourseData = _courses.firstWhere(
                      (c) => c['lectureofferingid'] == value,
                  orElse: () => {},
                );
                _selectedAcademicYear = selectedCourseData['academicyear']?.toString();
                _selectedSemester = selectedCourseData['semester']?.toString();
                _selectedCourseSchedule = selectedCourseData;
              } else {
                final selectedCourseData = _courses.firstWhere(
                      (c) => (c['sectioncourseoffering'] as Map<String, dynamic>?)?['sectionofferingid'] == value,
                  orElse: () => {},
                );
                final sectionOffering = selectedCourseData['sectioncourseoffering'] as Map<String, dynamic>?;
                _selectedCourseSchedule = sectionOffering;
              }

              // Set initial date to the most recent matching scheduled day
              _selectedDate = _findMostRecentScheduledDate();
            });
            _loadStudents();
          },
        ),
      ],
    );
  }

  Widget _buildScheduleInfo(ColorScheme colorScheme, bool isDark, bool isSmallScreen, bool isCompact) {
    if (_selectedCourseSchedule == null) return const SizedBox.shrink();

    final timeslot = _selectedCourseSchedule!['timeslot'] as Map<String, dynamic>?;
    if (timeslot == null) return const SizedBox.shrink();

    final dayOfWeek = timeslot['dayofweek']?.toString() ?? 'N/A';
    final startTime = timeslot['starttime']?.toString() ?? 'N/A';
    final endTime = timeslot['endtime']?.toString() ?? 'N/A';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, size: 18, color: AppColors.primaryBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Scheduled: $dayOfWeek, $startTime - $endTime',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 13,
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateStatusRow(ColorScheme colorScheme, bool isDark, bool isSmallScreen, bool isCompact, bool isTablet) {
    if (isSmallScreen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDateSelection(colorScheme, isDark, isSmallScreen, isCompact),
          const SizedBox(height: 16),
          _buildStatusSelection(colorScheme, isDark, isSmallScreen, isCompact),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildDateSelection(colorScheme, isDark, isSmallScreen, isCompact),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatusSelection(colorScheme, isDark, isSmallScreen, isCompact),
        ),
      ],
    );
  }

  Widget _buildDateSelection(ColorScheme colorScheme, bool isDark, bool isSmallScreen, bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 15,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectedCourseSchedule == null
              ? null
              : () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now(),
              selectableDayPredicate: (DateTime date) {
                // Only allow dates that match the course schedule
                return _isDateMatchingSchedule(date);
              },
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
            if (date != null) {
              setState(() => _selectedDate = date);
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: EdgeInsets.all(isCompact ? 12 : 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedCourseSchedule == null
                    ? colorScheme.outline.withOpacity(0.3)
                    : AppColors.primaryBlue.withOpacity(0.3),
              ),
              borderRadius: BorderRadius.circular(14),
              color: _selectedCourseSchedule == null
                  ? (isDark ? colorScheme.surface.withOpacity(0.5) : Colors.grey.shade100)
                  : (isDark ? colorScheme.surface : Colors.white),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedCourseSchedule == null
                        ? 'Select a course first'
                        : DateFormat('MMM dd, yyyy').format(_selectedDate),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 14,
                      color: _selectedCourseSchedule == null
                          ? colorScheme.onSurface.withOpacity(0.4)
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_rounded,
                  size: isSmallScreen ? 18 : 20,
                  color: _selectedCourseSchedule == null
                      ? colorScheme.onSurface.withOpacity(0.3)
                      : AppColors.primaryBlue,
                ),
              ],
            ),
          ),
        ),
        if (_selectedCourseSchedule != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: AppColors.primaryBlue),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Only ${_getScheduledDayName()} dates are selectable',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 11,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusSelection(ColorScheme colorScheme, bool isDark, bool isSmallScreen, bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 15,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedStatus,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
            filled: true,
            fillColor: isDark ? colorScheme.surface : Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isCompact ? 10 : 12,
              vertical: isCompact ? 12 : 14,
            ),
          ),
          dropdownColor: colorScheme.surface,
          style: TextStyle(
            fontSize: isSmallScreen ? 13 : 14,
            color: colorScheme.onSurface,
          ),
          items: ['Present', 'Absent'].map((status) {
            return DropdownMenuItem(
              value: status,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStatusIcon(status),
                    size: isSmallScreen ? 16 : 18,
                    color: _getStatusColor(status),
                  ),
                  const SizedBox(width: 8),
                  Text(status),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedStatus = value!);
          },
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.secondaryOrange.withOpacity(isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: AppColors.secondaryOrange),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Note: Database only supports Present/Absent',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 11,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentSearch(ColorScheme colorScheme, bool isDark, bool isSmallScreen, bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Students',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 15,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
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
              prefixIcon: Icon(Icons.search_rounded, color: AppColors.primaryBlue, size: isSmallScreen ? 20 : 24),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: Icon(
                  Icons.clear_rounded,
                  color: colorScheme.onSurface.withOpacity(0.5),
                  size: isSmallScreen ? 20 : 24,
                ),
                onPressed: () {
                  _searchController.clear();
                  _filterStudents('');
                },
              )
                  : null,
              hintText: 'Search by name or email...',
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.4),
                fontSize: isSmallScreen ? 13 : 14,
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
              contentPadding: EdgeInsets.symmetric(
                horizontal: isCompact ? 12 : 16,
                vertical: isCompact ? 12 : 14,
              ),
            ),
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: isSmallScreen ? 13 : 14,
            ),
            onChanged: _filterStudents,
          ),
        ),
        if (_searchQuery.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Found ${_filteredStudents.length} student(s)',
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 12,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStudentListHeader(ColorScheme colorScheme, bool isSmallScreen, bool isCompact) {
    if (isSmallScreen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Select Students',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selectedStudents.length}/${_filteredStudents.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  if (_selectedStudents.length == _filteredStudents.length) {
                    _selectedStudents.clear();
                  } else {
                    _selectedStudents = _filteredStudents
                        .map((s) => _getStudentId(s))
                        .where((id) => id.isNotEmpty)
                        .toList();
                  }
                });
              },
              icon: Icon(
                _selectedStudents.length == _filteredStudents.length
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                color: AppColors.primaryBlue,
                size: 18,
              ),
              label: Text(
                _selectedStudents.length == _filteredStudents.length
                    ? 'Deselect All'
                    : 'Select All',
                style: TextStyle(color: AppColors.primaryBlue, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primaryBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              'Select Students',
              style: TextStyle(
                fontSize: isCompact ? 14 : 15,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 8 : 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_selectedStudents.length}/${_filteredStudents.length}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 11 : 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: () {
            setState(() {
              if (_selectedStudents.length == _filteredStudents.length) {
                _selectedStudents.clear();
              } else {
                _selectedStudents = _filteredStudents
                    .map((s) => _getStudentId(s))
                    .where((id) => id.isNotEmpty)
                    .toList();
              }
            });
          },
          icon: Icon(
            _selectedStudents.length == _filteredStudents.length
                ? Icons.check_box_rounded
                : Icons.check_box_outline_blank_rounded,
            color: AppColors.primaryBlue,
            size: isSmallScreen ? 18 : 20,
          ),
          label: Text(
            _selectedStudents.length == _filteredStudents.length
                ? 'Deselect All'
                : 'Select All',
            style: TextStyle(
              color: AppColors.primaryBlue,
              fontSize: isSmallScreen ? 12 : 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentList(ColorScheme colorScheme, bool isDark, bool isSmallScreen, bool isCompact) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(16),
        color: isDark ? colorScheme.surface : Colors.white,
      ),
      child: _filteredStudents.isEmpty
          ? Padding(
        padding: EdgeInsets.all(isCompact ? 24 : 32),
        child: Center(
          child: Text(
            'No students match your search',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.6),
              fontSize: isSmallScreen ? 13 : 14,
            ),
          ),
        ),
      )
          : ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _filteredStudents.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: colorScheme.outline.withOpacity(0.15),
        ),
        itemBuilder: (context, index) {
          final student = _filteredStudents[index];
          final studentId = _getStudentId(student);
          final name = _getStudentName(student);
          final code = _getStudentCode(student);
          final isSelected = _selectedStudents.contains(studentId);

          return CheckboxListTile(
            value: isSelected,
            onChanged: (checked) {
              setState(() {
                if (checked == true) {
                  _selectedStudents.add(studentId);
                } else {
                  _selectedStudents.remove(studentId);
                }
              });
            },
            title: Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
                fontSize: isSmallScreen ? 13 : 14,
              ),
            ),
            subtitle: Text(
              'ID: $code',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: isSmallScreen ? 11 : 12,
              ),
            ),
            activeColor: AppColors.primaryBlue,
            checkboxShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isCompact ? 8 : 12,
              vertical: isCompact ? 4 : 8,
            ),
            secondary: Container(
              width: isSmallScreen ? 36 : 40,
              height: isSmallScreen ? 36 : 40,
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected
                    ? null
                    : colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubmitButton(bool isSmallScreen, bool isCompact) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _selectedStudents.isEmpty ? null : _submitAttendance,
        icon: Icon(
          Icons.check_circle_rounded,
          size: isSmallScreen ? 18 : 20,
        ),
        label: Text(
          _selectedStudents.isEmpty
              ? 'Select students to continue'
              : isSmallScreen
              ? 'Record (${_selectedStudents.length})'
              : 'Record Attendance (${_selectedStudents.length} students)',
          style: TextStyle(
            fontSize: isSmallScreen ? 13 : (isCompact ? 14 : 15),
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.tertiaryLightGray,
          disabledForegroundColor: Colors.white54,
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 14 : 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildEmptyStudentsState(ColorScheme colorScheme, bool isDark, bool isSmallScreen, bool isCompact) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 32 : 48),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
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
                size: isSmallScreen ? 44 : 56,
                color: AppColors.primaryBlue,
              ),
            ),
            SizedBox(height: isCompact ? 16 : 20),
            Text(
              'No students found',
              style: TextStyle(
                fontSize: isSmallScreen ? 15 : 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: isCompact ? 6 : 8),
            Text(
              'No students are enrolled in this ${widget.role == 'faculty' ? 'course' : 'section'} yet',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: isSmallScreen ? 13 : 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Present':
        return Icons.check_circle_rounded;
      case 'Absent':
        return Icons.cancel_rounded;
      default:
        return Icons.circle;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Present':
        return AppColors.accentGreen;
      case 'Absent':
        return AppColors.accentRed;
      default:
        return AppColors.tertiaryLightGray;
    }
  }
}