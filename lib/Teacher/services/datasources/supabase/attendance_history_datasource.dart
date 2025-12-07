import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/attendance_record.dart';

/// Data source for attendance history operations
class AttendanceHistoryDataSource {
  final supabase = Supabase.instance.client;

  /// Get all attendance records with full details
  Future<List<AttendanceRecord>> getAllAttendanceRecords({
    String? courseCode,
    int? weekNumber,
    DateTime? startDate,
    DateTime? endDate,
    String? facultyId,
  }) async {
    try {
      dynamic query = supabase.from('LectureQR').select('''
            AttendanceId,
            StudentId,
            InstanceId,
            ScanTime,
            Status,
            Student!inner(
              StudentCode,
              User!inner(FullName)
            ),
            LectureInstance!inner(
              WeekNumber,
              LectureCourseOffering!inner(
                FacultyId,
                Course!inner(Code, Title)
              )
            )
          ''');

      // Apply filters
      if (startDate != null) {
        query = query.gte('ScanTime', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('ScanTime', endDate.toIso8601String());
      }

      // Order and limit results for performance
      final response =
          await query.order('ScanTime', ascending: false).limit(500);

      var records = (response as List<dynamic>)
          .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
          .toList();

      // Apply post-fetch filters
      if (courseCode != null && courseCode.isNotEmpty) {
        records = records
            .where((r) =>
                r.courseCode
                    ?.toLowerCase()
                    .contains(courseCode.toLowerCase()) ??
                false)
            .toList();
      }

      if (weekNumber != null) {
        records = records.where((r) => r.weekNumber == weekNumber).toList();
      }

      if (facultyId != null) {
        // Filter by faculty after fetching (since nested filtering is complex)
        records = records.where((r) {
          // This would need the faculty ID from the lecture offering
          // For now, keep all records as the UI should handle faculty-specific filtering
          return true;
        }).toList();
      }

      return records;
    } catch (e) {
      print('Error fetching attendance records: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// Get attendance records for a specific lecture instance
  Future<List<AttendanceRecord>> getAttendanceByInstance(
      String instanceId) async {
    try {
      final response = await supabase.from('LectureQR').select('''
            AttendanceId,
            StudentId,
            InstanceId,
            ScanTime,
            Status,
            Student!inner(
              StudentCode,
              User!inner(FullName)
            ),
            LectureInstance!inner(
              WeekNumber,
              LectureCourseOffering!inner(
                FacultyId,
                Course!inner(Code, Title)
              )
            )
          ''').eq('InstanceId', instanceId).order('ScanTime', ascending: false);

      return (response as List<dynamic>)
          .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching attendance for instance: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// Search attendance by student name or code
  Future<List<AttendanceRecord>> searchAttendance(String query) async {
    try {
      final response = await supabase
          .from('LectureQR')
          .select('''
            AttendanceId,
            StudentId,
            InstanceId,
            ScanTime,
            Status,
            Student!inner(
              StudentCode,
              User!inner(FullName)
            ),
            LectureInstance!inner(
              WeekNumber,
              LectureCourseOffering!inner(
                FacultyId,
                Course!inner(Code, Title)
              )
            )
          ''')
          .order('ScanTime', ascending: false)
          .limit(200); // Limit for performance

      final allRecords = (response as List<dynamic>)
          .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
          .toList();

      // Filter by student name or code
      return allRecords.where((record) {
        final name = record.studentName?.toLowerCase() ?? '';
        final code = record.studentCode?.toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();
        return name.contains(searchQuery) || code.contains(searchQuery);
      }).toList();
    } catch (e) {
      print('Error searching attendance: $e');
      print('Stack trace: ${StackTrace.current}');
      return [];
    }
  }
}
