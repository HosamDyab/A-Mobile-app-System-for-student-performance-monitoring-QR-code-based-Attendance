
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/CourseSearchgEntity.dart';

class StudentSearchState {
  final bool isLoadingCourses;
  final bool isLoadingFaculty;
  final List<CourseEntitySearch> courses;
  final List<FacultyEntitySearch> faculty;
  final String? error;

  StudentSearchState({
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
  }) {
    return StudentSearchState(
      isLoadingCourses: isLoadingCourses ?? this.isLoadingCourses,
      isLoadingFaculty: isLoadingFaculty ?? this.isLoadingFaculty,
      courses: courses ?? this.courses,
      faculty: faculty ?? this.faculty,
      error: error,
    );
  }
}

class StudentSearchCubit extends Cubit<StudentSearchState> {
  final StudentRepositorySearch repository;
  final String studentId;

  StudentSearchCubit(this.repository, this.studentId)
      : super(StudentSearchState());

  void clearCourses() {
    emit(state.copyWith(
      courses: [],
      isLoadingCourses: false,
    ));
  }

  void clearFaculty() {
    emit(state.copyWith(
      faculty: [],
      isLoadingFaculty: false,
    ));
  }

  Future<void> searchCourses(String query) async {
    emit(state.copyWith(
      isLoadingCourses: true,
      error: null,
    ));

    try {
      final courses = await repository.searchStudentCourses(studentId, query);

      final validCourses = courses.where((c) =>
      c.title.trim().isNotEmpty &&
          c.title != "Unknown Course"
      ).toList();

      emit(state.copyWith(
        isLoadingCourses: false,
        courses: validCourses,
      ));

    } catch (e) {
      emit(state.copyWith(
        isLoadingCourses: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> searchFaculty(String query) async {
    emit(state.copyWith(
      isLoadingFaculty: true,
      error: null,
    ));

    try {
      final faculty = await repository.searchStudentFaculty(studentId, query);

      final validFaculty = faculty.where((f) =>
      f.fullName.trim().isNotEmpty &&
          f.fullName != "Unknown Faculty"
      ).toList();

      emit(state.copyWith(
        isLoadingFaculty: false,
        faculty: validFaculty,
      ));

    } catch (e) {
      emit(state.copyWith(
        isLoadingFaculty: false,
        error: e.toString(),
      ));
    }
  }
}
