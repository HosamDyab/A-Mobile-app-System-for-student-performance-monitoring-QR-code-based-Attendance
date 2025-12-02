part 'student_model.g.dart';

// Ensure field names EXACTLY match your Supabase table
// @JsonSerializable()
// class StudentModel {
//   final String id;
//   final String name;
//   final String grade;
//   final String level;
//   final bool is_present; // ← This must match your DB column name
//   final String? avatar_url; // ← This must match your DB column name
  
//   StudentModel({
//     required this.id,
//     required this.name,
//     required this.grade,
//     required this.level,
//     this.is_present = false,
//     this.avatar_url, DateTime? lastAttendance,
//   });
  
//   // Add this constructor for Supabase compatibility
//   factory StudentModel.fromJson(Map<String, dynamic> json) => _$StudentModelFromJson(json);
  
//   Map<String, dynamic> toJson() => _$StudentModelToJson(this);
// }


class StudentModel {
  final String studentId;
  final String userId;
  final String studentCode;
  final String major;
  final double currentGpa;
  final String academicLevel;
  final String? fullName; // ← Add this (nullable since it might be null)
  final String? avatarUrl;

  StudentModel({
    required this.studentId,
    required this.userId,
    required this.studentCode,
    required this.major,
    required this.currentGpa,
    required this.academicLevel,
    this.fullName, // ← Make it nullable
    this.avatarUrl,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      studentId: json['StudentId']?.toString() ?? json['student_id']?.toString() ?? '',
      userId: json['UserId']?.toString() ?? json['user_id']?.toString() ?? '',
      studentCode: json['StudentCode']?.toString() ?? json['student_code']?.toString() ?? '',
      major: json['Major']?.toString() ?? json['major']?.toString() ?? '',
      currentGpa: (json['CurrentGPA'] ?? json['current_gpa'] ?? 0.0).toDouble(),
      academicLevel: json['AcademicLevel']?.toString() ?? json['academic_level']?.toString() ?? '',
      fullName: json['User']?['FullName']?.toString() ?? json['full_name']?.toString(),
      avatarUrl: json['AvatarURL']?.toString() ?? json['avatar_url']?.toString(),
    );
  }
  
  Map<String, dynamic> toJson() => _$StudentModelToJson(this);
}