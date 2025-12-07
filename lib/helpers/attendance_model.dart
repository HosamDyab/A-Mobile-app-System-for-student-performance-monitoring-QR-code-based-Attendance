import 'Attendance.dart';

class AttendanceModel extends Attendance {
  AttendanceModel({
    required super.attendanceId,
    required super.studentId,
    required super.instanceId,
    required super.scanTime,
    required super.status,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      attendanceId: json['AttendanceId'] ?? '',
      studentId: json['StudentId'] ?? '',
      instanceId: json['InstanceId'] ?? '',
      scanTime: json['ScanTime'] != null
          ? DateTime.parse(json['ScanTime']).toLocal()
          : DateTime.now(),
      status: json['Status'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() => {
    'AttendanceId': attendanceId,
    'StudentId': studentId,
    'InstanceId': instanceId,
    'ScanTime': scanTime.toUtc().toIso8601String(),
    'Status': status,
  };
}
