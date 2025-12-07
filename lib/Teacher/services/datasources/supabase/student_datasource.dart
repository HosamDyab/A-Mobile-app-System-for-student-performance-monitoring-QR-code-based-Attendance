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
        final lecturesResponse = await SupabaseService.client
            .from('LectureCourseOffering')
            .select('LectureOfferingId')
            .eq('FacultyId', facultyId)
            .eq('IsActive', true);

        final lectureIds = (lecturesResponse as List)
            .map((l) => l['LectureOfferingId'])
            .whereType<dynamic>()
            .toList();

        if (lectureIds.isNotEmpty) {
          // Get students enrolled in these lectures directly
          final enrollmentsResponse = await SupabaseService.client
              .from('LectureStudentEnrollment')
              .select('StudentId, Student(*, User(FullName, Email))')
              .inFilter('LectureOfferingId', lectureIds)
              .eq('EnrollmentStatus', 'Enrolled');

          final studentSet = <String>{};
          for (var item in enrollmentsResponse as List) {
            final studentData = item['Student'];
            if (studentData != null) {
              final studentId = studentData['StudentId']?.toString();
              if (studentId != null && !studentSet.contains(studentId)) {
                studentSet.add(studentId);
                students.add(StudentModel.fromJson(studentData));
              }
            }
          }
        }
      } else if (role == 'teacher_assistant') {
        // For TA: Get students from their assigned sections
        final sectionsResponse = await SupabaseService.client
            .from('SectionCourseOffering')
            .select('SectionOfferingId, LectureOfferingId')
            .eq('TAId', facultyId)
            .eq('IsActive', true);

        final lectureIds = (sectionsResponse as List)
            .map((s) => s['LectureOfferingId'])
            .whereType<dynamic>()
            .toList();

        if (lectureIds.isNotEmpty) {
          // Get students enrolled in the parent lecture courses
          final enrollmentsResponse = await SupabaseService.client
              .from('LectureStudentEnrollment')
              .select('StudentId, Student(*, User(FullName, Email))')
              .inFilter('LectureOfferingId', lectureIds)
              .eq('EnrollmentStatus', 'Enrolled');

          final studentSet = <String>{};
          for (var item in enrollmentsResponse as List) {
            final studentData = item['Student'];
            if (studentData != null) {
              final studentId = studentData['StudentId']?.toString();
              if (studentId != null && !studentSet.contains(studentId)) {
                studentSet.add(studentId);
                students.add(StudentModel.fromJson(studentData));
              }
            }
          }
        }
      }

      // Apply level filter if specified
      if (level != null && level != 'All Levels') {
        students = students.where((s) => s.academicLevel == level).toList();
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
        .from('Student')
        .select('*, User(FullName, Email)')
        .eq('StudentId', id)
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
        return id.contains(query) ||
            code.contains(query) ||
            name.contains(query);
      }).toList();
    } catch (e) {
      debugPrint('Error searching students: $e');
      return [];
    }
  }
}
