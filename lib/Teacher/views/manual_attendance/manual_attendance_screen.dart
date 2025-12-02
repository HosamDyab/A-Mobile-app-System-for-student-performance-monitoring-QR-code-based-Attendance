import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_app_bar.dart';

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
  List<Map<String, dynamic>> _students = [];
  List<String> _selectedStudents = [];

  String? _selectedCourse;
  DateTime _selectedDate = DateTime.now();
  String _selectedStatus = 'Present';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);

    try {
      final table = widget.role == 'faculty'
          ? 'LectureCourseOffering'
          : 'SectionCourseOffering';
      final idField = widget.role == 'faculty' ? 'FacultyId' : 'TAId';

      final response = await _supabase
          .from(table)
          .select('*, Course(*)')
          .eq(idField, widget.facultyId);

      setState(() {
        _courses = List<Map<String, dynamic>>.from(response as List);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading courses: $e')),
        );
      }
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedCourse == null) return;

    setState(() => _isLoading = true);

    try {
      // Determine the correct table and field based on role
      final String table = widget.role == 'faculty'
          ? 'StudentCourseEnrollment'
          : 'StudentSection';
      final String fieldName =
          widget.role == 'faculty' ? 'LectureOfferingId' : 'SectionOfferingId';

      // Load students enrolled in the selected course/section
      final response = await _supabase
          .from(table)
          .select('StudentId, Student(StudentCode, User(FullName))')
          .eq(fieldName, _selectedCourse!);

      setState(() {
        _students = List<Map<String, dynamic>>.from(response as List);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final errorMessage = e.toString();
        final isTableError = errorMessage.contains('StudentCourseEnrollment') ||
            errorMessage.contains('StudentSection');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isTableError
                ? 'Database table not found. Please run create_student_tables.sql in Supabase.'
                : 'Error loading students: $errorMessage'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Dismiss',
              onPressed: () {},
            ),
          ),
        );

        print('Error details: $errorMessage');
        print('Role: ${widget.role}');
        print('Selected course: $_selectedCourse');
      }
    }
  }

  Future<void> _submitAttendance() async {
    if (_selectedCourse == null || _selectedStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select course and students')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create a lecture instance if not exists
      final instanceId =
          'MANUAL-$_selectedCourse-${_selectedDate.millisecondsSinceEpoch}';

      // Upsert lecture instance (insert or ignore if exists)
      await _supabase.from('LectureInstance').upsert({
        'InstanceId': instanceId,
        'LectureOfferingId': _selectedCourse,
        'InstanceDate': _selectedDate.toIso8601String(),
        'WeekNumber': _getWeekNumber(_selectedDate),
      }, onConflict: 'InstanceId');

      // Insert attendance records for each student
      final attendanceRecords = _selectedStudents.map((studentId) {
        return {
          'AttendanceId':
              'ATT-$studentId-${DateTime.now().millisecondsSinceEpoch}',
          'StudentId': studentId,
          'InstanceId': instanceId,
          'ScanTime': DateTime.now().toIso8601String(),
          'Status': _selectedStatus,
        };
      }).toList();

      await _supabase.from('LectureQR').insert(attendanceRecords);

      setState(() {
        _isLoading = false;
        _selectedStudents.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Attendance recorded for ${attendanceRecords.length} students'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting attendance: $e')),
        );
      }
    }
  }

  int _getWeekNumber(DateTime date) {
    // Calculate week number (simple implementation)
    final startOfYear = DateTime(date.year, 1, 1);
    final daysSinceStart = date.difference(startOfYear).inDays;
    return (daysSinceStart / 7).ceil();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Manual Attendance'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFD88A2D).withOpacity(0.1),
                          const Color(0xFF2E7D32).withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFD88A2D).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD88A2D),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.edit_calendar,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Manual Attendance Entry',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Record attendance for students manually',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Course Selection
                  const Text(
                    'Select Course',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCourse,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Choose a course',
                      prefixIcon:
                          const Icon(Icons.book, color: Color(0xFFD88A2D)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: _courses.map((course) {
                      final courseData =
                          course['Course'] as Map<String, dynamic>;
                      return DropdownMenuItem<String>(
                        value: course['LectureOfferingId']?.toString() ??
                            course['SectionOfferingId']?.toString(),
                        child: Text(
                          '${courseData['Code']} - ${courseData['Title']}',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCourse = value;
                        _students.clear();
                        _selectedStudents.clear();
                      });
                      _loadStudents();
                    },
                  ),
                  const SizedBox(height: 20),

                  // Date and Status Row
                  Row(
                    children: [
                      // Date Selection
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Select Date',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime.now()
                                      .subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setState(() => _selectedDate = date);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey[50],
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat('MMM dd, yyyy')
                                          .format(_selectedDate),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const Icon(Icons.calendar_today,
                                        size: 20, color: Color(0xFFD88A2D)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Status Selection
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Status',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedStatus,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 16),
                              ),
                              items: ['Present', 'Absent', 'Late', 'Excused']
                                  .map((status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getStatusIcon(status),
                                        size: 18,
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
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Student List
                  if (_students.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Select Students',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD88A2D),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_selectedStudents.length}/${_students.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              if (_selectedStudents.length ==
                                  _students.length) {
                                _selectedStudents.clear();
                              } else {
                                _selectedStudents = _students
                                    .map((s) => s['StudentId'].toString())
                                    .toList();
                              }
                            });
                          },
                          icon: Icon(
                            _selectedStudents.length == _students.length
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            color: const Color(0xFFD88A2D),
                          ),
                          label: Text(
                            _selectedStudents.length == _students.length
                                ? 'Deselect All'
                                : 'Select All',
                            style: const TextStyle(color: Color(0xFFD88A2D)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _students.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: Colors.grey.shade200,
                        ),
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          final studentData =
                              student['Student'] as Map<String, dynamic>;
                          final studentId = student['StudentId'].toString();
                          final name =
                              studentData['User']?['FullName'] ?? 'Unknown';
                          final code = studentData['StudentCode'] ?? 'N/A';
                          final isSelected =
                              _selectedStudents.contains(studentId);

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
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'Code: $code',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            activeColor: const Color(0xFFD88A2D),
                            secondary: CircleAvatar(
                              backgroundColor: isSelected
                                  ? const Color(0xFFD88A2D).withOpacity(0.2)
                                  : Colors.grey[200],
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFFD88A2D)
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _selectedStudents.isEmpty
                            ? null
                            : _submitAttendance,
                        icon: const Icon(Icons.check_circle),
                        label: Text(
                          _selectedStudents.isEmpty
                              ? 'Select students to continue'
                              : 'Record Attendance (${_selectedStudents.length} students)',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          disabledForegroundColor: Colors.grey[600],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],

                  if (_selectedCourse != null &&
                      _students.isEmpty &&
                      !_isLoading)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Column(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No students enrolled in this course',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Present':
        return Icons.check_circle;
      case 'Absent':
        return Icons.cancel;
      case 'Late':
        return Icons.schedule;
      case 'Excused':
        return Icons.info;
      default:
        return Icons.circle;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Present':
        return Colors.green;
      case 'Absent':
        return Colors.red;
      case 'Late':
        return Colors.orange;
      case 'Excused':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
