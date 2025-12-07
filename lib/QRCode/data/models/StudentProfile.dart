class StudentProfile {
  final String fullName;
  final String major;
  final String academicLevel;
  final String semester;
  final double gpa;

  StudentProfile({
    required this.fullName,
    required this.major,
    required this.academicLevel,
    required this.semester,
    required this.gpa,
  });

  factory StudentProfile.fromMap(Map<String, dynamic> map) {
    return StudentProfile(
      fullName: map['FullName'] ?? 'Unknown',
      major: map['Major'] ?? 'Unknown',
      academicLevel: map['AcademicLevel'] ?? 'Unknown',
      semester: map['Semester'] ?? 'Unknown',
      gpa: (map['GPA'] is num) ? map['GPA'].toDouble() : 0.0,
    );
  }
}
