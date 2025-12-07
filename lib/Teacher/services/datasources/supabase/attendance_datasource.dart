import '../../../models/attendance_model.dart';
import '../../supabase_service.dart';

/// Data source for attendance-related operations with Supabase
class AttendanceDataSource {
  Future<AttendanceModel> createAttendanceSession(String studentId) async {
    final now = DateTime.now();
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    
    final attendance = {
      'student_id': studentId,
      'session_id': sessionId,
      'check_in_time': now.toIso8601String(),
      'status': 'present',
    };
    
    final response = await SupabaseService.client
        .from('LectureQR')
        .insert(attendance)
        .select()
        .single();
    
    return AttendanceModel.fromJson(response);
  }
  
  Future<List<AttendanceModel>> getLiveAttendance(String sessionId) async {
    final response = await SupabaseService.client
        .from('attendance')
        .select()
        .eq('session_id', sessionId)
        .order('check_in_time', ascending: false);
    
    return (response as List<dynamic>)
        .map((e) => AttendanceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
  
  Future<void> endSession(String sessionId) async {
    await SupabaseService.client
        .from('attendance_sessions')
        .update({'ended_at': DateTime.now().toIso8601String()})
        .eq('id', sessionId);
  }
}