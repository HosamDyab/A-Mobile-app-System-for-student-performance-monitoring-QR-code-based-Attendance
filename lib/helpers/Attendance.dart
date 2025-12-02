class Attendance {
  final String attendanceId;
  final String studentId;
  final String instanceId;
  final DateTime scanTime;
  final String status;

  Attendance({
    required this.attendanceId,
    required this.studentId,
    required this.instanceId,
    required this.scanTime,
    required this.status,
  });
}
