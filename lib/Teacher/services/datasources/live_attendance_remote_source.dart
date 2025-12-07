import 'package:qra/Teacher/models/lecture_attendance.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for attendance operations using Supabase
class LiveAttendanceRemoteDataSource {
  final supabase = Supabase.instance.client;

  /// Fetches attendance records for a specific lecture instance
  ///
  /// [instanceId] - The unique identifier for the lecture instance
  /// Returns a list of attendance models
  Future<List<LectureAttendanceModel>> getAttendanceForLecture(
      String instanceId) async {
    try {
      // Add debug print
      print('📊 Fetching attendance for instance: $instanceId');

      final response = await supabase.from('LectureQR').select('''
            AttendanceId, 
            StudentId, 
            InstanceId, 
            ScanTime, 
            Status,
            Student(
              StudentCode,
              User(FullName)
            )
          ''').eq('InstanceId', instanceId).order('ScanTime', ascending: false);

      print('📊 Attendance response count: ${(response as List).length}');

      // Response from Supabase select is always a List
      return (response as List<dynamic>)
          .map((json) =>
              LectureAttendanceModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching attendance: $e');
      return [];
    }
  }
}
