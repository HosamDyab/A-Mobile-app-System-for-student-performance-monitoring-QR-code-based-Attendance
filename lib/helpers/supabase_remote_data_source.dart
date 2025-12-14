import '../Student/data/StudentModel.dart';
import '../Student/data/models/StudentDashboard.dart';
import 'attendance_model.dart';
import 'package:qra/ustils/supabase_manager.dart';

class SupabaseRemoteDataSource {
  final supabase = SupabaseManager.client;

  Future<void> markAttendance(String studentId, String instanceId) async {
    final now = DateTime.now().toUtc();

    // Try lecture instance first
    final lectureInstance = await supabase
        .from('lectureinstance')
        .select('linstanceid, lectureofferingid')
        .eq('linstanceid', instanceId)
        .maybeSingle();

    if (lectureInstance != null) {
      final lectureOfferingId = lectureInstance['lectureofferingid'];

      // Check if student is enrolled in this lecture
      final enrollment = await supabase
          .from('lectureenrollment')
          .select('studentid')
          .eq('studentid', studentId)
          .eq('lectureofferingid', lectureOfferingId)
          .maybeSingle();

      if (enrollment == null) {
        throw Exception('You are not enrolled in this lecture');
      }

      // Check if attendance already marked
      final existing = await supabase
          .from('lectureattendance')
          .select()
          .eq('studentid', studentId)
          .eq('linstanceid', instanceId)
          .maybeSingle();

      if (existing != null) {
        throw Exception('Attendance already marked');
      }

      // Mark attendance
      await supabase.from('lectureattendance').insert({
        'studentid': studentId,
        'linstanceid': instanceId,
        'ispresent': true,
        'scannedat': now.toIso8601String(),
      });

      return;
    }

    // Try section instance
    final sectionInstance = await supabase
        .from('sectioninstance')
        .select('sinstanceid, sectionofferingid')
        .eq('sinstanceid', instanceId)
        .maybeSingle();

    if (sectionInstance == null) {
      throw Exception('Invalid QR code - instance not found');
    }

    final sectionOfferingId = sectionInstance['sectionofferingid'];

    // Check if student is enrolled in this section
    final enrollment = await supabase
        .from('sectionenrollment')
        .select('studentid')
        .eq('studentid', studentId)
        .eq('sectionofferingid', sectionOfferingId)
        .maybeSingle();

    if (enrollment == null) {
      throw Exception('You are not enrolled in this section');
    }

    // Check if attendance already marked
    final existing = await supabase
        .from('sectionattendance')
        .select()
        .eq('studentid', studentId)
        .eq('sinstanceid', instanceId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('Attendance already marked');
    }

    // Mark attendance
    await supabase.from('sectionattendance').insert({
      'studentid': studentId,
      'sinstanceid': instanceId,
      'ispresent': true,
      'scannedat': now.toIso8601String(),
    });
  }

  Future<List<AttendanceModel>> getAttendanceForStudent(
      String studentId) async {
    final response = await supabase.from('lectureattendance').select('''
      studentid,
      linstanceid,
      scannedat,
      ispresent
    ''').eq('studentid', studentId);

    return response.map((json) => AttendanceModel.fromJson(json)).toList();
  }

  Future<List<AttendanceModel>> getAttendanceForLecture(
      String instanceId) async {
    final response = await supabase.from('lectureattendance').select('''
      studentid,
      linstanceid,
      scannedat,
      ispresent
    ''').eq('linstanceid', instanceId);

    return response.map((json) => AttendanceModel.fromJson(json)).toList();
  }

  Future<StudentDashboard?> getStudentDashboard(String studentId) async {
    final response = await supabase.from('student').select('''
      studentid,
      fullname,
      major,
      academiclevel,
      currentgpa
    ''').eq('studentid', studentId).maybeSingle();

    if (response == null) return null;

    return StudentDashboard(
      fullName: response['fullname'],
      major: response['major'],
      academicLevel: response['academiclevel'].toString(),
      semester: "N/A",
      gpa: (response['currentgpa'] ?? 0).toDouble(),
    );
  }

