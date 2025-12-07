import '../../../helpers/supabase_remote_data_source.dart';
import '../../../helpers/Attendance.dart';
import '../../domain/repo/attendance_repository.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final SupabaseRemoteDataSource remoteDataSource;

  AttendanceRepositoryImpl(this.remoteDataSource);

  @override
  Future<void> markAttendance(String studentId, String instanceId) {
    return remoteDataSource.markAttendance(studentId, instanceId);
  }

  @override
  Future<List<Attendance>> getAttendanceForStudent(String studentId) {
    return remoteDataSource.getAttendanceForStudent(studentId);
  }

  @override
  Future<List<Attendance>> getAttendanceForLecture(String instanceId) {
    return remoteDataSource.getAttendanceForLecture(instanceId);
  }
}
