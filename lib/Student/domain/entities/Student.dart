class Student {
  final String id;
  final String fullName;
  final String major;
  final String academicLevel;
  final double gpa;
  final String email;
  final String? phone;   // always null unless you add profile table

  Student({
    required this.id,
    required this.fullName,
    required this.major,
    required this.academicLevel,
    required this.gpa,
    required this.email,
    this.phone,
  });
}
