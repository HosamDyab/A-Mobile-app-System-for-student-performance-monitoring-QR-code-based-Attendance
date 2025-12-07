import '../datasources/supabase/grade_datasource.dart';

class GradeRepository {
  final GradeDataSource _dataSource;

  GradeRepository(this._dataSource);

  /// Submit lecture grade with breakdown:
  /// - Midterm: 20 points
  /// - Final: 60 points
  /// - Year_Work: 20 points (10 Attendance + 10 Assignments/Quizzes)
  Future<void> submitLectureGrade({
    required String studentId,
    required String lectureOfferingId,
    required double midterm, // Max: 20
    required double finalExam, // Max: 60
    required double attendance, // Max: 10
    required double assignmentsQuizzes, // Max: 10
  }) async {
    // Validate ranges
    if (midterm < 0 || midterm > 20) {
      throw Exception('Midterm must be between 0 and 20');
    }
    if (finalExam < 0 || finalExam > 60) {
      throw Exception('Final exam must be between 0 and 60');
    }
    if (attendance < 0 || attendance > 10) {
      throw Exception('Attendance must be between 0 and 10');
    }
    if (assignmentsQuizzes < 0 || assignmentsQuizzes > 10) {
      throw Exception('Assignments/Quizzes must be between 0 and 10');
    }

    // Calculate Year_Work
    final yearWork = attendance + assignmentsQuizzes;

    await _dataSource.submitLectureGrade(
      studentId: studentId,
      lectureOfferingId: lectureOfferingId,
      midterm: midterm,
      finalExam: finalExam,
      yearWork: yearWork,
    );
  }

  /// Submit section grade (similar structure)
  Future<void> submitSectionGrade({
    required String studentId,
    required String sectionOfferingId,
    required double midterm,
    required double finalExam,
    required double attendance,
    required double assignmentsQuizzes,
  }) async {
    final yearWork = attendance + assignmentsQuizzes;

    await _dataSource.submitSectionGrade(
      studentId: studentId,
      sectionOfferingId: sectionOfferingId,
      midterm: midterm,
      finalExam: finalExam,
      yearWork: yearWork,
    );
  }

  /// Get all grades for a student
  Future<List<Map<String, dynamic>>> getStudentGrades(String studentId) async {
    return await _dataSource.getStudentGrades(studentId);
  }

  /// Get all grades for a course (for faculty)
  Future<List<Map<String, dynamic>>> getCourseGrades(
      String lectureOfferingId) async {
    return await _dataSource.getCourseGrades(lectureOfferingId);
  }

  /// Finalize grade (lock it from editing)
  Future<void> finalizeGrade(String gradeId) async {
    await _dataSource.finalizeGrade(gradeId);
  }
}
