// student_datasource.dart

import 'package:flutter/foundation.dart';
import '../../../models/student_model.dart';
import '../../supabase_service.dart';

/// Data source for student-related operations with Supabase
class StudentDataSource {
  Future<List<StudentModel>> getAllStudents({
    String? level,
    String? status,
    String? facultyId,
    String? role,
  }) async {
    try {
      // If facultyId and role are provided, get students for that faculty/TA
      if (facultyId != null && role != null) {
        return await _getStudentsForFacultyOrTA(facultyId, role, level);
      }

      // Otherwise, get all students
      var query = SupabaseService.client
          .from('student')
          .select('*');

      // Apply level filter if specified
      if (level != null && level != 'All Levels') {
        // Extract numeric level from "L1", "L2", etc.
        final numericLevel = int.tryParse(level.replaceAll('L', ''));
        if (numericLevel != null) {
          query = query.eq('academiclevel', numericLevel);
        }
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

  /// Get students for a specific faculty member or TA
  Future<List<StudentModel>> _getStudentsForFacultyOrTA(
      String facultyId,
      String role,
      String? level,
      ) async {
    try {
      List<StudentModel> students = [];

      if (role == 'faculty') {
        // For Faculty: Get students enrolled in their lecture courses
        // Step 1: Get lecture offerings for this faculty
        final lecturesResponse = await SupabaseService.client
            .from('lecturecourseoffering')
            .select('lectureofferingid')
            .eq('facultysnn', facultyId);

        final lectureIds = (lecturesResponse as List)
            .map((l) => l['lectureofferingid'])
            .whereType<String>()
            .toList();

        if (lectureIds.isNotEmpty) {
          // Step 2: Get students enrolled in these lectures
          final enrollmentsResponse = await SupabaseService.client
              .from('lectureenrollment')
              .select('studentid')
              .inFilter('lectureofferingid', lectureIds);

          final studentIds = (enrollmentsResponse as List)
              .map((e) => e['studentid'])
              .whereType<String>()
              .toSet()
              .toList();

          if (studentIds.isNotEmpty) {
            // Step 3: Get student details
            final studentsResponse = await SupabaseService.client
                .from('student')
                .select('*')
                .inFilter('studentid', studentIds);

            students = (studentsResponse as List)
                .map((s) => StudentModel.fromJson(s as Map<String, dynamic>))
                .toList();
          }
        }
      } else if (role == 'teacher_assistant') {
        // For TA: Get students from their assigned sections
        // Step 1: Get section offerings for this TA
        final sectionsResponse = await SupabaseService.client
            .from('sectionta')
            .select('sectionofferingid')
            .eq('tasnn', facultyId);

        final sectionIds = (sectionsResponse as List)
            .map((s) => s['sectionofferingid'])
            .whereType<String>()
            .toList();

        if (sectionIds.isNotEmpty) {
          // Step 2: Get students enrolled in these sections
          final enrollmentsResponse = await SupabaseService.client
              .from('sectionenrollment')
              .select('studentid')
              .inFilter('sectionofferingid', sectionIds);

          final studentIds = (enrollmentsResponse as List)
              .map((e) => e['studentid'])
              .whereType<String>()
              .toSet()
              .toList();

          if (studentIds.isNotEmpty) {
            // Step 3: Get student details
            final studentsResponse = await SupabaseService.client
                .from('student')
                .select('*')
                .inFilter('studentid', studentIds);

            students = (studentsResponse as List)
                .map((s) => StudentModel.fromJson(s as Map<String, dynamic>))
                .toList();
          }
        }
      }

      // Apply level filter if specified
      if (level != null && level != 'All Levels') {
        final numericLevel = int.tryParse(level.replaceAll('L', ''));
        if (numericLevel != null) {
          students = students
              .where((s) => s.academicLevel == numericLevel)
              .toList();
        }
      }

      return students;
    } catch (e) {
      debugPrint('Error fetching students for $role: $e');
      // Fallback to all students
      return await getAllStudents(level: level);
    }
  }

  Future<StudentModel> getStudentById(String id) async {
    final response = await SupabaseService.client
        .from('student')
        .select('*')
        .eq('studentid', id)
        .single();

    return StudentModel.fromJson(response);
  }

  Future<List<StudentModel>> searchStudents(String queryText) async {
    try {
      // Fetch all students
      final response = await SupabaseService.client
          .from('student')
          .select('*');

      final allStudents = (response as List<dynamic>)
          .map((e) => StudentModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // Filter by student ID, email, or name
      return allStudents.where((student) {
        final query = queryText.toLowerCase();
        final id = student.studentId.toLowerCase();
        final email = student.email.toLowerCase();
        final name = student.fullName.toLowerCase();
        return id.contains(query) ||
            email.contains(query) ||
            name.contains(query);
      }).toList();
    } catch (e) {
      debugPrint('Error searching students: $e');
      return [];
    }
  }
}