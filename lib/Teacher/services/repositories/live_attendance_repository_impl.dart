
import 'package:qra/Teacher/models/lecture_attendance.dart';
import 'package:qra/Teacher/services/repositories/live_attendance_repository.dart';
import 'package:qra/Teacher/services/datasources/live_attendance_remote_source.dart';

class LiveAttendanceRepositoryImpl implements LiveAttendanceRepository {
  final LiveAttendanceRemoteDataSource remoteDataSource;

  LiveAttendanceRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<LectureAttendance>> getAttendanceForLecture(String instanceId) async {
    final models = await remoteDataSource.getAttendanceForLecture(instanceId);
    return models; 
  }
}
