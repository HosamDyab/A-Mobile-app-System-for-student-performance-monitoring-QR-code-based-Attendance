import '../repositories/grade_repository.dart';

/// Use case for submitting student grades
///
/// Supports two grading structures:
///
/// **Regular Courses (No Lab):**
/// - Midterm: 20 points
/// - Final: 60 points
/// - Year_Work: 20 points (10 Attendance + 10 Assignments/Quizzes)
/// - Total: 100 points
///
/// **Courses with Lab:**
/// - Midterm: 20 points
/// - Lab: 10 points
/// - Final: 50 points
/// - Year_Work: 20 points (10 Attendance + 10 Assignments/Quizzes)
/// - Total: 100 points
class SubmitGradesUseCase {
  final GradeRepository repository;

  SubmitGradesUseCase(this.repository);

  /// Submit lecture grade (regular course without lab)
  ///
  /// Parameters:
  /// - [midterm]: Out of 20 points
  /// - [finalExam]: Out of 60 points
  /// - [attendance]: Out of 10 points
  /// - [assignmentsQuizzes]: Out of 10 points (sum of all assignments and quizzes)
  Future<void> executeForLecture({
    required String studentId,
    required String lectureOfferingId,
    required double midterm,
    required double finalExam,
    required double attendance,
    required double assignmentsQuizzes,
  }) async {
    // Validate ranges for regular course
    if (midterm < 0 || midterm > 20) {
      throw Exception('Midterm must be between 0 and 20 points');
    }
    if (finalExam < 0 || finalExam > 60) {
      throw Exception('Final exam must be between 0 and 60 points');
    }
    if (attendance < 0 || attendance > 10) {
      throw Exception('Attendance must be between 0 and 10 points');
    }
    if (assignmentsQuizzes < 0 || assignmentsQuizzes > 10) {
      throw Exception('Assignments/Quizzes must be between 0 and 10 points');
    }

    return await repository.submitLectureGrade(
      studentId: studentId,
      lectureOfferingId: lectureOfferingId,
      midterm: midterm,
      finalExam: finalExam,
      attendance: attendance,
      assignmentsQuizzes: assignmentsQuizzes,
    );
  }

  /// Submit lecture grade (course WITH lab)
  ///
  /// Parameters:
  /// - [midterm]: Out of 20 points
  /// - [lab]: Out of 10 points (lab work/practical)
  /// - [finalExam]: Out of 50 points (reduced from 60 due to lab)
  /// - [attendance]: Out of 10 points
  /// - [assignmentsQuizzes]: Out of 10 points (sum of all assignments and quizzes)
  Future<void> executeForLectureWithLab({
    required String studentId,
    required String lectureOfferingId,
    required double midterm,
    required double lab,
    required double finalExam,
    required double attendance,
    required double assignmentsQuizzes,
  }) async {
    // Validate ranges for course with lab
    if (midterm < 0 || midterm > 20) {
      throw Exception('Midterm must be between 0 and 20 points');
    }
    if (lab < 0 || lab > 10) {
      throw Exception('Lab must be between 0 and 10 points');
    }
    if (finalExam < 0 || finalExam > 50) {
      throw Exception(
          'Final exam must be between 0 and 50 points (course has lab)');
    }
    if (attendance < 0 || attendance > 10) {
      throw Exception('Attendance must be between 0 and 10 points');
    }
    if (assignmentsQuizzes < 0 || assignmentsQuizzes > 10) {
      throw Exception('Assignments/Quizzes must be between 0 and 10 points');
    }

    // For courses with lab, we combine lab + finalExam to make 60 points for "Final" field
    // This way: midterm(20) + final(60) + yearWork(20) = 100
    final combinedFinal = lab + finalExam;

    return await repository.submitLectureGrade(
      studentId: studentId,
      lectureOfferingId: lectureOfferingId,
      midterm: midterm,
      finalExam: combinedFinal, // Lab(10) + Final(50) = 60
      attendance: attendance,
      assignmentsQuizzes: assignmentsQuizzes,
    );
  }

  /// Submit section grade (for TA-led sections)
  ///
  /// Uses same structure as lecture grades
  Future<void> executeForSection({
    required String studentId,
    required String sectionOfferingId,
    required double midterm,
    required double finalExam,
    required double attendance,
    required double assignmentsQuizzes,
  }) async {
    return await repository.submitSectionGrade(
      studentId: studentId,
      sectionOfferingId: sectionOfferingId,
      midterm: midterm,
      finalExam: finalExam,
      attendance: attendance,
      assignmentsQuizzes: assignmentsQuizzes,
    );
  }

  /// Helper method: Calculate total assignment and quiz scores
  ///
  /// Use this when you have multiple assignments and quizzes
  /// that need to be combined into one score out of 10
  ///
  /// Example:
  /// ```dart
  /// final totalScore = calculateAssignmentsQuizzesTotal(
  ///   assignments: [8, 9, 7.5],  // 3 assignments
  ///   quizzes: [9, 8.5, 9],      // 3 quizzes
  ///   maxPoints: 10,
  /// );
  /// ```
  double calculateAssignmentsQuizzesTotal({
    required List<double> assignments,
    required List<double> quizzes,
    required double maxPoints,
  }) {
    if (assignments.isEmpty && quizzes.isEmpty) {
      return 0.0;
    }

    // Calculate average of all assignments and quizzes
    final allScores = [...assignments, ...quizzes];
    final average = allScores.reduce((a, b) => a + b) / allScores.length;

    // Scale to maxPoints (usually 10)
    return (average / 100) * maxPoints;
  }

  /// Helper method: Calculate attendance score based on attendance percentage
  ///
  /// Example:
  /// ```dart
  /// final attendanceScore = calculateAttendanceScore(
  ///   attendedSessions: 28,
  ///   totalSessions: 30,
  ///   maxPoints: 10,
  /// );
  /// // Returns: 9.33 (93.3% attendance)
  /// ```
  double calculateAttendanceScore({
    required int attendedSessions,
    required int totalSessions,
    required double maxPoints,
  }) {
    if (totalSessions == 0) return 0.0;

    final percentage = attendedSessions / totalSessions;
    return percentage * maxPoints;
  }
}
