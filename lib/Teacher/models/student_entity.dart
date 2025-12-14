// student_entity.dart

class StudentEntity {
  final String studentId;
  final String fullName;
  final String email;
  final String? major;
  final int? academicLevel;
  final double? currentGpa;
  final int totalCreditHoursEarned;
  final String? entryYear;

  StudentEntity({
    required this.studentId,
    required this.fullName,
    required this.email,
    this.major,
    this.academicLevel,
    this.currentGpa,
    this.totalCreditHoursEarned = 0,
    this.entryYear,
  });

  factory StudentEntity.fromModel(dynamic model) {
    return StudentEntity(
      studentId: model.studentId,
      fullName: model.fullName,
      email: model.email,
      major: model.major,
      academicLevel: model.academicLevel,
      currentGpa: model.currentGpa,
      totalCreditHoursEarned: model.totalCreditHoursEarned,
      entryYear: model.entryYear,
    );
  }

  StudentEntity copyWith({
    String? studentId,
    String? fullName,
    String? email,
    String? major,
    int? academicLevel,
    double? currentGpa,
    int? totalCreditHoursEarned,
    String? entryYear,
  }) {
    return StudentEntity(
      studentId: studentId ?? this.studentId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      major: major ?? this.major,
      academicLevel: academicLevel ?? this.academicLevel,
      currentGpa: currentGpa ?? this.currentGpa,
      totalCreditHoursEarned: totalCreditHoursEarned ?? this.totalCreditHoursEarned,
      entryYear: entryYear ?? this.entryYear,
    );
  }

  // Helper to get level as string (L1, L2, L3, L4)
  String get academicLevelString {
    if (academicLevel == null) return 'Unknown';
    return 'L$academicLevel';
  }
}