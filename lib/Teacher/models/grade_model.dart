part 'grade_model.g.dart';

class GradeModel {
  final String id;
  final String studentId;
  final String examGrade;
  final String assignmentGrade;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  GradeModel({
    required this.id,
    required this.studentId,
    required this.examGrade,
    required this.assignmentGrade,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory GradeModel.fromJson(Map<String, dynamic> json) => _$GradeModelFromJson(json);
  Map<String, dynamic> toJson() => _$GradeModelToJson(this);
}