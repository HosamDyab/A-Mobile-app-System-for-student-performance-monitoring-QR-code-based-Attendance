import 'Attendance.dart';

class AttendanceModel extends Attendance {
  AttendanceModel({
    required super.studentId,
    required super.instanceId,
    required super.scanTime,
    required super.status,
  });

  // ============================================================
  // FACTORY FOR NEW SCHEMA (lectureattendance + sectionattendance)
  // ============================================================
  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      studentId: json['studentid'] ?? '',
      instanceId: json['linstanceid'] ?? json['sinstanceid'] ?? '',
      scanTime: json['scannedat'] != null
          ? DateTime.parse(json['scannedat']).toLocal()
          : DateTime.now(),
      status: (json['ispresent'] == true) ? 'Present' : 'Absent',
    );
  }

  // ============================================================
  // CONVERT TO JSON (IF NEEDED)
  // ============================================================
  Map<String, dynamic> toJson() => {
    'studentid': studentId,
    // choose correct column depending on type:
    'instanceid': instanceId,
    'scannedat': scanTime.toUtc().toIso8601String(),
    'ispresent': status == 'Present',
  };
}
