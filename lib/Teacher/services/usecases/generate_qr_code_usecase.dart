import '../repositories/attendance_repository.dart';

class GenerateQRCodeUseCase {
  final AttendanceRepository repository;
  
  GenerateQRCodeUseCase(this.repository);
  
  Future<String> execute() async {
    // Generate a unique session ID
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    return sessionId;
  }
}