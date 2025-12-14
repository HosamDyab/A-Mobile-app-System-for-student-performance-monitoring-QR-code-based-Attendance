// lib/presentation/blocs/SearchCuit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';

import '../../domain/entities/CourseSearchgEntity.dart';

/// State for StudentSearchCubit
@immutable
class StudentSearchState {
  final bool isLoadingCourses;
  final bool isLoadingFaculty;
  final List<CourseEntitySearch> courses;
  final List<FacultyEntitySearch> faculty;
  final String? error;

  const StudentSearchState({
    this.isLoadingCourses = false,
    this.isLoadingFaculty = false,
    this.courses = const [],
    this.faculty = const [],
    this.error,
  });

  StudentSearchState copyWith({
    bool? isLoadingCourses,
    bool? isLoadingFaculty,
    List<CourseEntitySearch>? courses,
    List<FacultyEntitySearch>? faculty,
    String? error,
    bool setErrorToNull = false,
  }) {
    return StudentSearchState(
      isLoadingCourses: isLoadingCourses ?? this.isLoadingCourses,
      isLoadingFaculty: isLoadingFaculty ?? this.isLoadingFaculty,
      courses: courses ?? this.courses,
      faculty: faculty ?? this.faculty,
      error: setErrorToNull ? null : (error ?? this.error),
    );
  }
}

class StudentSearchCubit extends Cubit<StudentSearchState> {
  final StudentRepositorySearch repository;
  String? _studentId;

  // Caches for filtering
  List<CourseEntitySearch> _allCourses = [];
  List<FacultyEntitySearch> _allFaculty = [];

  StudentSearchCubit({
    required this.repository,
    String? initialStudentId,
  })  : _studentId = initialStudentId,
        super(const StudentSearchState());

  /// Set student ID and optionally load initial data
  void setStudentId(String studentId, {bool loadInitialData = true}) {
    _studentId = studentId;
    if (loadInitialData) {
      loadAllCourses();
      loadAllFaculty();
    }
  }

  /// Clear error in state
  void clearError() {
    emit(state.copyWith(setErrorToNull: true));
  }

  bool get hasStudentId => _studentId != null && _studentId!.isNotEmpty;

  // ==================== COURSES ====================

  Future<void> loadAllCourses() async {
    if (!hasStudentId) {
      emit(state.copyWith(
        isLoadingCourses: false,
        error: 'Student ID not set',
      ));
      return;
    }

    emit(state.copyWith(isLoadingCourses: true, setErrorToNull: true));

    try {
      final courses = await repository.searchStudentCourses(_studentId!, '');

      // ✅ FIXED: Filter by courseName instead of title
      final safeCourses = courses.where((c) {
        return c.courseName.trim().isNotEmpty &&
            c.courseName != 'Unknown Course' &&
            c.courseCode.trim().isNotEmpty &&
            c.courseCode != 'N/A';
      }).toList();

      _allCourses = safeCourses;

      emit(state.copyWith(
        isLoadingCourses: false,
        courses: safeCourses,
      ));
    } catch (e) {
      print('❌ loadAllCourses error: $e');
      emit(state.copyWith(
        isLoadingCourses: false,
        error: e.toString(),
      ));
    }
  }

  void filterCourses(String query) {
    if (query.isEmpty) {
      emit(state.copyWith(courses: _allCourses));
      return;
    }

    final lowerQuery = query.toLowerCase();

    // ✅ FIXED: Filter by both courseName and courseCode
    final filtered = _allCourses.where((course) {
      final nameMatch = course.courseName.toLowerCase().contains(lowerQuery);
      final codeMatch = course.courseCode.toLowerCase().contains(lowerQuery);
      return nameMatch || codeMatch;
    }).toList();

    emit(state.copyWith(courses: filtered));
  }

  void clearCourses() {
    _allCourses = [];
    emit(state.copyWith(courses: [], isLoadingCourses: false));
  }

