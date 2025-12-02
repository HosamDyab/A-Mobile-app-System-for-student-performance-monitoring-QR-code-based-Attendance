/// Model for Attendance Record with full details
class AttendanceRecord {
  final String attendanceId;
  final String studentId;
  final String? studentName;
  final String? studentCode;
  final String instanceId;
  final DateTime scanTime;
  final String status;
  final String? courseTitle;
  final String? courseCode;
  final int? weekNumber;

  AttendanceRecord({
    required this.attendanceId,
    required this.studentId,
    this.studentName,
    this.studentCode,
    required this.instanceId,
    required this.scanTime,
    required this.status,
    this.courseTitle,
    this.courseCode,
    this.weekNumber,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      attendanceId: json['AttendanceId']?.toString() ?? '',
      studentId: json['StudentId']?.toString() ?? '',
      studentName: json['Student']?['User']?['FullName'] as String?,
      studentCode: json['Student']?['StudentCode'] as String?,
      instanceId: json['InstanceId']?.toString() ?? '',
      scanTime: json['ScanTime'] != null 
          ? DateTime.parse(json['ScanTime'].toString())
          : DateTime.now(),
      status: json['Status']?.toString() ?? 'Present',
      courseTitle: json['LectureInstance']?['LectureOffering']?['Course']?['Title'] as String?,
      courseCode: json['LectureInstance']?['LectureOffering']?['Course']?['Code'] as String?,
      weekNumber: json['LectureInstance']?['WeekNumber'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'AttendanceId': attendanceId,
      'StudentId': studentId,
      'StudentName': studentName,
      'StudentCode': studentCode,
      'InstanceId': instanceId,
      'ScanTime': scanTime.toIso8601String(),
      'Status': status,
      'CourseTitle': courseTitle,
      'CourseCode': courseCode,
      'WeekNumber': weekNumber,
    };
  }
}

