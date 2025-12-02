import '../../models/attendance_entity.dart';
import '../repositories/attendance_repository.dart';

class MarkAttendanceUseCase {
  final AttendanceRepository repository;
  
  MarkAttendanceUseCase(this.repository);
  
  Future<AttendanceEntity> execute(String studentId) async {
    return await repository.createAttendanceSession(studentId);
  }
}