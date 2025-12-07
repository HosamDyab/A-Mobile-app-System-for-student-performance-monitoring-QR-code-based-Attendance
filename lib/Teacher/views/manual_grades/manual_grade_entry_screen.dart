import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/utils/app_colors.dart';
import '../widgets/custom_app_bar.dart';

/// Manual Grade Entry Screen - Enter grades for students manually.
///
/// Features:
/// - Course selection dropdown
/// - Grade type selection (Midterm, Quiz, Assignment, etc.)
/// - Student list with grade input and search
/// - Theme-aware styling (light/dark mode)
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
        // For Faculty: Try to get students from sections linked to this lecture
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

        // If no students found via sections, try loading all students
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
        // For TA: Get students from this section directly
        try {
          final response = await _supabase
              .from('StudentSection')
              .select(
                  'StudentId, Student(StudentId, StudentCode, User(FullName))')
              .eq('SectionOfferingId', _selectedCourse!);

          studentsList = List<Map<String, dynamic>>.from(response as List);
        } catch (e) {
          debugPrint('TA section query failed: $e');
          // Fallback to all students
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

      // Initialize controllers for all grade types
      _gradeControllers.clear();
      for (var student in studentsList) {
        final studentId = _getStudentId(student);
        if (studentId.isNotEmpty) {
          _gradeControllers[studentId] = {
            'Midterm': TextEditingController(),
            'Quiz1': TextEditingController(),
            'Quiz2': TextEditingController(),
            'Quiz3': TextEditingController(),
            'Assignment1': TextEditingController(),
            'Assignment2': TextEditingController(),
            'Assignment3': TextEditingController(),
            'Lab': TextEditingController(),
            'MiniProject': TextEditingController(),
            'Final': TextEditingController(),
          };
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
          final name = _getStudentName(student).toLowerCase();
          final code = _getStudentCode(student).toLowerCase();
          final searchLower = query.toLowerCase();
          return name.contains(searchLower) || code.contains(searchLower);
        }).toList();
      }
    });
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

  Future<void> _submitGrades() async {
    if (_selectedCourse == null || _filteredStudents.isEmpty) {
      _showSnackBar('Please select course and enter grades', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final gradeUpdates = <Map<String, dynamic>>[];
      final isFaculty = widget.role == 'faculty';

      for (var student in _filteredStudents) {
        final studentId = _getStudentId(student);
        if (studentId.isEmpty) continue;

        final controllers = _gradeControllers[studentId];
        if (controllers == null) continue;

        // Calculate Year_Work from all components
        double yearWork = 0;
        for (int i = 1; i <= _quizCount; i++) {
          yearWork += double.tryParse(controllers['Quiz$i']?.text ?? '0') ?? 0;
        }
        for (int i = 1; i <= _assignmentCount; i++) {
          yearWork += double.tryParse(controllers['Assignment$i']?.text ?? '0') ?? 0;
        }
        if (_courseHasLab) {
          yearWork += double.tryParse(controllers['Lab']?.text ?? '0') ?? 0;
        }
        if (_courseHasMiniProject) {
          yearWork += double.tryParse(controllers['MiniProject']?.text ?? '0') ?? 0;
        }

        // Create grade data with correct foreign key based on role
        final gradeData = <String, dynamic>{
          'StudentId': studentId,
          'Midterm': double.tryParse(controllers['Midterm']?.text ?? '0') ?? 0,
          'Final': double.tryParse(controllers['Final']?.text ?? '0') ?? 0,
          'Year_Work': yearWork,
          // Add the correct offering ID key based on role
          if (isFaculty) 'LectureOfferingId': _selectedCourse
          else 'SectionOfferingId': _selectedCourse,
        };

        gradeUpdates.add(gradeData);
      }

      // Insert into correct table based on role
      if (isFaculty) {
        await _supabase.from('LectureGrade').upsert(gradeUpdates);
      } else {
        await _supabase.from('SectionGrade').upsert(gradeUpdates);
      }

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
                  'Enter grades for students manually',
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
           // prefixIcon: Icon(Icons.book_rounded, color: AppColors.primaryBlue),
            filled: true,
            fillColor: isDark ? colorScheme.surface : Colors.white,
          ),
          dropdownColor: colorScheme.surface,
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
                style: TextStyle(fontSize: 13,color: colorScheme.onSurface),
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
                    'Has Lab',
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
                    'Has Project',
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

        // Assignment and Quiz count controls
        Container(
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.accentPurple.withOpacity(0.2)),
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
                  'Entering grades for: $_selectedGradeType (Max: ${_getMaxGrade()})',
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
              hintText: 'Search by name or code...',
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
              final code = _getStudentCode(student);
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
                    'Code: $code',
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
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _submitGrades,
        icon: const Icon(Icons.save_rounded),
        label: Text(
          'Save Grades (${_filteredStudents.length} students)',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGreen,
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
              'No students are enrolled in this course yet',
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
