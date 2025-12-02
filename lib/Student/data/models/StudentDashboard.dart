class StudentDashboard {
  final String fullName;
  final String major;
  final String academicLevel;
  final String semester;
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
      fullName: json['FullName'],
      major: json['Major'],
      academicLevel: json['AcademicLevel'],
      semester: json['CurrentSemester'],
      gpa: (json['CumulativeGPA'] ?? 0).toDouble(),
    );
  }
}
