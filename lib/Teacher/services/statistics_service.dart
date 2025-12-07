import 'package:qra/ustils/supabase_manager.dart';

/// Service for fetching teacher/faculty statistics
class StatisticsService {
  final supabase = SupabaseManager.client;

  /// Get active sessions count (QR codes that haven't expired)
  Future<int> getActiveSessions(String facultyId, String role) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      
      if (role == 'teacher_assistant') {
        // For TAs: Count active section instances
        final response = await supabase
            .from('SectionInstance')
            .select('InstanceId, SectionCourseOffering!inner(TAId)')
            .eq('SectionCourseOffering.TAId', facultyId)
            .gte('QRExpiresAt', now)
            .eq('IsCancelled', false);
        
        return (response as List).length;
      } else {
        // For Faculty: Count active lecture instances
        final response = await supabase
            .from('LectureInstance')
            .select('InstanceId, LectureCourseOffering!inner(FacultyId)')
            .eq('LectureCourseOffering.FacultyId', facultyId)
            .gte('QRExpiresAt', now)
            .eq('IsCancelled', false);
        
        return (response as List).length;
      }
    } catch (e) {
      print('Error fetching active sessions: $e');
      return 0;
    }
  }

  /// Get total students count across all faculty's courses
  Future<int> getTotalStudents(String facultyId, String role) async {
    try {
      if (role == 'teacher_assistant') {
        // For TAs: Count students in their sections
        final response = await supabase
            .from('StudentSection')
            .select('StudentId, SectionCourseOffering!inner(TAId)')
            .eq('SectionCourseOffering.TAId', facultyId);
        
        // Get unique student IDs
        final studentIds = (response as List)
            .map((e) => e['StudentId'])
            .toSet()
            .length;
        
        return studentIds;
      } else {
        // For Faculty: Count students enrolled in their lectures via sections
        final response = await supabase.rpc('get_faculty_student_count', params: {
          'faculty_id_param': facultyId,
        });
        
        return response as int? ?? 0;
      }
    } catch (e) {
      print('Error fetching student count: $e');
      // Fallback: try direct query
      try {
        if (role == 'teacher_assistant') {
          final response = await supabase
              .from('StudentSection')
              .select('StudentId, SectionOfferingId, SectionCourseOffering!inner(TAId)')
              .eq('SectionCourseOffering.TAId', facultyId);
          
          final uniqueStudents = <String>{};
          for (var item in response as List) {
            uniqueStudents.add(item['StudentId']);
          }
          return uniqueStudents.length;
        } else {
          // For faculty, get students through sections linked to their lectures
          final lectureOfferings = await supabase
              .from('LectureCourseOffering')
              .select('LectureOfferingId')
              .eq('FacultyId', facultyId)
              .eq('IsActive', true);
          
          if ((lectureOfferings as List).isEmpty) return 0;
          
          final lectureIds = lectureOfferings.map((e) => e['LectureOfferingId']).toList();
          
          final sections = await supabase
              .from('SectionCourseOffering')
              .select('SectionOfferingId')
              .inFilter('LectureOfferingId', lectureIds);
          
          if ((sections as List).isEmpty) return 0;
          
          final sectionIds = sections.map((e) => e['SectionOfferingId']).toList();
          
          final students = await supabase
              .from('StudentSection')
              .select('StudentId')
              .inFilter('SectionOfferingId', sectionIds);
          
          final uniqueStudents = <String>{};
          for (var item in students as List) {
            uniqueStudents.add(item['StudentId']);
          }
          return uniqueStudents.length;
        }
      } catch (fallbackError) {
        print('Fallback query also failed: $fallbackError');
        return 0;
      }
    }
  }

  /// Get today's lectures/sections that are still active (not expired)
  Future<int> getActiveTodayLectures(String facultyId, String role) async {
    try {
      final now = DateTime.now().toUtc();
      final today = DateTime(now.year, now.month, now.day);
      
      if (role == 'teacher_assistant') {
        final response = await supabase
            .from('SectionInstance')
            .select('InstanceId, SectionCourseOffering!inner(TAId)')
            .eq('SectionCourseOffering.TAId', facultyId)
            .eq('MeetingDate', today.toIso8601String().split('T')[0])
            .gte('QRExpiresAt', now.toIso8601String())
            .eq('IsCancelled', false);
        
        return (response as List).length;
      } else {
        final response = await supabase
            .from('LectureInstance')
            .select('InstanceId, LectureCourseOffering!inner(FacultyId)')
            .eq('LectureCourseOffering.FacultyId', facultyId)
            .eq('MeetingDate', today.toIso8601String().split('T')[0])
            .gte('QRExpiresAt', now.toIso8601String())
            .eq('IsCancelled', false);
        
        return (response as List).length;
      }
    } catch (e) {
      print('Error fetching active today lectures: $e');
      return 0;
    }
  }

  /// Get all statistics at once
  Future<Map<String, int>> getAllStatistics(String facultyId, String role) async {
    final results = await Future.wait([
      getActiveTodayLectures(facultyId, role),
      getActiveSessions(facultyId, role),
      getTotalStudents(facultyId, role),
    ]);

    return {
      'todayLectures': results[0],
      'activeSessions': results[1],
      'totalStudents': results[2],
    };
  }
}

