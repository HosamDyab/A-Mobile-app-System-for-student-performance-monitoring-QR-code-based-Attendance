class StudentDashboard {
  final String fullName;
  final String major;
  final String academicLevel;
  final String semester; // still required in UI
  final double gpa;

  StudentDashboard({
    required this.fullName,
    required this.major,
    required this.academicLevel,
    required this.semester,
    required this.gpa,
  });

  factory StudentDashboard.fromJson(Map<String, dynamic> json) {
    return StudentDashboard(
      fullName: json['fullname'],
      major: json['major'],
      academicLevel: json['academiclevel'].toString(),
      semester: json['semester'] ?? "N/A",
      gpa: (json['currentgpa'] ?? 0).toDouble(),
    );
  }
}
