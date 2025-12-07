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
  final String? error; // null => no error

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
    // NOTE: `error == null` means "preserve existing error".
    // To clear error explicitly call clearError() on the cubit.
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

  // caches for filtering
  List<CourseEntitySearch> _allCourses = [];
  List<FacultyEntitySearch> _allFaculty = [];

  StudentSearchCubit({
    required this.repository,
    String? initialStudentId,
  })  : _studentId = initialStudentId,
        super(const StudentSearchState());

  /// Allows setting the studentId after construction.
  /// If [loadInitialData] is true, it will call loadAllCourses() and loadAllFaculty().
  void setStudentId(String studentId, {bool loadInitialData = true}) {
    _studentId = studentId;
    if (loadInitialData) {
      // fire-and-forget — callers can await if they need to by calling the methods directly.
      loadAllCourses();
      loadAllFaculty();
    }
  }

  /// Explicitly clear error in state.
  void clearError() {
    emit(state.copyWith(setErrorToNull: true));
  }

  bool get hasStudentId => _studentId != null && _studentId!.isNotEmpty;

  Future<void> loadAllCourses() async {
    if (!hasStudentId) {
      emit(state.copyWith(
        isLoadingCourses: false,
        // preserve error (or set a meaningful one)
        error: 'Student ID not set',
      ));
      return;
    }

    emit(state.copyWith(isLoadingCourses: true, error: null));

    try {
      final courses = await repository.searchStudentCourses(_studentId!, '');

      final safeCourses = courses
          .where(
              (c) => c.title.trim().isNotEmpty && c.title != 'Unknown Course')
          .toList();

      _allCourses = safeCourses;

      emit(state.copyWith(
        isLoadingCourses: false,
        courses: safeCourses,
      ));
    } catch (e) {
      emit(state.copyWith(isLoadingCourses: false, error: e.toString()));
      // optional: debug print
      // debugPrint('loadAllCourses error: $e\n$st');
    }
  }

  void filterCourses(String query) {
    if (query.isEmpty) {
      emit(state.copyWith(courses: _allCourses));
      return;
    }

    final filtered = _allCourses
        .where((course) =>
            course.title.toLowerCase().contains(query.toLowerCase()))
        .toList();

    emit(state.copyWith(courses: filtered));
  }

  void clearCourses() {
    _allCourses = [];
    emit(state.copyWith(courses: [], isLoadingCourses: false));
  }

  Future<void> searchCourses(String query) async {
    if (!hasStudentId) {
      emit(
          state.copyWith(isLoadingCourses: false, error: 'Student ID not set'));
      return;
    }

    emit(state.copyWith(isLoadingCourses: true, error: null));

    try {
      final courses = await repository.searchStudentCourses(_studentId!, query);

      final safeCourses = courses
          .where(
              (c) => c.title.trim().isNotEmpty && c.title != 'Unknown Course')
          .toList();

      _allCourses = safeCourses;

      emit(state.copyWith(
        isLoadingCourses: false,
        courses: safeCourses,
      ));
    } catch (e) {
      emit(state.copyWith(isLoadingCourses: false, error: e.toString()));
      // debugPrint('searchCourses error: $e\n$st');
    }
  }

  Future<void> loadAllFaculty() async {
    if (!hasStudentId) {
      emit(
          state.copyWith(isLoadingFaculty: false, error: 'Student ID not set'));
      return;
    }

    emit(state.copyWith(isLoadingFaculty: true, error: null));

    try {
      final faculty = await repository.searchStudentFaculty(_studentId!, '');

      final safeFaculty = faculty
          .where((f) =>
              f.fullName.trim().isNotEmpty && f.fullName != 'Unknown Faculty')
          .toList();

      _allFaculty = safeFaculty;

      emit(state.copyWith(
        isLoadingFaculty: false,
        faculty: safeFaculty,
      ));
    } catch (e) {
      emit(state.copyWith(isLoadingFaculty: false, error: e.toString()));
      // debugPrint('loadAllFaculty error: $e\n$st');
    }
  }

  Future<void> searchFaculty(String query) async {
    if (!hasStudentId) {
      emit(
          state.copyWith(isLoadingFaculty: false, error: 'Student ID not set'));
      return;
    }

    emit(state.copyWith(isLoadingFaculty: true, error: null));

    try {
      final faculty = await repository.searchStudentFaculty(_studentId!, query);

      final validFaculty = faculty
          .where((f) =>
              f.fullName.trim().isNotEmpty && f.fullName != 'Unknown Faculty')
          .toList();

      _allFaculty = validFaculty;

      emit(state.copyWith(
        isLoadingFaculty: false,
        faculty: validFaculty,
      ));
    } catch (e) {
      emit(state.copyWith(isLoadingFaculty: false, error: e.toString()));
      // debugPrint('searchFaculty error: $e\n$st');
    }
  }

  void filterFaculty(String query) {
    if (query.isEmpty) {
      emit(state.copyWith(faculty: _allFaculty));
      return;
    }

    final filtered = _allFaculty
        .where((f) => f.fullName.toLowerCase().contains(query.toLowerCase()))
        .toList();

    emit(state.copyWith(faculty: filtered));
  }

  void clearFaculty() {
    _allFaculty = [];
    emit(state.copyWith(faculty: [], isLoadingFaculty: false));
  }
}
