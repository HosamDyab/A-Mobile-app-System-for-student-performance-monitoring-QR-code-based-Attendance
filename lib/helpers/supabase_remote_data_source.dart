import '../Student/data/StudentModel.dart';
import '../Student/data/models/StudentDashboard.dart';
import 'attendance_model.dart';
import 'package:qra/ustils/supabase_manager.dart';

class SupabaseRemoteDataSource {
  final supabase = SupabaseManager.client;

  Future<void> markAttendance(String studentId, String instanceId) async {
    await supabase.from('LectureQR').insert({
      'StudentId': studentId,
      'InstanceId': instanceId,
      'Status': 'Present',
      'ScanTime': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<List<AttendanceModel>> getAttendanceForStudent(
      String studentId) async {
    final response = await supabase
        .from('LectureQR')
        .select('AttendanceId, StudentId, InstanceId, ScanTime, Status')
        .eq('StudentId', studentId);

    return response.map((json) => AttendanceModel.fromJson(json)).toList();
    }

  Future<List<AttendanceModel>> getAttendanceForLecture(
      String instanceId) async {
    final response = await supabase
        .from('LectureQR')
        .select('AttendanceId, StudentId, InstanceId, ScanTime, Status')
        .eq('InstanceId', instanceId);

    return response.map((json) => AttendanceModel.fromJson(json)).toList();
    }

  Future<StudentDashboard?> getStudentDashboard(String studentId) async {
    final response = await supabase.from('Student').select('''
          StudentId,
          Major,
          AcademicLevel,
          CurrentSemester,
          CumulativeGPA,
          User:UserId ( FullName )
        ''').eq('StudentId', studentId).maybeSingle();

    if (response == null) return null;

    return StudentDashboard(
      fullName: response['User']['FullName'],
      major: response['Major'],
      academicLevel: response['AcademicLevel'],
      semester: response['CurrentSemester'],
      gpa: (response['CurrentGPA'] ?? 0).toDouble(),
    );
  }

  Future<List<Map<String, dynamic>>> getCurrentCourses(String studentId) async {
    final data = await supabase.from('StudentSection').select('''
          SectionCourseOffering (
            Semester,
            AcademicYear,
            Course:CourseId (
              Title
            ),
            SectionGrade (
              Total,
              LetterGrade
            )
          )
        ''').eq('StudentId', studentId);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<StudentModel?> getStudentById(String studentId) async {
    final response = await supabase.from('Student').select('''
          StudentId,
          StudentCode,
          Major,
          AcademicLevel,
          CurrentSemester,
          CumulativeGPA,
          User:UserId ( FullName, Email, Phone )
        ''').eq('StudentId', studentId).maybeSingle();

    if (response == null) return null;
    return StudentModel.fromJson(response);
  }
  Future<List<Map<String, dynamic>>> searchCourses(String studentId, String query) async {
    final data = await supabase.from('StudentSection').select('''
    SectionCourseOffering (
      Semester,
      AcademicYear,
      Course:CourseId (
        Title
      ),
      SectionGrade (
        Total,
        LetterGrade
      )
    )
  ''')
        .eq('StudentId', studentId)
        .ilike('SectionCourseOffering.Course.Title', '%$query%');

    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> searchFaculty(String studentId, String query) async {
    final data = await supabase.from('StudentSection').select('''
    SectionCourseOffering (
      LectureOffering:LectureOfferingId (
        Faculty:FacultyId (
          User:UserId (
            FullName, Email
          )
        )
      )
    )
  ''')
        .eq('StudentId', studentId)
        .ilike('SectionCourseOffering.LectureOffering.Faculty.User.FullName', '%$query%');

    return List<Map<String, dynamic>>.from(data);
  }

}
