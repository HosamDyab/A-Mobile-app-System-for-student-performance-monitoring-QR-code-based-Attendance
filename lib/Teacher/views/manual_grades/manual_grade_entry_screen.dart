import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/custom_app_bar.dart';

class ManualGradeEntryScreen extends StatefulWidget {
  final String facultyId;
  final String role;

  const ManualGradeEntryScreen({
    super.key,
    required this.facultyId,
    required this.role,
  });

  @override
  State<ManualGradeEntryScreen> createState() => _ManualGradeEntryScreenState();
}

class _ManualGradeEntryScreenState extends State<ManualGradeEntryScreen> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _students = [];
  final Map<String, Map<String, TextEditingController>> _gradeControllers = {};

  String? _selectedCourse;
  bool _courseHasLab = false;
  bool _courseHasMiniProject = false;

  String _selectedGradeType = 'Midterm';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var studentControllers in _gradeControllers.values) {
      for (var controller in studentControllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
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

  List<String> _getAvailableGradeTypes() {
    final types = <String>[
      'Midterm',
      'Quiz1',
      'Quiz2',
      'Quiz3',
      'Assignment1',
      'Assignment2',
      'Assignment3',
    ];

    if (_courseHasLab) {
      types.add('Lab');
    }

    if (_courseHasMiniProject) {
      types.add('MiniProject');
    }

    types.add('Final');

    return types;
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

      // Load students enrolled in the selected course with their current grades
      final response = await _supabase.from(table).select('''
            StudentId, 
            Student(
              StudentCode, 
              User(FullName)
            ),
            StudentGrade(
              MidtermGrade,
              Quiz1Grade,
              Quiz2Grade,
              Quiz3Grade,
              Assignment1Grade,
              Assignment2Grade,
              Assignment3Grade,
              LabGrade,
              MiniProjectGrade,
              FinalGrade
            )
          ''').eq(fieldName, _selectedCourse!);

      final studentsList = List<Map<String, dynamic>>.from(response as List);

      // Initialize controllers for all grade types
      _gradeControllers.clear();
      for (var student in studentsList) {
        final studentId = student['StudentId'].toString();
        final grades = student['StudentGrade'] as Map<String, dynamic>?;

        _gradeControllers[studentId] = {
          'Midterm': TextEditingController(
            text: grades?['MidtermGrade']?.toString() ?? '',
          ),
          'Quiz1': TextEditingController(
            text: grades?['Quiz1Grade']?.toString() ?? '',
          ),
          'Quiz2': TextEditingController(
            text: grades?['Quiz2Grade']?.toString() ?? '',
          ),
          'Quiz3': TextEditingController(
            text: grades?['Quiz3Grade']?.toString() ?? '',
          ),
          'Assignment1': TextEditingController(
            text: grades?['Assignment1Grade']?.toString() ?? '',
          ),
          'Assignment2': TextEditingController(
            text: grades?['Assignment2Grade']?.toString() ?? '',
          ),
          'Assignment3': TextEditingController(
            text: grades?['Assignment3Grade']?.toString() ?? '',
          ),
          'Lab': TextEditingController(
            text: grades?['LabGrade']?.toString() ?? '',
          ),
          'MiniProject': TextEditingController(
            text: grades?['MiniProjectGrade']?.toString() ?? '',
          ),
          'Final': TextEditingController(
            text: grades?['FinalGrade']?.toString() ?? '',
          ),
        };
      }

      setState(() {
        _students = studentsList;
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
            content: Text(
              isTableError 
                  ? 'Database table not found. Please run create_student_tables.sql in Supabase.'
                  : 'Error loading students: $errorMessage'
            ),
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

  Future<void> _submitGrades() async {
    if (_selectedCourse == null || _students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select course and enter grades')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Prepare grade updates
      final gradeUpdates = <Map<String, dynamic>>[];

      for (var student in _students) {
        final studentId = student['StudentId'].toString();
        final controllers = _gradeControllers[studentId]!;

        final gradeData = {
          'StudentId': studentId,
          'LectureOfferingId': _selectedCourse,
          'MidtermGrade': double.tryParse(controllers['Midterm']!.text),
          'Quiz1Grade': double.tryParse(controllers['Quiz1']!.text),
          'Quiz2Grade': double.tryParse(controllers['Quiz2']!.text),
          'Quiz3Grade': double.tryParse(controllers['Quiz3']!.text),
          'Assignment1Grade': double.tryParse(controllers['Assignment1']!.text),
          'Assignment2Grade': double.tryParse(controllers['Assignment2']!.text),
          'Assignment3Grade': double.tryParse(controllers['Assignment3']!.text),
          'LabGrade': double.tryParse(controllers['Lab']!.text),
          'MiniProjectGrade': double.tryParse(controllers['MiniProject']!.text),
          'FinalGrade': double.tryParse(controllers['Final']!.text),
        };

        gradeUpdates.add(gradeData);
      }

      // Upsert grades
      await _supabase.from('StudentGrade').upsert(
            gradeUpdates,
            onConflict: 'StudentId,LectureOfferingId',
          );

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Grades saved for ${gradeUpdates.length} students'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving grades: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Manual Grade Entry'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Course Selection
                  const Text(
                    'Select Course',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCourse,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Choose a course',
                      prefixIcon: Icon(Icons.book, color: Color(0xFFD88A2D)),
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
                      });
                      _loadStudents();
                    },
                  ),
                  const SizedBox(height: 20),

                  // Course Settings (Lab & Mini Project)
                  if (_selectedCourse != null) ...[
                    const Text(
                      'Course Settings',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            value: _courseHasLab,
                            onChanged: (value) {
                              setState(() {
                                _courseHasLab = value ?? false;
                              });
                            },
                            title: const Text('Has Lab'),
                            subtitle:
                                const Text('Course includes lab component'),
                            activeColor: const Color(0xFFD88A2D),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: CheckboxListTile(
                            value: _courseHasMiniProject,
                            onChanged: (value) {
                              setState(() {
                                _courseHasMiniProject = value ?? false;
                              });
                            },
                            title: const Text('Has Mini Project'),
                            subtitle: const Text('Course includes project'),
                            activeColor: const Color(0xFFD88A2D),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Grade Type Selector
                  if (_students.isNotEmpty) ...[
                    const Text(
                      'Select Grade Type',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _getAvailableGradeTypes().map((type) {
                        return ChoiceChip(
                          label: Text(type),
                          selected: _selectedGradeType == type,
                          onSelected: (selected) {
                            setState(() => _selectedGradeType = type);
                          },
                          selectedColor: const Color(0xFFD88A2D),
                          backgroundColor: Colors.grey[200],
                          labelStyle: TextStyle(
                            color: _selectedGradeType == type
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: _selectedGradeType == type
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    // Grade type info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 20, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Entering grades for: $_selectedGradeType (Max: ${_getMaxGrade()})',
                              style: TextStyle(
                                color: Colors.blue.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Students List with Grade Input
                    const Text(
                      'Enter Grades',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        final studentData =
                            student['Student'] as Map<String, dynamic>;
                        final studentId = student['StudentId'].toString();
                        final name =
                            studentData['User']?['FullName'] ?? 'Unknown';
                        final code = studentData['StudentCode'] ?? 'N/A';
                        final controller =
                            _gradeControllers[studentId]![_selectedGradeType]!;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(name),
                            subtitle: Text('Code: $code'),
                            trailing: SizedBox(
                              width: 100,
                              child: TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  hintText: '0-100',
                                  suffix: Text('/$_getMaxGrade()'),
                                ),
                                onChanged: (value) {
                                  // Validate range
                                  final grade = double.tryParse(value);
                                  if (grade != null &&
                                      (grade < 0 || grade > _getMaxGrade())) {
                                    controller.text = '';
                                  }
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submitGrades,
                        icon: const Icon(Icons.save),
                        label:
                            Text('Save Grades (${_students.length} students)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],

                  if (_selectedCourse != null &&
                      _students.isEmpty &&
                      !_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No students enrolled in this course',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  int _getMaxGrade() {
    switch (_selectedGradeType) {
      case 'Midterm':
        return 20; // 20% of total grade
      case 'Final':
        return 40; // 40% of total grade
      case 'Quiz1':
      case 'Quiz2':
      case 'Quiz3':
        return 5; // 5% each quiz
      case 'Assignment1':
      case 'Assignment2':
      case 'Assignment3':
        return 5; // 5% each assignment
      case 'Lab':
        return 10; // 10% for lab
      case 'MiniProject':
        return 10; // 10% for mini project
      default:
        return 100;
    }
  }

  String _getGradeDescription() {
    switch (_selectedGradeType) {
      case 'Midterm':
        return 'Midterm Exam (20% of final grade)';
      case 'Final':
        return 'Final Exam (40% of final grade)';
      case 'Quiz1':
        return 'Quiz 1 (5% of final grade)';
      case 'Quiz2':
        return 'Quiz 2 (5% of final grade)';
      case 'Quiz3':
        return 'Quiz 3 (5% of final grade)';
      case 'Assignment1':
        return 'Assignment 1 (5% of final grade)';
      case 'Assignment2':
        return 'Assignment 2 (5% of final grade)';
      case 'Assignment3':
        return 'Assignment 3 (5% of final grade)';
      case 'Lab':
        return 'Lab Work (10% of final grade)';
      case 'MiniProject':
        return 'Mini Project (10% of final grade)';
      default:
        return '';
    }
  }
}
