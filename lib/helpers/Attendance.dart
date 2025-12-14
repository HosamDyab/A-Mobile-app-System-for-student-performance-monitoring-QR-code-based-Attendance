class Attendance {
  final String studentId;
  final String instanceId;     // works for lecture + section
  final DateTime scanTime;
  final String status;         // "Present" / "Absent"

  Attendance({
    required this.studentId,
    required this.instanceId,
    required this.scanTime,
    required this.status,
  });
}
