import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qra/Teacher/services/usecases/submit_grades_usecase.dart';
import 'grade_entry_state.dart';

class GradeEntryCubit extends Cubit<GradeEntryState> {
  final SubmitGradesUseCase submitGradesUseCase;

  GradeEntryCubit(this.submitGradesUseCase) : super(GradeEntryInitial());

  /// Submit grade for regular course (no lab)
  ///
  /// Grading: Midterm(20) + Final(60) + Attendance(10) + Assignments/Quizzes(10) = 100
  Future<void> submitLectureGrade({
    required String studentId,
    required String lectureOfferingId,
    required double midterm,
    required double finalExam,
    required double attendance,
    required double assignmentsQuizzes,
  }) async {
    emit(GradeEntryLoading());
    try {
      await submitGradesUseCase.executeForLecture(
        studentId: studentId,
        lectureOfferingId: lectureOfferingId,
        midterm: midterm,
        finalExam: finalExam,
        attendance: attendance,
        assignmentsQuizzes: assignmentsQuizzes,
      );
      emit(GradeEntrySuccess());
    } catch (e) {
      emit(GradeEntryError(message: e.toString()));
    }
  }

  /// Submit grade for course with lab
  ///
  /// Grading: Midterm(20) + Lab(10) + Final(50) + Attendance(10) + Assignments/Quizzes(10) = 100
  Future<void> submitLectureGradeWithLab({
    required String studentId,
    required String lectureOfferingId,
    required double midterm,
    required double lab,
    required double finalExam,
    required double attendance,
    required double assignmentsQuizzes,
  }) async {
    emit(GradeEntryLoading());
    try {
      await submitGradesUseCase.executeForLectureWithLab(
        studentId: studentId,
        lectureOfferingId: lectureOfferingId,
        midterm: midterm,
        lab: lab,
        finalExam: finalExam,
        attendance: attendance,
        assignmentsQuizzes: assignmentsQuizzes,
      );
      emit(GradeEntrySuccess());
    } catch (e) {
      emit(GradeEntryError(message: e.toString()));
    }
  }

  /// Submit section grade (for TAs)
  Future<void> submitSectionGrade({
    required String studentId,
    required String sectionOfferingId,
    required double midterm,
    required double finalExam,
    required double attendance,
    required double assignmentsQuizzes,
  }) async {
    emit(GradeEntryLoading());
    try {
      await submitGradesUseCase.executeForSection(
        studentId: studentId,
        sectionOfferingId: sectionOfferingId,
        midterm: midterm,
        finalExam: finalExam,
        attendance: attendance,
        assignmentsQuizzes: assignmentsQuizzes,
      );
      emit(GradeEntrySuccess());
    } catch (e) {
      emit(GradeEntryError(message: e.toString()));
    }
  }

  /// Calculate total score for assignments and quizzes
  ///
  /// Use this when you have multiple assignments/quizzes that need to be combined
  double calculateAssignmentsQuizzesTotal({
    required List<double> assignments,
    required List<double> quizzes,
    double maxPoints = 10.0,
  }) {
    return submitGradesUseCase.calculateAssignmentsQuizzesTotal(
      assignments: assignments,
      quizzes: quizzes,
      maxPoints: maxPoints,
    );
  }

  /// Calculate attendance score from session count
  ///
  /// Example: 28 attended out of 30 total = 9.33 points (out of 10)
  double calculateAttendanceScore({
    required int attendedSessions,
    required int totalSessions,
    double maxPoints = 10.0,
  }) {
    return submitGradesUseCase.calculateAttendanceScore(
      attendedSessions: attendedSessions,
      totalSessions: totalSessions,
      maxPoints: maxPoints,
    );
  }

  void reset() {
    emit(GradeEntryInitial());
  }
}
