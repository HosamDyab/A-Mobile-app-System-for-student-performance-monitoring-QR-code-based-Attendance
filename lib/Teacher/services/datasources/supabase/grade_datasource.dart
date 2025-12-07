import '../../supabase_service.dart';

class GradeDataSource {
  /// Submit or update lecture grade (uses LectureGrade table)
  Future<void> submitLectureGrade({
    required String studentId,
    required String lectureOfferingId,
    required double midterm,
    required double finalExam,
    required double yearWork,
  }) async {
    final grade = {
      'StudentId': studentId,
      'LectureOfferingId': lectureOfferingId,
      'Midterm': midterm,
      'Final': finalExam,
      'Year_Work': yearWork,
      // Total, LetterGrade, and QualityPoint are auto-calculated by database
    };

    await SupabaseService.client
        .from('LectureGrade')
        .upsert(grade, onConflict: 'StudentId,LectureOfferingId');
  }

  /// Submit or update section grade (uses SectionGrade table)
  Future<void> submitSectionGrade({
    required String studentId,
    required String sectionOfferingId,
    required double midterm,
    required double finalExam,
    required double yearWork,
  }) async {
    final grade = {
      'StudentId': studentId,
      'SectionOfferingId': sectionOfferingId,
      'Midterm': midterm,
      'Final': finalExam,
      'Year_Work': yearWork,
      // Total, LetterGrade, and QualityPoint are auto-calculated by database
    };

    await SupabaseService.client
        .from('SectionGrade')
        .upsert(grade, onConflict: 'StudentId,SectionOfferingId');
  }

  /// Get all grades for a student
  Future<List<Map<String, dynamic>>> getStudentGrades(String studentId) async {
    final response =
        await SupabaseService.client.from('LectureGrade').select('''
          *,
          LectureCourseOffering:LectureOfferingId (
            AcademicYear,
            Semester,
            Course:CourseId (
              Code,
              Title,
              Credits
            )
          )
        ''').eq('StudentId', studentId).order('CreatedAt', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get grades for a specific course offering
  Future<List<Map<String, dynamic>>> getCourseGrades(
      String lectureOfferingId) async {
    final response = await SupabaseService.client
        .from('LectureGrade')
        .select('''
          *,
          Student:StudentId (
            StudentCode,
            User:UserId (
              FullName,
              Email
            )
          )
        ''')
        .eq('LectureOfferingId', lectureOfferingId)
        .order('Total', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Finalize grades (lock them from editing)
  Future<void> finalizeGrade(String gradeId) async {
    await SupabaseService.client.from('LectureGrade').update({
      'IsFinalized': true,
      'FinalizedAt': DateTime.now().toIso8601String(),
    }).eq('GradeId', gradeId);
  }
}
