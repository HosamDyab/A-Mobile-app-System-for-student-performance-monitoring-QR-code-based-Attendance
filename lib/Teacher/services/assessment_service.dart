import 'package:uuid/uuid.dart';
import 'package:qra/ustils/supabase_manager.dart';

class AssessmentService {
  final supabase = SupabaseManager.client;
  final uuid = const Uuid();

  // ========== LECTURE QUIZZES ==========

  Future<String> createLectureQuiz({
    required String lectureGradeId,
    required String title,
    required double totalPoints,
    DateTime? quizDate,
    DateTime? dueDate,
    int? durationMinutes,
  }) async {
    final quizId = uuid.v4();

    await supabase.from('LectureQuizzes').insert({
      'QuizId': quizId,
      'LectureGradeId': lectureGradeId,
      'Title': title,
      'TotalPoints': totalPoints,
      'Score': 0,
      'QuizDate': quizDate?.toIso8601String().split('T')[0],
      'DueDate': dueDate?.toIso8601String(),
      'DurationMinutes': durationMinutes,
    });

    return quizId;
  }

  Future<void> updateLectureQuizScore({
    required String quizId,
    required double score,
  }) async {
    await supabase
        .from('LectureQuizzes')
        .update({'Score': score}).eq('QuizId', quizId);
  }

  // ========== SECTION QUIZZES ==========

  Future<String> createSectionQuiz({
    required String sectionGradeId,
    required String title,
    required double totalPoints,
    DateTime? quizDate,
    DateTime? dueDate,
    int? durationMinutes,
  }) async {
    final quizId = uuid.v4();

    await supabase.from('SectionQuizzes').insert({
      'QuizId': quizId,
      'SectionGradeId': sectionGradeId,
      'Title': title,
      'TotalPoints': totalPoints,
      'Score': 0,
      'QuizDate': quizDate?.toIso8601String().split('T')[0],
      'DueDate': dueDate?.toIso8601String(),
      'DurationMinutes': durationMinutes,
    });

    return quizId;
  }

  Future<void> gradeSectionQuiz({
    required String quizId,
    required double score,
    String? feedback,
  }) async {
    await supabase.from('SectionQuizzes').update({
      'Score': score,
      'GradedAt': DateTime.now().toIso8601String(),
      'Feedback': feedback,
    }).eq('QuizId', quizId);
  }

  // ========== SECTION ASSIGNMENTS ==========

  Future<String> createSectionAssignment({
    required String sectionGradeId,
    required String title,
    required double totalPoints,
    String? description,
    DateTime? assignedDate,
    DateTime? dueDate,
  }) async {
    final assignmentId = uuid.v4();

    await supabase.from('SectionAssignment').insert({
      'AssignmentId': assignmentId,
      'SectionGradeId': sectionGradeId,
      'Title': title,
      'Description': description,
      'TotalPoints': totalPoints,
      'Score': 0,
      'AssignedDate': assignedDate?.toIso8601String().split('T')[0],
      'DueDate': dueDate?.toIso8601String(),
    });

    return assignmentId;
  }

  Future<void> submitAssignment({
    required String assignmentId,
    required String submissionFile,
  }) async {
    await supabase.from('SectionAssignment').update({
      'SubmissionFile': submissionFile,
      'SubmittedAt': DateTime.now().toIso8601String(),
      'IsLate': false, // TODO: Calculate based on DueDate
    }).eq('AssignmentId', assignmentId);
  }

  Future<void> gradeAssignment({
    required String assignmentId,
    required double score,
    String? feedback,
  }) async {
    await supabase.from('SectionAssignment').update({
      'Score': score,
      'GradedAt': DateTime.now().toIso8601String(),
      'Feedback': feedback,
    }).eq('AssignmentId', assignmentId);
  }

  // ========== GET METHODS ==========

  Future<List<Map<String, dynamic>>> getStudentAssignments(
      String studentId) async {
    // First get all section grade IDs for this student
    final sectionGrades = await supabase
        .from('SectionGrade')
        .select('GradeId')
        .eq('StudentId', studentId);

    if (sectionGrades.isEmpty) return [];

    final gradeIds = (sectionGrades as List).map((g) => g['GradeId']).toList();

    final assignments = await supabase
        .from('SectionAssignment')
        .select('''
          *,
          SectionGrade:SectionGradeId (
            SectionCourseOffering:SectionOfferingId (
              Course:CourseId (
                Title,
                Code
              )
            )
          )
        ''')
        .inFilter('SectionGradeId', gradeIds)
        .order('DueDate', ascending: true);

    return List<Map<String, dynamic>>.from(assignments);
  }

  Future<List<Map<String, dynamic>>> getLectureQuizzes(
      String lectureGradeId) async {
    final quizzes = await supabase
        .from('LectureQuizzes')
        .select('*')
        .eq('LectureGradeId', lectureGradeId)
        .order('QuizDate', ascending: false);

    return List<Map<String, dynamic>>.from(quizzes);
  }

  Future<List<Map<String, dynamic>>> getSectionQuizzes(
      String sectionGradeId) async {
    final quizzes = await supabase
        .from('SectionQuizzes')
        .select('*')
        .eq('SectionGradeId', sectionGradeId)
        .order('QuizDate', ascending: false);

    return List<Map<String, dynamic>>.from(quizzes);
  }
}
