import 'package:flutter/foundation.dart';
import '../../../models/student_model.dart';
import '../../supabase_service.dart';

/// Data source for student-related operations with Supabase
class StudentDataSource {
  Future<List<StudentModel>> getAllStudents({String? level, String? status}) async {
    try {
      var query = SupabaseService.client
          .from('Student')
          .select('*, User(FullName, Email)');
      
      if (level != null && level != 'All Levels') {
        query = query.eq('AcademicLevel', level);
      }
      
      final response = await query;
      return (response as List<dynamic>)
          .map((e) => StudentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching students: $e');
      return [];
    }
  }
  
  Future<StudentModel> getStudentById(String id) async {
    final response = await SupabaseService.client
        .from('Student')
        .select()
        .eq('student_id', id) // Use student_id instead of id
        .single();
    
    return StudentModel.fromJson(response);
  }
  
  Future<List<StudentModel>> searchStudents(String queryText) async {
    try {
      // Fetch all students with user info
      final response = await SupabaseService.client
          .from('Student')
          .select('*, User(FullName, Email)');

      final allStudents = (response as List<dynamic>)
          .map((e) => StudentModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // Filter by student ID, code, or name
      return allStudents.where((student) {
        final query = queryText.toLowerCase();
        final id = student.studentId.toLowerCase();
        final code = student.studentCode.toLowerCase();
        final name = (student.fullName ?? '').toLowerCase();
        return id.contains(query) || code.contains(query) || name.contains(query);
      }).toList();
    } catch (e) {
      debugPrint('Error searching students: $e');
      return [];
    }
  }
}