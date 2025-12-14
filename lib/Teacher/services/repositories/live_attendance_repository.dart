import '../../models/lecture_attendance.dart';

abstract class LiveAttendanceRepository {
  Future<List<LectureAttendance>> getAttendanceForLecture(String instanceId);
}