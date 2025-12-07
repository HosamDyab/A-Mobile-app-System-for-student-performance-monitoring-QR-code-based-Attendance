import '../../models/attendance_entity.dart';
import '../datasources/supabase/attendance_datasource.dart';

class AttendanceRepository {
  final AttendanceDataSource _dataSource;
  
  AttendanceRepository(this._dataSource);
  
  Future<AttendanceEntity> createAttendanceSession(String studentId) async {
    final model = await _dataSource.createAttendanceSession(studentId);
    return AttendanceEntity.fromModel(model);
  }
  
  Future<List<AttendanceEntity>> getLiveAttendance(String sessionId) async {
    final models = await _dataSource.getLiveAttendance(sessionId);
    return models.map((model) => AttendanceEntity.fromModel(model)).toList();
  }
  
  Future<void> endSession(String sessionId) async {
    await _dataSource.endSession(sessionId);
  }
}