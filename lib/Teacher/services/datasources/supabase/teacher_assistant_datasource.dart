import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/teacher_assistant.dart';

/// Data source for Teacher Assistant operations
class TeacherAssistantDataSource {
  final supabase = Supabase.instance.client;

  /// Get all teacher assistants
  Future<List<TeacherAssistant>> getAllTeacherAssistants() async {
    try {
      final response = await supabase
          .from('ta')
          .select('*')
          .order('tasnn');

      return (response as List<dynamic>)
          .map((e) => TeacherAssistant.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching teacher assistants: $e');
      return [];
    }
  }

  /// Search teacher assistants by name or email
  Future<List<TeacherAssistant>> searchTeacherAssistants(String query) async {
    try {
      final searchQuery = query.toLowerCase();

      // Search using ilike for case-insensitive pattern matching
      final response = await supabase
          .from('ta')
          .select('*')
          .or('fullname.ilike.%$searchQuery%,email.ilike.%$searchQuery%')
          .order('tasnn');

      return (response as List<dynamic>)
          .map((e) => TeacherAssistant.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error searching teacher assistants: $e');
      return [];
    }
  }

  /// Get teacher assistants by department code
  Future<List<TeacherAssistant>> getTeacherAssistantsByDepartment(String depCode) async {
    try {
      final response = await supabase
          .from('ta')
          .select('*')
          .eq('depcode', depCode)
          .order('tasnn');

      return (response as List<dynamic>)
          .map((e) => TeacherAssistant.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching TAs for department: $e');
      return [];
    }
  }

  /// Get teacher assistants assigned to a specific course
  Future<List<TeacherAssistant>> getTeacherAssistantsByCourse(String courseCode) async {
    try {
      final response = await supabase
          .from('courseta')
          .select('ta(*)')
          .eq('coursecode', courseCode);

      return (response as List<dynamic>)
          .map((e) => TeacherAssistant.fromJson(e['ta'] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching TAs for course: $e');
      return [];
    }
  }
}