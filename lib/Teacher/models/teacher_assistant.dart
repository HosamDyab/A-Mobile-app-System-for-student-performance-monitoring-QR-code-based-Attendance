/// Model for Teacher Assistant
class TeacherAssistant {
  final String taId;      // tasnn
  final String fullName;  // fullname
  final String email;     // email
  final String? depCode;  // depcode

  TeacherAssistant({
    required this.taId,
    required this.fullName,
    required this.email,
    this.depCode,
  });

  factory TeacherAssistant.fromJson(Map<String, dynamic> json) {
    return TeacherAssistant(
      taId: json['tasnn']?.toString() ?? '',
      fullName: json['fullname']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      depCode: json['depcode']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tasnn': taId,
      'fullname': fullName,
      'email': email,
      'depcode': depCode,
    };
  }
}