import '../domain/entities/Student.dart';

class StudentModel extends Student {
  StudentModel({
    required super.id,
    required super.fullName,
    required super.major,
    required super.academicLevel,
    required super.gpa,
    required super.email,
    super.phone,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['studentid'],
      fullName: json['fullname'],
      major: json['major'] ?? '',
      academicLevel: json['academiclevel'].toString(),
      gpa: (json['currentgpa'] ?? 0).toDouble(),
      email: json['email'],
      phone: null, // No phone in new schema
    );
  }

  Map<String, dynamic> toJson() => {
    'studentid': id,
    'fullname': fullName,
    'major': major,
    'academiclevel': academicLevel,
    'currentgpa': gpa,
    'email': email,
    'phone': phone,
  };
}
