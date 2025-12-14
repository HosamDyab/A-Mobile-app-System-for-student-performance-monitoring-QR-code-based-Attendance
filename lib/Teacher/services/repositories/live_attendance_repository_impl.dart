import '../../models/lecture_attendance.dart';
import '../datasources/live_attendance_remote_source.dart';
import 'live_attendance_repository.dart';

class LiveAttendanceRepositoryImpl implements LiveAttendanceRepository {
  final LiveAttendanceRemoteDataSource remoteDataSource;

  LiveAttendanceRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<LectureAttendance>> getAttendanceForLecture(
      String instanceId) async {
    final models = await remoteDataSource.getAttendanceForLecture(instanceId);
    return models;
  }
}