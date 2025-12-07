/// Model for Teacher Assistant
class TeacherAssistant {
  final String taId;
  final String userId;
  final String facultyId;
  final String? fullName;
  final String? email;

  TeacherAssistant({
    required this.taId,
    required this.userId,
    required this.facultyId,
    this.fullName,
    this.email,
  });

  factory TeacherAssistant.fromJson(Map<String, dynamic> json) {
    return TeacherAssistant(
      taId: json['TAId']?.toString() ?? '',
      userId: json['UserId']?.toString() ?? '',
      facultyId: json['FacultyId']?.toString() ?? '',
      fullName: json['User']?['FullName'] as String?,
      email: json['User']?['Email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'TAId': taId,
      'UserId': userId,
      'FacultyId': facultyId,
      'FullName': fullName,
      'Email': email,
    };
  }
}

