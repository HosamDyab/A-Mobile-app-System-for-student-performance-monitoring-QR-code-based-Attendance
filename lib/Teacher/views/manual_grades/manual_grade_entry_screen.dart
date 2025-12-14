import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/utils/app_colors.dart';
import '../widgets/custom_app_bar.dart';

/// Manual Grade Entry Screen - Enter grades for students manually.
///
/// FIXES:
/// 1. Proper yearwork calculation with validation
/// 2. Grade component limits enforced
/// 3. TA submission blocked properly with clear messaging
/// 4. Lab score only enabled when course has lab
/// 5. Proper total grade calculation
/// 6. Better error handling and validation
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
  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  final Map<String, Map<String, TextEditingController>> _gradeControllers = {};

  String? _selectedCourse;
  String? _selectedCourseName;
  bool _courseHasLab = false;
  bool _courseHasMiniProject = false;

  String _selectedGradeType = 'Midterm';
  bool _isLoading = false;
  String _searchQuery = '';

  // Dynamic assignment and quiz counts
  int _assignmentCount = 3;
  int _quizCount = 3;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
      if (widget.role == 'faculty') {
        final response = await _supabase
            .from('lecturecourseoffering')
            .select('lectureofferingid, coursecode, academicyear, semester, course(coursecode, coursename, haslab)')
            .eq('facultysnn', widget.facultyId);

        setState(() {
          _courses = List<Map<String, dynamic>>.from(response as List);
          _isLoading = false;
        });
      } else {
        // For TA, get sections they're assigned to
        final response = await _supabase
            .from('sectionta')
            .select('sectionofferingid, sectioncourseoffering(sectionofferingid, coursecode, groupnumber, course(coursecode, coursename, haslab))')
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

  List<String> _getAvailableGradeTypes() {
    final types = <String>[
      'Midterm',
    ];

    // Add dynamic number of quizzes
    for (int i = 1; i <= _quizCount; i++) {
      types.add('Quiz$i');
    }

    // Add dynamic number of assignments
    for (int i = 1; i <= _assignmentCount; i++) {
      types.add('Assignment$i');
    }

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
      List<Map<String, dynamic>> studentsList = [];

      if (widget.role == 'faculty') {
        // For Faculty: Get students enrolled in this lecture offering
        try {
          final response = await _supabase
              .from('lectureenrollment')
              .select('studentid, student(studentid, fullname, email)')
              .eq('lectureofferingid', _selectedCourse!);

          studentsList = List<Map<String, dynamic>>.from(response as List);
        } catch (e) {
          debugPrint('Lecture enrollment query failed: $e');
        }
      } else {
        // For TA: Get students enrolled in this section
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

      // Initialize controllers for all grade types
      _gradeControllers.clear();
      for (var student in studentsList) {
        final studentId = _getStudentId(student);
        if (studentId.isNotEmpty) {
          _gradeControllers[studentId] = {};

          // Always create these controllers
          _gradeControllers[studentId]!['Midterm'] = TextEditingController();
          _gradeControllers[studentId]!['Final'] = TextEditingController();

          // Create dynamic quiz controllers
          for (int i = 1; i <= 10; i++) {
            _gradeControllers[studentId]!['Quiz$i'] = TextEditingController();
          }

          // Create dynamic assignment controllers
          for (int i = 1; i <= 10; i++) {
            _gradeControllers[studentId]!['Assignment$i'] = TextEditingController();
          }

          // Optional controllers
          _gradeControllers[studentId]!['Lab'] = TextEditingController();
          _gradeControllers[studentId]!['MiniProject'] = TextEditingController();
        }
      }

      // Load existing grades if faculty
      if (widget.role == 'faculty') {
        await _loadExistingGrades(studentsList);
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

  Future<void> _loadExistingGrades(List<Map<String, dynamic>> students) async {
    if (_selectedCourse == null) return;

    try {
      final response = await _supabase
          .from('evaluationsheet')
          .select('studentid, midterm, yearwork, labscore, finalexam')
          .eq('lectureofferingid', _selectedCourse!);

      final grades = List<Map<String, dynamic>>.from(response as List);

      for (var grade in grades) {
        final studentId = grade['studentid']?.toString();
        if (studentId != null && _gradeControllers.containsKey(studentId)) {
          final controllers = _gradeControllers[studentId]!;

          // Set midterm
          if (grade['midterm'] != null) {
            controllers['Midterm']?.text = grade['midterm'].toString();
          }

          // Set final
          if (grade['finalexam'] != null) {
            controllers['Final']?.text = grade['finalexam'].toString();
          }

          // Set lab score if applicable
          if (grade['labscore'] != null && _courseHasLab) {
            controllers['Lab']?.text = grade['labscore'].toString();
          }

          // Note: yearwork is calculated from components, so we don't load it
        }
      }
    } catch (e) {
      debugPrint('Error loading existing grades: $e');
    }
  }

  void _filterStudents(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredStudents = _allStudents;
      } else {
        _filteredStudents = _allStudents.where((student) {
          final name = _getStudentName(student).toLowerCase();
          final id = _getStudentId(student).toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || id.contains(searchLower);
        }).toList();
      }
    });
  }

  String _getStudentName(Map<String, dynamic> student) {
    final studentData = student['student'] as Map<String, dynamic>?;
    return studentData?['fullname'] ?? 'Unknown Student';
  }

  String _getStudentId(Map<String, dynamic> student) {
    return student['studentid']?.toString() ?? '';
  }

  bool _validateGrade(String value, int maxGrade) {
    final grade = double.tryParse(value);
    if (grade == null) return false;
    return grade >= 0 && grade <= maxGrade;
  }

  Future<void> _submitGrades() async {
    if (_selectedCourse == null || _filteredStudents.isEmpty) {
      _showSnackBar('Please select course and enter grades', isError: true);
      return;
    }

    // Only faculty can submit to evaluationsheet
    if (widget.role != 'faculty') {
      _showSnackBar(
        'Only faculty can submit grades. TAs can view and prepare grades but cannot save to evaluation sheet.',
        isError: true,
      );
      return;
    }

    // Validate all grades before submission
    List<String> errors = [];
    for (var student in _filteredStudents) {
      final studentId = _getStudentId(student);
      final controllers = _gradeControllers[studentId];
      if (controllers == null) continue;

      // Validate midterm (max 20)
      final midtermText = controllers['Midterm']?.text ?? '';
      if (midtermText.isNotEmpty && !_validateGrade(midtermText, 20)) {
        errors.add('${_getStudentName(student)}: Invalid midterm grade (max 20)');
      }

      // Validate quizzes (max 5 each)
      for (int i = 1; i <= _quizCount; i++) {
        final quizText = controllers['Quiz$i']?.text ?? '';
        if (quizText.isNotEmpty && !_validateGrade(quizText, 5)) {
          errors.add('${_getStudentName(student)}: Invalid Quiz$i grade (max 5)');
        }
      }

      // Validate assignments (max 5 each)
      for (int i = 1; i <= _assignmentCount; i++) {
        final assignText = controllers['Assignment$i']?.text ?? '';
        if (assignText.isNotEmpty && !_validateGrade(assignText, 5)) {
          errors.add('${_getStudentName(student)}: Invalid Assignment$i grade (max 5)');
        }
      }

      // Validate lab (max 10)
      if (_courseHasLab) {
        final labText = controllers['Lab']?.text ?? '';
        if (labText.isNotEmpty && !_validateGrade(labText, 10)) {
          errors.add('${_getStudentName(student)}: Invalid lab grade (max 10)');
        }
      }

      // Validate mini project (max 10)
      if (_courseHasMiniProject) {
        final projectText = controllers['MiniProject']?.text ?? '';
        if (projectText.isNotEmpty && !_validateGrade(projectText, 10)) {
          errors.add('${_getStudentName(student)}: Invalid mini project grade (max 10)');
        }
      }

      // Validate final (max 50 with lab, 60 without)
      final finalMax = _courseHasLab ? 50 : 60;
      final finalText = controllers['Final']?.text ?? '';
      if (finalText.isNotEmpty && !_validateGrade(finalText, finalMax)) {
        errors.add('${_getStudentName(student)}: Invalid final grade (max $finalMax)');
      }
    }

    if (errors.isNotEmpty) {
      _showSnackBar('Validation errors: ${errors.first}', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final gradeUpdates = <Map<String, dynamic>>[];

      for (var student in _filteredStudents) {
        final studentId = _getStudentId(student);
        if (studentId.isEmpty) continue;

        final controllers = _gradeControllers[studentId];
        if (controllers == null) continue;

        // Calculate yearwork from all components (quizzes + assignments + miniproject)
        double yearWork = 0;

        // Add quiz grades
        for (int i = 1; i <= _quizCount; i++) {
          yearWork += double.tryParse(controllers['Quiz$i']?.text ?? '0') ?? 0;
        }

        // Add assignment grades
        for (int i = 1; i <= _assignmentCount; i++) {
          yearWork += double.tryParse(controllers['Assignment$i']?.text ?? '0') ?? 0;
        }

        // Add mini project if applicable
        if (_courseHasMiniProject) {
          yearWork += double.tryParse(controllers['MiniProject']?.text ?? '0') ?? 0;
        }

        final midterm = double.tryParse(controllers['Midterm']?.text ?? '0') ?? 0;
        final finalExam = double.tryParse(controllers['Final']?.text ?? '0') ?? 0;
        final labScore = _courseHasLab
            ? (double.tryParse(controllers['Lab']?.text ?? '0') ?? 0)
            : null;

        // Calculate total grade
        // Total = Midterm (20) + YearWork (varies) + Lab (10 if exists) + Final (50 or 60)
        double totalGrade = midterm + yearWork + finalExam;
        if (labScore != null) {
          totalGrade += labScore;
        }

        // Skip if no grades entered at all
        if (midterm == 0 && yearWork == 0 && finalExam == 0 && (labScore == null || labScore == 0)) {
          continue;
        }

        // Create grade data for evaluationsheet
        final gradeData = <String, dynamic>{
          'studentid': studentId,
          'lectureofferingid': _selectedCourse,
          'midterm': midterm,
          'yearwork': yearWork,
          'finalexam': finalExam,
          'totalgrade': totalGrade,
        };

        if (labScore != null) {
          gradeData['labscore'] = labScore;
        }

        gradeUpdates.add(gradeData);
      }

      if (gradeUpdates.isEmpty) {
        setState(() => _isLoading = false);
        _showSnackBar('No grades to save', isError: true);
        return;
      }

      // Upsert into evaluationsheet
      await _supabase.from('evaluationsheet').upsert(
        gradeUpdates,
        onConflict: 'studentid,lectureofferingid',
      );

      setState(() => _isLoading = false);

      if (mounted) {
        _showSnackBar(
          'Grades saved for ${gradeUpdates.length} students',
          isError: false,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnackBar('Error saving grades: $e', isError: true);
      }
      debugPrint('Error saving grades: $e');
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Manual Grade Entry'),
      body: _isLoading
          ? Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildHeaderCard(colorScheme, isDark),
            const SizedBox(height: 24),

            // Course Selection
            _buildCourseSelection(colorScheme, isDark),
            const SizedBox(height: 20),

            // Course Settings (Lab & Mini Project)
            if (_selectedCourse != null) ...[
              _buildCourseSettings(colorScheme, isDark),
              const SizedBox(height: 20),
            ],

            // Grade Type Selector and Students List
            if (_allStudents.isNotEmpty) ...[
              _buildGradeTypeSelector(colorScheme, isDark),
              const SizedBox(height: 20),

              // Student Search
              _buildStudentSearch(colorScheme, isDark),
              const SizedBox(height: 16),

              // Students List with Grade Input
              _buildStudentsList(colorScheme, isDark),
              const SizedBox(height: 24),

              // Submit Button
              _buildSubmitButton(),

              // TA Warning
              if (widget.role != 'faculty') ...[
                const SizedBox(height: 12),
                _buildTAWarning(colorScheme, isDark),
              ],
            ],

            if (_selectedCourse != null &&
                _allStudents.isEmpty &&
                !_isLoading)
              _buildEmptyState(colorScheme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.grade_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manual Grade Entry',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.role == 'faculty'
                      ? 'Enter grades for students'
                      : 'View and prepare grades (TAs cannot submit)',
                  style: TextStyle(
                    fontSize: 13,
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

  Widget _buildCourseSelection(ColorScheme colorScheme, bool isDark) {
    final isTA = widget.role == 'teacher_assistant';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isTA ? 'Select Section' : 'Select Course',
          style: TextStyle(
            fontSize: 15,
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
            hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.4)),
            filled: true,
            fillColor: isDark ? colorScheme.surface : Colors.white,
          ),
          dropdownColor: colorScheme.surface,
          items: _courses.map((course) {
            String id;
            Map<String, dynamic>? courseData;

            if (widget.role == 'faculty') {
              id = course['lectureofferingid']?.toString() ?? '';
              courseData = course['course'] as Map<String, dynamic>?;
            } else {
              final sectionOffering = course['sectioncourseoffering'] as Map<String, dynamic>?;
              id = sectionOffering?['sectionofferingid']?.toString() ?? '';
              courseData = sectionOffering?['course'] as Map<String, dynamic>?;
            }

            return DropdownMenuItem<String>(
              value: id,
              child: Text(
                courseData != null
                    ? '${courseData['coursecode']} - ${courseData['coursename']}'
                    : 'Unknown Course',
                style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCourse = value;
              _allStudents.clear();
              _filteredStudents.clear();
              _searchController.clear();
              _searchQuery = '';

              // Check if course has lab and get course name
              if (widget.role == 'faculty') {
                final selectedCourseData = _courses.firstWhere(
                      (c) => c['lectureofferingid'] == value,
                  orElse: () => {},
                );
                final courseInfo = selectedCourseData['course'] as Map<String, dynamic>?;
                _courseHasLab = courseInfo?['haslab'] == 'YES';
                _selectedCourseName = courseInfo?['coursename'];
              } else {
                final selectedCourseData = _courses.firstWhere(
                      (c) => (c['sectioncourseoffering'] as Map<String, dynamic>?)?['sectionofferingid'] == value,
                  orElse: () => {},
                );
                final sectionOffering = selectedCourseData['sectioncourseoffering'] as Map<String, dynamic>?;
                final courseInfo = sectionOffering?['course'] as Map<String, dynamic>?;
                _courseHasLab = courseInfo?['haslab'] == 'YES';
                _selectedCourseName = courseInfo?['coursename'];
              }
            });
            _loadStudents();
          },
        ),
      ],
    );
  }

  Widget _buildCourseSettings(ColorScheme colorScheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Course Settings',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),

        // Lab and Project checkboxes
        Container(
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  value: _courseHasLab,
                  onChanged: (value) {
                    setState(() => _courseHasLab = value ?? false);
                  },
                  title: Text(
                    'Has Lab (10 pts)',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                  activeColor: AppColors.primaryBlue,
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: colorScheme.outline.withOpacity(0.2),
              ),
              Expanded(
                child: CheckboxListTile(
                  value: _courseHasMiniProject,
                  onChanged: (value) {
                    setState(() => _courseHasMiniProject = value ?? false);
                  },
                  title: Text(
                    'Has Project (10 pts)',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                  activeColor: AppColors.primaryBlue,
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Grade distribution info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.accentPurple.withOpacity(isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accentPurple.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: AppColors.accentPurple),
                  const SizedBox(width: 8),
                  Text(
                    'Grade Distribution',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '• Midterm: 20 pts\n'
                    '• Quizzes: ${_quizCount} × 5 pts = ${_quizCount * 5} pts\n'
                    '• Assignments: ${_assignmentCount} × 5 pts = ${_assignmentCount * 5} pts'
                    '${_courseHasMiniProject ? '\n• Mini Project: 10 pts' : ''}'
                    '${_courseHasLab ? '\n• Lab: 10 pts' : ''}\n'
                    '• Final: ${_courseHasLab ? '50' : '60'} pts\n'
                    '━━━━━━━━━━━━━━━━━\n'
                    'Total: ${20 + (_quizCount * 5) + (_assignmentCount * 5) + (_courseHasMiniProject ? 10 : 0) + (_courseHasLab ? 10 : 0) + (_courseHasLab ? 50 : 60)} pts',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.8),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Assignment and Quiz count controls
        Container(
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.secondaryOrange.withOpacity(0.2)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Assignment count
              Row(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    color: AppColors.accentPurple,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Number of Assignments',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppColors.accentPurple.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _assignmentCount > 1
                              ? () => setState(() => _assignmentCount--)
                              : null,
                          icon: const Icon(Icons.remove, size: 18),
                          constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                          padding: EdgeInsets.zero,
                          color: AppColors.accentPurple,
                        ),
                        Container(
                          width: 40,
                          alignment: Alignment.center,
                          child: Text(
                            '$_assignmentCount',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _assignmentCount < 10
                              ? () => setState(() => _assignmentCount++)
                              : null,
                          icon: const Icon(Icons.add, size: 18),
                          constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                          padding: EdgeInsets.zero,
                          color: AppColors.accentPurple,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Divider(color: colorScheme.outline.withOpacity(0.2)),
              const SizedBox(height: 12),

              // Quiz count
              Row(
                children: [
                  Icon(
                    Icons.quiz_outlined,
                    color: AppColors.secondaryOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Number of Quizzes',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppColors.secondaryOrange.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _quizCount > 1
                              ? () => setState(() => _quizCount--)
                              : null,
                          icon: const Icon(Icons.remove, size: 18),
                          constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                          padding: EdgeInsets.zero,
                          color: AppColors.secondaryOrange,
                        ),
                        Container(
                          width: 40,
                          alignment: Alignment.center,
                          child: Text(
                            '$_quizCount',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _quizCount < 10
                              ? () => setState(() => _quizCount++)
                              : null,
                          icon: const Icon(Icons.add, size: 18),
                          constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                          padding: EdgeInsets.zero,
                          color: AppColors.secondaryOrange,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGradeTypeSelector(ColorScheme colorScheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Grade Type',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _getAvailableGradeTypes().map((type) {
            final isSelected = _selectedGradeType == type;
            return ChoiceChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedGradeType = type);
              },
              selectedColor: AppColors.primaryBlue,
              backgroundColor: isDark ? colorScheme.surface : Colors.grey[200],
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Entering grades for: $_selectedGradeType (Max: ${_getMaxGrade()} pts)',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentSearch(ColorScheme colorScheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Students',
          style: TextStyle(
            fontSize: 15,
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
              prefixIcon:
              Icon(Icons.search_rounded, color: AppColors.primaryBlue),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear_rounded,
                    color: colorScheme.onSurface.withOpacity(0.5)),
                onPressed: () {
                  _searchController.clear();
                  _filterStudents('');
                },
              )
                  : null,
              hintText: 'Search by name or ID...',
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.4),
                fontSize: 14,
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
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
            onChanged: _filterStudents,
          ),
        ),
        if (_searchQuery.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Found ${_filteredStudents.length} student(s)',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStudentsList(ColorScheme colorScheme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Enter Grades',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_filteredStudents.length} students',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_filteredStudents.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
            ),
            child: Center(
              child: Text(
                'No students match your search',
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredStudents.length,
            itemBuilder: (context, index) {
              final student = _filteredStudents[index];
              final studentId = _getStudentId(student);
              final name = _getStudentName(student);
              final controller =
              _gradeControllers[studentId]?[_selectedGradeType];

              if (controller == null) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.surface : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border:
                  Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
                ),
                child: ListTile(
                  leading: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.transparent,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    'ID: $studentId',
                    style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6)),
                  ),
                  trailing: SizedBox(
                    width: 90,
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: AppColors.primaryBlue.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: AppColors.primaryBlue, width: 2),
                        ),
                        hintText: '0',
                        hintStyle: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.3)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 10),
                        suffixText: '/${_getMaxGrade()}',
                        suffixStyle: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 11,
                        ),
                        filled: true,
                        fillColor:
                        isDark ? colorScheme.surfaceContainerHighest : null,
                      ),
                      onChanged: (value) {
                        if (value.isEmpty) return;
                        final grade = double.tryParse(value);
                        if (grade != null &&
                            (grade < 0 || grade > _getMaxGrade())) {
                          controller.text = '';
                          _showSnackBar(
                            'Grade must be between 0 and ${_getMaxGrade()}',
                            isError: true,
                          );
                        }
                      },
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = widget.role == 'faculty';
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canSubmit ? _submitGrades : null,
        icon: Icon(canSubmit ? Icons.save_rounded : Icons.lock_outline),
        label: Text(
          canSubmit
              ? 'Save Grades (${_filteredStudents.length} students)'
              : 'TAs Cannot Submit Grades',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: canSubmit ? AppColors.accentGreen : Colors.grey,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildTAWarning(ColorScheme colorScheme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryOrange.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.secondaryOrange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: AppColors.secondaryOrange, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'As a TA, you can view and prepare grades but cannot save them to the evaluation sheet. Only faculty members can submit final grades.',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 20),
            Text(
              'No students found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No students are enrolled in this ${widget.role == 'faculty' ? 'course' : 'section'} yet',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  int _getMaxGrade() {
    if (_selectedGradeType == 'Midterm') {
      return 20;
    } else if (_selectedGradeType == 'Final') {
      // If has lab: Final = 50, If no lab: Final = 60
      return _courseHasLab ? 50 : 60;
    } else if (_selectedGradeType.startsWith('Quiz')) {
      return 5;
    } else if (_selectedGradeType.startsWith('Assignment')) {
      return 5;
    } else if (_selectedGradeType == 'Lab') {
      return 10;
    } else if (_selectedGradeType == 'MiniProject') {
      return 10;
    } else {
      return 100;
    }
  }
}