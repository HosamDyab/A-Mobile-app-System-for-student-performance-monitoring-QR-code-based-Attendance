import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/lecture_attendance.dart';

class LiveAttendanceRemoteDataSource {
  final supabase = Supabase.instance.client;

  /// Fetch attendance for a lecture or section instance
  Future<List<LectureAttendanceModel>> getAttendanceForLecture(
      String instanceId) async {
    try {
      print("📡 ========================================");
      print("📡 Fetching attendance for instance: $instanceId");
      print("📡 ========================================");

      // First, try to detect by checking which table has this instance ID
      // Your instanceId format: IS351-2025-FALL-G1-OFR-w13-SAT-4
      // This doesn't start with L or S, so we need a different approach

      String? tableName;
      String? instanceColumn;

      // Try lecture table first
      try {
        final lectureCheck = await supabase
            .from('lectureinstance')
            .select('linstanceid')
            .eq('linstanceid', instanceId)
            .maybeSingle();

        if (lectureCheck != null) {
          tableName = 'lectureattendance';
          instanceColumn = 'linstanceid';
          print("✅ Found in lectureinstance table - using lectureattendance");
        }
      } catch (e) {
        print("⚠️ Not found in lectureinstance: $e");
      }

      // If not found in lecture, try section table
      if (tableName == null) {
        try {
          final sectionCheck = await supabase
              .from('sectioninstance')
              .select('sinstanceid')
              .eq('sinstanceid', instanceId)
              .maybeSingle();

          if (sectionCheck != null) {
            tableName = 'sectionattendance';
            instanceColumn = 'sinstanceid';
            print("✅ Found in sectioninstance table - using sectionattendance");
          }
        } catch (e) {
          print("⚠️ Not found in sectioninstance: $e");
        }
      }

      // If still not found, return empty
      if (tableName == null || instanceColumn == null) {
        print("❌ Instance ID not found in either lectureinstance or sectioninstance tables!");
        print("❌ Make sure the instance exists in the database before starting attendance.");
        return [];
      }

      print("📘 Query details:");
      print("   - Table: $tableName");
      print("   - Column: $instanceColumn");
      print("   - Looking for: $instanceId");

      // Fetch from Supabase with JOIN on student table
      final response = await supabase
          .from(tableName)
          .select('''
            ${instanceColumn},
            studentid,
            scannedat,
            ispresent,
            student:studentid (
              fullname,
              email,
              studentid
            )
          ''')
          .eq(instanceColumn, instanceId)
          .order('scannedat', ascending: false);

      print("📦 Raw response type: ${response.runtimeType}");

      final list = response as List<dynamic>;
      print("📦 Number of records fetched: ${list.length}");

      if (list.isEmpty) {
        print("⚠️ No attendance records found yet. Waiting for students to scan...");
      }

      // Convert response → List<LectureAttendanceModel>
      final models = list.map((json) {
        print("🔄 Processing record: $json");

        final student = json["student"];
        print("   Student data: $student");

        final model = LectureAttendanceModel.fromJson({
          "AttendanceId": "${json[instanceColumn]}_${json["studentid"]}",
          "StudentId": json["studentid"] ?? '',
          "InstanceId": instanceId,
          "ScanTime": json["scannedat"] ?? DateTime.now().toIso8601String(),
          "Status": json["ispresent"] == true ? "Present" : "Absent",
          "Student": {
            "FullName": student?["fullname"] ?? 'Unknown',
            "StudentCode": student?["studentid"] ?? '',
          }
        });

        print("   ✅ Created model: ${model.studentName} (${model.studentCode})");

        return model;
      }).toList();

      print("✅ Successfully processed ${models.length} attendance records");
      print("📡 ========================================");

      return models;
    } catch (e, stackTrace) {
      print("❌ ========================================");
      print("❌ Error fetching attendance: $e");
      print("❌ Stack trace: $stackTrace");
      print("❌ ========================================");
      rethrow;
    }
  }
}