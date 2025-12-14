import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/course_offering.dart';

class FacultyDataSource {
  final supabase = Supabase.instance.client;

  Future<List<CourseOffering>> getFacultyCourses(String facultyId, String role) async {
    try {
      // Get today's date
      final now = DateTime.now().toUtc();
      final today = DateTime(now.year, now.month, now.day);
      final todayStr = today.toIso8601String().split('T')[0];

      if (role == 'faculty') {
        // Fetch today's lecture instances for this faculty
        final response = await supabase
            .from('lectureinstance')
            .select('''
              linstanceid,
              lectureofferingid,
              meetingdate,
              starttime,
              endtime,
              lecturecourseoffering!inner(
                lectureofferingid,
                coursecode,
                facultysnn,
                slotid,
                roomid,
                course:coursecode(coursename),
                room:roomid(roomid),
                timeslot:slotid(dayofweek, starttime, endtime)
              )
            ''')
            .eq('lecturecourseoffering.facultysnn', facultyId)
            .eq('meetingdate', todayStr)
            .order('starttime', ascending: true);

        print("\n=======================");
        print("📥 RAW RESPONSE (Faculty Instances)");
        print("=======================");
        print(response);
        print("=======================\n");

        final courses = (response as List<dynamic>).map((e) {
          final offering = e['lecturecourseoffering'];
          final timeslot = offering['timeslot'];

          // Use instance times if available, otherwise fall back to slot times
          final startTime = e['starttime'] ?? timeslot?['starttime'];
          final endTime = e['endtime'] ?? timeslot?['endtime'];
          final dayOfWeek = timeslot?['dayofweek'] ?? '';

          final schedule = timeslot != null
              ? "$dayOfWeek | $startTime - $endTime"
              : "No Schedule";

          return CourseOffering(
            id: e['linstanceid'].toString(), // Use instance ID instead of offering ID
            courseCode: offering['coursecode'] ?? '',
            courseTitle: offering['course']?['coursename'] ?? '',
            schedule: schedule,
            offeringId: e['linstanceid'].toString(), // Instance ID for QR generation
          );
        }).toList();

        print("📚 Faculty Lecture Instances Today = ${courses.length}");
        return courses;
      }

      if (role == 'teacher_assistant') {
        // First get section offerings for this TA
        final sectionTAs = await supabase
            .from('sectionta')
            .select('sectionofferingid')
            .eq('tasnn', facultyId);

        if ((sectionTAs as List).isEmpty) {
          print("⚠️ No sections assigned to this TA");
          return [];
        }

        final sectionIds = sectionTAs.map((e) => e['sectionofferingid']).toList();

        // Fetch today's section instances for these sections
        final response = await supabase
            .from('sectioninstance')
            .select('''
              sinstanceid,
              sectionofferingid,
              meetingdate,
              weeknumber,
              sectioncourseoffering!inner(
                sectionofferingid,
                coursecode,
                groupnumber,
                slotid,
                roomid,
                course:coursecode(coursename),
                room:roomid(roomid),
                timeslot:slotid(dayofweek, starttime, endtime)
              )
            ''')
            .inFilter('sectionofferingid', sectionIds)
            .eq('meetingdate', todayStr)
            .order('weeknumber', ascending: true);

        print("\n=======================");
        print("📥 RAW RESPONSE (TA Instances)");
        print("=======================");
        print(response);
        print("=======================\n");

        final courses = (response as List<dynamic>).map((e) {
          final offering = e['sectioncourseoffering'];
          final timeslot = offering['timeslot'];

          final schedule = timeslot != null
              ? "${timeslot['dayofweek']} | ${timeslot['starttime']} - ${timeslot['endtime']}"
              : "No Schedule";

          return CourseOffering(
            id: e['sinstanceid'].toString(), // Use instance ID instead of offering ID
            courseCode: offering['coursecode'] ?? '',
            courseTitle: offering['course']?['coursename'] ?? 'Section ${offering['groupnumber']}',
            schedule: schedule,
            offeringId: e['sinstanceid'].toString(), // Instance ID for QR generation
          );
        }).toList();

        print("📚 TA Section Instances Today = ${courses.length}");
        return courses;
      }

      return [];
    } catch (e, stackTrace) {
      print('❌ Error fetching courses: $e');
      print('📍 Stack trace: $stackTrace');
      return [];
    }
  }
}