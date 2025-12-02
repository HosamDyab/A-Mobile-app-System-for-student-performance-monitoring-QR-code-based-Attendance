

class Student {
  final String id;
  final String fullName;
  final String studentCode;
  final String major;
  final String academicLevel;
  final String currentSemester;
  final double gpa;
  final String email;
  final String? phone;

  Student({
    required this.id,
    required this.fullName,
    required this.studentCode,
    required this.major,
    required this.academicLevel,
    required this.currentSemester,
    required this.gpa,
    required this.email,
    this.phone,
  });
}
