// student_model.dart

class StudentModel {
  final String studentId;
  final String fullName;
  final String email;
  final String? major;
  final int? academicLevel;
  final double? currentGpa;
  final int totalCreditHoursEarned;
  final String? entryYear;

  StudentModel({
    required this.studentId,
    required this.fullName,
    required this.email,
    this.major,
    this.academicLevel,
    this.currentGpa,
    this.totalCreditHoursEarned = 0,
    this.entryYear,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      studentId: json['studentid']?.toString() ?? '',
      fullName: json['fullname']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      major: json['major']?.toString(),
      academicLevel: json['academiclevel'] as int?,
      currentGpa: (json['currentgpa'] as num?)?.toDouble(),
      totalCreditHoursEarned: json['totalcredithoursearned'] as int? ?? 0,
      entryYear: json['entryyear']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentid': studentId,
      'fullname': fullName,
      'email': email,
      'major': major,
      'academiclevel': academicLevel,
      'currentgpa': currentGpa,
      'totalcredithoursearned': totalCreditHoursEarned,
      'entryyear': entryYear,
    };
  }

  // Helper to get level as string (L1, L2, L3, L4)
  String get academicLevelString {
    if (academicLevel == null) return 'Unknown';
    return 'L$academicLevel';
  }
}