

import '../../../helpers/Attendance.dart';

abstract class AttendanceRepository {
  Future<void> markAttendance(String studentId, String instanceId);
  Future<List<Attendance>> getAttendanceForStudent(String studentId);
  Future<List<Attendance>> getAttendanceForLecture(String instanceId);
}
