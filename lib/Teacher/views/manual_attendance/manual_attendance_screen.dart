import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../../shared/utils/app_colors.dart';
import '../widgets/custom_app_bar.dart';

/// Manual Attendance Screen - Record attendance manually for students.
///
/// Features:
/// - Course selection dropdown
/// - Date picker with modern design
/// - Status selection (Present, Absent, Late, Excused)
/// - Student list with multi-select and search
/// - Theme-aware styling (light/dark mode)
/// - Fully responsive and adaptive
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
            .from('LectureCourseOffering')
            .select('*, Course(*)')
            .eq('FacultyId', widget.facultyId);

        setState(() {
          _courses = List<Map<String, dynamic>>.from(response as List);
          _isLoading = false;
        });
      } else {
        final response = await _supabase
            .from('SectionCourseOffering')
            .select('*, Course(*)')
            .eq('TAId', widget.facultyId);

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
          final sectionsResponse = await _supabase
              .from('SectionCourseOffering')
              .select('SectionOfferingId')
              .eq('LectureOfferingId', _selectedCourse!);

          final sectionIds = (sectionsResponse as List)
              .map((s) => s['SectionOfferingId'])
              .whereType<dynamic>()
              .toList();

          if (sectionIds.isNotEmpty) {
            final studentsResponse = await _supabase
                .from('StudentSection')
                .select(
                'StudentId, Student(StudentId, StudentCode, User(FullName))')
                .inFilter('SectionOfferingId', sectionIds);

            studentsList =
            List<Map<String, dynamic>>.from(studentsResponse as List);
          }
        } catch (e) {
          debugPrint('Section query failed, trying direct student load: $e');
        }

        if (studentsList.isEmpty) {
          try {
            final allStudentsResponse = await _supabase
                .from('Student')
                .select('StudentId, StudentCode, User(FullName)')
                .limit(100);

            studentsList = (allStudentsResponse as List).map((s) {
              return {
                'StudentId': s['StudentId'],
                'Student': {
                  'StudentId': s['StudentId'],
                  'StudentCode': s['StudentCode'],
                  'User': s['User'],
                },
              };
            }).toList();
          } catch (e) {
            debugPrint('Direct student load failed: $e');
          }
        }
      } else {
        try {
          final response = await _supabase
              .from('StudentSection')
              .select(
              'StudentId, Student(StudentId, StudentCode, User(FullName))')
              .eq('SectionOfferingId', _selectedCourse!);

          studentsList = List<Map<String, dynamic>>.from(response as List);
        } catch (e) {
          debugPrint('TA section query failed: $e');
          try {
            final allStudentsResponse = await _supabase
                .from('Student')
                .select('StudentId, StudentCode, User(FullName)')
                .limit(100);

            studentsList = (allStudentsResponse as List).map((s) {
              return {
                'StudentId': s['StudentId'],
                'Student': {
                  'StudentId': s['StudentId'],
                  'StudentCode': s['StudentCode'],
                  'User': s['User'],
                },
              };
            }).toList();
          } catch (e2) {
            debugPrint('Fallback student load failed: $e2');
          }
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
          final studentData = student['Student'] as Map<String, dynamic>?;
          final name = (studentData?['User']?['FullName'] ?? '')
              .toString()
              .toLowerCase();
          final code =
          (studentData?['StudentCode'] ?? '').toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || code.contains(searchLower);
        }).toList();
      }
    });
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

      String finalInstanceId;

      if (isFaculty) {
        // === FACULTY: Use LectureInstance and LectureQR ===

        // Check if lecture instance already exists
        final existingInstance = await _supabase
            .from('LectureInstance')
            .select('InstanceId')
            .eq('LectureOfferingId', _selectedCourse!)
            .eq('MeetingDate', dateStr)
            .eq('StartTime', '00:00:00')
            .maybeSingle();

        if (existingInstance == null) {
          // Create new lecture instance
          final insertResponse = await _supabase
              .from('LectureInstance')
              .insert({
            'LectureOfferingId': _selectedCourse,
            'MeetingDate': dateStr,
            'StartTime': '00:00:00',
            'EndTime': '23:59:59',
            'Topic': 'Manual Attendance Entry',
            'IsCancelled': false,
          })
              .select('InstanceId')
              .single();

          finalInstanceId = insertResponse['InstanceId'];
        } else {
          finalInstanceId = existingInstance['InstanceId'];
        }

        // Check existing attendance for this lecture instance
        final existingAttendance = await _supabase
            .from('LectureQR')
            .select('StudentId')
            .eq('InstanceId', finalInstanceId)
            .inFilter('StudentId', _selectedStudents);

        final existingStudentIds = (existingAttendance as List)
            .map((a) => a['StudentId'].toString())
            .toSet();

        // Insert new attendance records
        final newStudents = _selectedStudents
            .where((id) => !existingStudentIds.contains(id))
            .toList();

        if (newStudents.isNotEmpty) {
          final attendanceRecords = newStudents.map((studentId) {
            return {
              'StudentId': studentId,
              'InstanceId': finalInstanceId,
              'ScanTime': DateTime.now().toIso8601String(),
              'Status': _selectedStatus,
            };
          }).toList();

          await _supabase.from('LectureQR').insert(attendanceRecords);
        }

        // Update existing attendance records
        final updateStudents = _selectedStudents
            .where((id) => existingStudentIds.contains(id))
            .toList();

        if (updateStudents.isNotEmpty) {
          for (final studentId in updateStudents) {
            await _supabase
                .from('LectureQR')
                .update({
              'Status': _selectedStatus,
              'ScanTime': DateTime.now().toIso8601String(),
            })
                .eq('InstanceId', finalInstanceId)
                .eq('StudentId', studentId);
          }
        }

        // Show success message
        if (mounted) {
          final totalRecorded = newStudents.length + updateStudents.length;
          final message = newStudents.isNotEmpty && updateStudents.isNotEmpty
              ? 'Recorded attendance for $totalRecorded students (${newStudents.length} new, ${updateStudents.length} updated)'
              : newStudents.isNotEmpty
              ? 'Attendance recorded for ${newStudents.length} students'
              : 'Attendance updated for ${updateStudents.length} students';

          _showSnackBar(message, isError: false);
        }
      } else {
        // === TA: Use SectionInstance and SectionQR ===

        // Check if section instance already exists
        final existingInstance = await _supabase
            .from('SectionInstance')
            .select('InstanceId')
            .eq('SectionOfferingId', _selectedCourse!)
            .eq('MeetingDate', dateStr)
            .eq('StartTime', '00:00:00')
            .maybeSingle();

        if (existingInstance == null) {
          // Create new section instance
          final insertResponse = await _supabase
              .from('SectionInstance')
              .insert({
            'SectionOfferingId': _selectedCourse,
            'MeetingDate': dateStr,
            'StartTime': '00:00:00',
            'EndTime': '23:59:59',
            'Topic': 'Manual Attendance Entry',
            'IsCancelled': false,
          })
              .select('InstanceId')
              .single();

          finalInstanceId = insertResponse['InstanceId'];
        } else {
          finalInstanceId = existingInstance['InstanceId'];
        }

        // Check existing attendance for this section instance
        final existingAttendance = await _supabase
            .from('SectionQR')
            .select('StudentId')
            .eq('InstanceId', finalInstanceId)
            .inFilter('StudentId', _selectedStudents);

        final existingStudentIds = (existingAttendance as List)
            .map((a) => a['StudentId'].toString())
            .toSet();

        // Insert new attendance records
        final newStudents = _selectedStudents
            .where((id) => !existingStudentIds.contains(id))
            .toList();

        if (newStudents.isNotEmpty) {
          final attendanceRecords = newStudents.map((studentId) {
            return {
              'StudentId': studentId,
              'InstanceId': finalInstanceId,
              'ScanTime': DateTime.now().toIso8601String(),
              'Status': _selectedStatus,
            };
          }).toList();

          await _supabase.from('SectionQR').insert(attendanceRecords);
        }

        // Update existing attendance records
        final updateStudents = _selectedStudents
            .where((id) => existingStudentIds.contains(id))
            .toList();

        if (updateStudents.isNotEmpty) {
          for (final studentId in updateStudents) {
            await _supabase
                .from('SectionQR')
                .update({
              'Status': _selectedStatus,
              'ScanTime': DateTime.now().toIso8601String(),
            })
                .eq('InstanceId', finalInstanceId)
                .eq('StudentId', studentId);
          }
        }

        // Show success message
        if (mounted) {
          final totalRecorded = newStudents.length + updateStudents.length;
          final message = newStudents.isNotEmpty && updateStudents.isNotEmpty
              ? 'Recorded attendance for $totalRecorded students (${newStudents.length} new, ${updateStudents.length} updated)'
              : newStudents.isNotEmpty
              ? 'Attendance recorded for ${newStudents.length} students'
              : 'Attendance updated for ${updateStudents.length} students';

          _showSnackBar(message, isError: false);
        }
      }

      setState(() {
        _isLoading = false;
        _selectedStudents.clear();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnackBar('Error submitting attendance: $e', isError: true);
      }
      debugPrint('Error submitting attendance: $e');
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
    final studentData = student['Student'] as Map<String, dynamic>?;
    return studentData?['User']?['FullName'] ?? 'Unknown Student';
  }

  String _getStudentCode(Map<String, dynamic> student) {
    final studentData = student['Student'] as Map<String, dynamic>?;
    return studentData?['StudentCode'] ?? 'N/A';
  }

  String _getStudentId(Map<String, dynamic> student) {
    return student['StudentId']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    // Responsive breakpoints
    final isSmallScreen = size.width < 360;
    final isCompact = size.width < 400;
    final isTablet = size.width >= 600;
    final isDesktop = size.width >= 1024;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    // Adaptive padding
    final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 24.0 : (isCompact ? 12.0 : 16.0));
    final verticalPadding = isTablet ? 24.0 : 16.0;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Manual Attendance'),
      body: _isLoading
          ? Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : isLandscape && isTablet
          ? _buildLandscapeLayout(context, colorScheme, isDark, isSmallScreen, isCompact, isTablet, isDesktop, horizontalPadding)
          : _buildPortraitLayout(context, colorScheme, isDark, isSmallScreen, isCompact, isTablet, isDesktop, horizontalPadding, verticalPadding),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, ColorScheme colorScheme, bool isDark, bool isSmallScreen, bool isCompact, bool isTablet, bool isDesktop, double horizontalPadding) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel - Course selection and date
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
              ],
            ),
          ),
        ),

        // Right panel - Student list
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
                if (_selectedCourse != null &&
                    _allStudents.isEmpty &&
                    !_isLoading)
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

              if (_selectedCourse != null &&
                  _allStudents.isEmpty &&
                  !_isLoading)
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
            // prefixIcon: Icon(
            //   Icons.book_rounded,
            //   color: AppColors.primaryBlue,
            //   size: isSmallScreen ? 20 : 24,
            // ),
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
            final courseData = course['Course'] as Map<String, dynamic>?;
            final id = widget.role == 'faculty'
                ? course['LectureOfferingId']?.toString()
                : course['SectionOfferingId']?.toString();
            return DropdownMenuItem<String>(
              value: id,
              child: Text(
                courseData != null
                    ? '${courseData['Code']} - ${courseData['Title']}'
                    : 'Unknown Course',
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
            });
            _loadStudents();
          },
        ),
      ],
    );
  }

  Widget _buildDateStatusRow(ColorScheme colorScheme, bool isDark, bool isSmallScreen, bool isCompact, bool isTablet) {
    // Stack vertically on very small screens
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
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now(),
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
                  color: AppColors.primaryBlue.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(14),
              color: isDark ? colorScheme.surface : Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    DateFormat('MMM dd, yyyy').format(_selectedDate),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 14,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_rounded,
                  size: isSmallScreen ? 18 : 20,
                  color: AppColors.primaryBlue,
                ),
              ],
            ),
          ),
        ),
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
              borderSide:
              BorderSide(color: AppColors.primaryBlue, width: 2),
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
          items: ['Present', 'Absent', 'Late', 'Excused'].map((status) {
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
              prefixIcon: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Icon(
                      Icons.search_rounded,
                      color: AppColors.primaryBlue,
                      size: isSmallScreen ? 20 : 24,
                    ),
                  );
                },
              ),
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
              hintText: 'Search by name or code...',
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
    // Stack vertically on very small screens
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
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 13,
                ),
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
              'Code: $code',
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
              'No students are enrolled in this course yet',
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
      case 'Late':
        return Icons.schedule_rounded;
      case 'Excused':
        return Icons.info_rounded;
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
      case 'Late':
        return AppColors.secondaryOrange;
      case 'Excused':
        return AppColors.primaryBlue;
      default:
        return AppColors.tertiaryLightGray;
    }
  }
}