  Future<List<Map<String, dynamic>>> getCurrentCourses(String studentId) async {
    final data = await supabase.from('lectureenrollment').select('''
          lectureofferingid,
          lecturecourseoffering!inner (
            lectureofferingid,
            academicyear,
            semester,
            coursecode,
            course!inner (
              coursecode,
              coursename,
              credithours,
              haslab
            )
          )
        ''').eq('studentid', studentId);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<StudentModel?> getStudentById(String studentId) async {
    final response = await supabase.from('student').select('''
      studentid,
      fullname,
      email,
      major,
      academiclevel,
      currentgpa,
      totalcredithoursearned
    ''').eq('studentid', studentId).maybeSingle();

    if (response == null) return null;
    return StudentModel.fromJson(response);
  }


  Future<List<Map<String, dynamic>>> searchCourses(
      String studentId, String query) async {

    final allCourses = await getCurrentCourses(studentId);

     final filtered = allCourses.where((course) {
      final courseName = course['lecturecourseoffering']
      ?['course']?['coursename']?.toString().toLowerCase() ?? '';
      final courseCode = course['lecturecourseoffering']
      ?['course']?['coursecode']?.toString().toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();

      return courseName.contains(searchQuery) || courseCode.contains(searchQuery);
    }).toList();

    return filtered;
  }
  Future<List<Map<String, dynamic>>> searchFaculty(
      String studentId, String query) async {

    // 1️⃣ Get student enrollments
    final enrollments = await supabase
        .from('lectureenrollment')
        .select('lectureofferingid')
        .eq('studentid', studentId);

    if (enrollments.isEmpty) return [];

    final offeringIds = enrollments
        .map((e) => e['lectureofferingid'] as String)
        .toList();

    // 2️⃣ Get faculty via lecturecourseoffering (✅ CORRECT TABLE)
    final result = await supabase
        .from('lecturecourseoffering')
        .select('''
        lectureofferingid,
        faculty!inner (
          facultysnn,
          fullname,
          email,
          depcode
        )
      ''')
        .inFilter('lectureofferingid', offeringIds)
        .ilike('faculty.fullname', '%$query%');

    return List<Map<String, dynamic>>.from(result);
  }

}
















//
// Future<void> markAttendance(String studentId, String instanceId) async {
//   final now = DateTime.now().toUtc();
//
//   // Try lecture instance first
//   final lectureInstance = await supabase
//       .from('lectureinstance')
//       .select('linstanceid, lectureofferingid, qr_expires_at')
//       .eq('linstanceid', instanceId)
//       .maybeSingle();
//
//   if (lectureInstance != null) {
//     // Check if QR code has expired
//     final qrExpiresAt = lectureInstance['qr_expires_at'];
//     if (qrExpiresAt != null) {
//       final expiryTime = DateTime.parse(qrExpiresAt);
//       if (now.isAfter(expiryTime)) {
//         throw Exception('QR code has expired');
//       }
//     }
//
//     final lectureOfferingId = lectureInstance['lectureofferingid'];
//
//     // Check if student is enrolled in this lecture
//     final enrollment = await supabase
//         .from('lectureenrollment')
//         .select('studentid')
//         .eq('studentid', studentId)
//         .eq('lectureofferingid', lectureOfferingId)
//         .maybeSingle();
//
//     if (enrollment == null) {
//       throw Exception('You are not enrolled in this lecture');
//     }
//
//     // Check if attendance already marked
//     final existing = await supabase
//         .from('lectureattendance')
//         .select()
//         .eq('studentid', studentId)
//         .eq('linstanceid', instanceId)
//         .maybeSingle();
//
//     if (existing != null) {
//       throw Exception('Attendance already marked');
//     }
//
//     // Mark attendance
//     await supabase.from('lectureattendance').insert({
//       'studentid': studentId,
//       'linstanceid': instanceId,
//       'ispresent': true,
//       'scannedat': now.toIso8601String(),
//     });
//
//     return;
//   }
//
//   // Try section instance
//   final sectionInstance = await supabase
//       .from('sectioninstance')
//       .select('sinstanceid, sectionofferingid, qr_expires_at')
//       .eq('sinstanceid', instanceId)
//       .maybeSingle();
//
//   if (sectionInstance == null) {
//     throw Exception('Invalid QR code - instance not found');
//   }
//
//   // Check if QR code has expired
//   final qrExpiresAt = sectionInstance['qr_expires_at'];
//   if (qrExpiresAt != null) {
//     final expiryTime = DateTime.parse(qrExpiresAt);
//     if (now.isAfter(expiryTime)) {
//       throw Exception('QR code has expired');
//     }
//   }
//
//   final sectionOfferingId = sectionInstance['sectionofferingid'];
//
//   // Check if student is enrolled in this section
//   final enrollment = await supabase
//       .from('sectionenrollment')
//       .select('studentid')
//       .eq('studentid', studentId)
//       .eq('sectionofferingid', sectionOfferingId)
//       .maybeSingle();
//
//   if (enrollment == null) {
//     throw Exception('You are not enrolled in this section');
//   }
//
//   // Check if attendance already marked
//   final existing = await supabase
//       .from('sectionattendance')
//       .select()
//       .eq('studentid', studentId)
//       .eq('sinstanceid', instanceId)
//       .maybeSingle();
//
//   if (existing != null) {
//     throw Exception('Attendance already marked');
//   }
//
//   // Mark attendance
//   await supabase.from('sectionattendance').insert({
//     'studentid': studentId,
//     'sinstanceid': instanceId,
//     'ispresent': true,
//     'scannedat': now.toIso8601String(),
//   });
// }
