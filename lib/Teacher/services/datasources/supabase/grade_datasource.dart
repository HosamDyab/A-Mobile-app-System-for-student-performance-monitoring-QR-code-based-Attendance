// import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/grade_model.dart';
import '../../supabase_service.dart';

class GradeDataSource {
  Future<GradeModel> submitGrade({
    required String studentId,
    required String examGrade,
    required String assignmentGrade,
  }) async {
    final grade = {
      'student_id': studentId,
      'exam_grade': examGrade,
      'assignment_grade': assignmentGrade,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    final response = await SupabaseService.client
        .from('grades')
        .insert(grade)
        .select()
        .single();
    
    return GradeModel.fromJson(response);
  }
  
  Future<List<GradeModel>> getStudentGrades(String studentId) async {
    final response = await SupabaseService.client
        .from('grades')
        .select()
        .eq('student_id', studentId)
        .order('created_at', ascending: false);
    
    return (response as List<dynamic>)
        .map((e) => GradeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}