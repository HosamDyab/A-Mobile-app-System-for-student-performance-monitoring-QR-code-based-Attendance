class LectureAttendance {
  final String attendanceId;
  final String studentId;
  final String instanceId;
  final DateTime scanTime;
  final String status;
  final String? studentName;
  final String? studentCode;

  LectureAttendance({
    required this.attendanceId,
    required this.studentId,
    required this.instanceId,
    required this.scanTime,
    required this.status,
    this.studentName,
    this.studentCode,
  });
}

class LectureAttendanceModel extends LectureAttendance {
  LectureAttendanceModel({
    required super.attendanceId,
    required super.studentId,
    required super.instanceId,
    required super.scanTime,
    required super.status,
    super.studentName,
    super.studentCode,
  });

  factory LectureAttendanceModel.fromJson(Map<String, dynamic> json) {
    return LectureAttendanceModel(
      attendanceId: json['AttendanceId'],
      studentId: json['StudentId'],
      instanceId: json['InstanceId'],
      scanTime: DateTime.parse(json['ScanTime']),
      status: json['Status'],
      studentName: json['Student']?['User']?['FullName'] as String?,
      studentCode: json['Student']?['StudentCode'] as String?,
    );
  }
}
