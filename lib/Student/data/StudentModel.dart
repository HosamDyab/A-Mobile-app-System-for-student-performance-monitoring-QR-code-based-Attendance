
import '../domain/entities/Student.dart';

class StudentModel extends Student {
  StudentModel({
    required super.id,
    required super.fullName,
    required super.studentCode,
    required super.major,
    required super.academicLevel,
    required super.currentSemester,
    required super.gpa,
    required super.email,
    super.phone,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['StudentId'],
      fullName: json['User']['FullName'],
      studentCode: json['StudentCode'],
      major: json['Major'],
      academicLevel: json['AcademicLevel'],
      currentSemester: json['CurrentSemester'],
      gpa: (json['CumulativeGPA'] ?? 0).toDouble(),
      email: json['User']['Email'],
      phone: json['User']['Phone'],
    );
  }

  Map<String, dynamic> toJson() => {
    'StudentId': id,
    'FullName': fullName,
    'StudentCode': studentCode,
    'Major': major,
    'AcademicLevel': academicLevel,
    'CurrentSemester': currentSemester,
    'CumulativeGPA': gpa,
    'Email': email,
    'Phone': phone,
  };
}
