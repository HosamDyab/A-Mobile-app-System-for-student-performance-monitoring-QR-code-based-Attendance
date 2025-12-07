import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/teacher_assistant.dart';

/// Data source for Teacher Assistant operations
class TeacherAssistantDataSource {
  final supabase = Supabase.instance.client;

  /// Get all teacher assistants with their user details
  Future<List<TeacherAssistant>> getAllTeacherAssistants() async {
    try {
      final response = await supabase
          .from('TeacherAssistant')
          .select('*, User(FullName, Email)')
          .order('TAId');

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
      // First get all TAs with user info
      final response = await supabase
          .from('TeacherAssistant')
          .select('*, User(FullName, Email)')
          .order('TAId');

      final allTAs = (response as List<dynamic>)
          .map((e) => TeacherAssistant.fromJson(e as Map<String, dynamic>))
          .toList();

      // Filter by name or email
      return allTAs.where((ta) {
        final name = ta.fullName?.toLowerCase() ?? '';
        final email = ta.email?.toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();
        return name.contains(searchQuery) || email.contains(searchQuery);
      }).toList();
    } catch (e) {
      print('Error searching teacher assistants: $e');
      return [];
    }
  }

  /// Get teacher assistants assigned to a specific faculty
  Future<List<TeacherAssistant>> getTeacherAssistantsByFaculty(String facultyId) async {
    try {
      final response = await supabase
          .from('TeacherAssistant')
          .select('*, User(FullName, Email)')
          .eq('FacultyId', facultyId)
          .order('TAId');

      return (response as List<dynamic>)
          .map((e) => TeacherAssistant.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching TAs for faculty: $e');
      return [];
    }
  }
}

