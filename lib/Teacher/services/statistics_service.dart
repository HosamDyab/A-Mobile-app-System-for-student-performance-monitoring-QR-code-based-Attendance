import 'package:qra/ustils/supabase_manager.dart';

/// Service for fetching teacher/faculty statistics
class StatisticsService {
  final supabase = SupabaseManager.client;

  /// Get active sessions count (lecture/section instances for today)
  Future<int> getActiveSessions(String userSnn, String role) async {
    try {
      final now = DateTime.now().toUtc();
      final today = DateTime(now.year, now.month, now.day);
      final todayStr = today.toIso8601String().split('T')[0];

      if (role == 'teacher_assistant') {
        // For TAs: Count today's section instances
        final response = await supabase
            .from('sectioninstance')
            .select('sinstanceid, sectioncourseoffering!inner(sectionofferingid, sectionta!inner(tasnn))')
            .eq('sectioncourseoffering.sectionta.tasnn', userSnn)
            .eq('meetingdate', todayStr);

        return (response as List).length;
      } else {
        // For Faculty: Count today's lecture instances
        final response = await supabase
            .from('lectureinstance')
            .select('linstanceid, lecturecourseoffering!inner(facultysnn)')
            .eq('lecturecourseoffering.facultysnn', userSnn)
            .eq('meetingdate', todayStr);

        return (response as List).length;
      }
    } catch (e) {
      print('Error fetching active sessions: $e');
      return 0;
    }
  }

  /// Get total students count across all faculty's courses
  Future<int> getTotalStudents(String userSnn, String role) async {
    try {
      if (role == 'teacher_assistant') {
        // For TAs: Count students in their sections
        // First get section offerings assigned to this TA
        final sectionTAs = await supabase
            .from('sectionta')
            .select('sectionofferingid')
            .eq('tasnn', userSnn);

        if ((sectionTAs as List).isEmpty) return 0;

        final sectionIds = sectionTAs.map((e) => e['sectionofferingid']).toList();

        // Get students enrolled in these sections
        final enrollments = await supabase
            .from('sectionenrollment')
            .select('studentid')
            .inFilter('sectionofferingid', sectionIds);

        // Get unique student IDs
        final uniqueStudents = <String>{};
        for (var item in enrollments as List) {
          uniqueStudents.add(item['studentid']);
        }

        return uniqueStudents.length;
      } else {
        // For Faculty: Count students enrolled in their lectures
        final lectureOfferings = await supabase
            .from('lecturecourseoffering')
            .select('lectureofferingid')
            .eq('facultysnn', userSnn);

        if ((lectureOfferings as List).isEmpty) return 0;

        final lectureIds = lectureOfferings.map((e) => e['lectureofferingid']).toList();

        final enrollments = await supabase
            .from('lectureenrollment')
            .select('studentid')
            .inFilter('lectureofferingid', lectureIds);

        // Get unique student IDs
        final uniqueStudents = <String>{};
        for (var item in enrollments as List) {
          uniqueStudents.add(item['studentid']);
        }

        return uniqueStudents.length;
      }
    } catch (e) {
      print('Error fetching student count: $e');
      return 0;
    }
  }

  /// Get today's lectures/sections count
  Future<int> getActiveTodayLectures(String userSnn, String role) async {
    try {
      final now = DateTime.now().toUtc();
      final today = DateTime(now.year, now.month, now.day);
      final todayStr = today.toIso8601String().split('T')[0];

      if (role == 'teacher_assistant') {
        // For TAs: Get today's section instances
        // First get section offerings for this TA
        final sectionTAs = await supabase
            .from('sectionta')
            .select('sectionofferingid')
            .eq('tasnn', userSnn);

        if ((sectionTAs as List).isEmpty) return 0;

        final sectionIds = sectionTAs.map((e) => e['sectionofferingid']).toList();

        final response = await supabase
            .from('sectioninstance')
            .select('sinstanceid')
            .inFilter('sectionofferingid', sectionIds)
            .eq('meetingdate', todayStr);

        return (response as List).length;
      } else {
        // For Faculty: Get today's lecture instances
        final lectureOfferings = await supabase
            .from('lecturecourseoffering')
            .select('lectureofferingid')
            .eq('facultysnn', userSnn);

        if ((lectureOfferings as List).isEmpty) return 0;

        final lectureIds = lectureOfferings.map((e) => e['lectureofferingid']).toList();

        final response = await supabase
            .from('lectureinstance')
            .select('linstanceid')
            .inFilter('lectureofferingid', lectureIds)
            .eq('meetingdate', todayStr);

        return (response as List).length;
      }
    } catch (e) {
      print('Error fetching active today lectures: $e');
      return 0;
    }
  }

  /// Get all statistics at once
  Future<Map<String, int>> getAllStatistics(String userSnn, String role) async {
    final results = await Future.wait([
      getActiveTodayLectures(userSnn, role),
      getActiveSessions(userSnn, role),
      getTotalStudents(userSnn, role),
    ]);

    return {
      'todayLectures': results[0],
      'activeSessions': results[1],
      'totalStudents': results[2],
    };
  }
}