  Future<void> searchCourses(String query) async {
    if (!hasStudentId) {
      emit(state.copyWith(
        isLoadingCourses: false,
        error: 'Student ID not set',
      ));
      return;
    }

    emit(state.copyWith(isLoadingCourses: true, setErrorToNull: true));

    try {
      final courses = await repository.searchStudentCourses(_studentId!, query);

      // ✅ FIXED: Filter by courseName and courseCode
      final safeCourses = courses.where((c) {
        return c.courseName.trim().isNotEmpty &&
            c.courseName != 'Unknown Course' &&
            c.courseCode.trim().isNotEmpty &&
            c.courseCode != 'N/A';
      }).toList();

      _allCourses = safeCourses;

      emit(state.copyWith(
        isLoadingCourses: false,
        courses: safeCourses,
      ));
    } catch (e) {
      print('❌ searchCourses error: $e');
      emit(state.copyWith(
        isLoadingCourses: false,
        error: e.toString(),
      ));
    }
  }

  // ==================== FACULTY ====================

  Future<void> loadAllFaculty() async {
    if (!hasStudentId) {
      emit(state.copyWith(
        isLoadingFaculty: false,
        error: 'Student ID not set',
      ));
      return;
    }

    emit(state.copyWith(isLoadingFaculty: true, setErrorToNull: true));

    try {
      final faculty = await repository.searchStudentFaculty(_studentId!, '');

      // ✅ Filter valid faculty and remove duplicates
      final Map<String, FacultyEntitySearch> uniqueFaculty = {};

      for (var f in faculty) {
        if (f.fullName.trim().isNotEmpty &&
            f.fullName != 'Unknown Faculty' &&
            f.facultySnn.trim().isNotEmpty &&
            f.facultySnn != 'N/A') {
          // Use facultySnn as key to deduplicate
          uniqueFaculty[f.facultySnn] = f;
        }
      }

      _allFaculty = uniqueFaculty.values.toList();

      emit(state.copyWith(
        isLoadingFaculty: false,
        faculty: _allFaculty,
      ));
    } catch (e) {
      print('❌ loadAllFaculty error: $e');
      emit(state.copyWith(
        isLoadingFaculty: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> searchFaculty(String query) async {
    if (!hasStudentId) {
      emit(state.copyWith(
        isLoadingFaculty: false,
        error: 'Student ID not set',
      ));
      return;
    }

    emit(state.copyWith(isLoadingFaculty: true, setErrorToNull: true));

    try {
      final faculty = await repository.searchStudentFaculty(_studentId!, query);

      // ✅ Filter valid faculty
      final validFaculty = faculty.where((f) {
        return f.fullName.trim().isNotEmpty &&
            f.fullName != 'Unknown Faculty' &&
            f.facultySnn.trim().isNotEmpty &&
            f.facultySnn != 'N/A';
      }).toList();

      _allFaculty = validFaculty;

      emit(state.copyWith(
        isLoadingFaculty: false,
        faculty: validFaculty,
      ));
    } catch (e) {
      print('❌ searchFaculty error: $e');
      emit(state.copyWith(
        isLoadingFaculty: false,
        error: e.toString(),
      ));
    }
  }

  void filterFaculty(String query) {
    if (query.isEmpty) {
      emit(state.copyWith(faculty: _allFaculty));
      return;
    }

    final lowerQuery = query.toLowerCase();

    // ✅ Filter by fullName or email
    final filtered = _allFaculty.where((f) {
      final nameMatch = f.fullName.toLowerCase().contains(lowerQuery);
      final emailMatch = f.email.toLowerCase().contains(lowerQuery);
      return nameMatch || emailMatch;
    }).toList();

    emit(state.copyWith(faculty: filtered));
  }

  void clearFaculty() {
    _allFaculty = [];
    emit(state.copyWith(faculty: [], isLoadingFaculty: false));
  }
}