// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grade_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GradeModel _$GradeModelFromJson(Map<String, dynamic> json) => GradeModel(
  id: json['id'] as String,
  studentId: json['studentId'] as String,
  examGrade: json['examGrade'] as String,
  assignmentGrade: json['assignmentGrade'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$GradeModelToJson(GradeModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'studentId': instance.studentId,
      'examGrade': instance.examGrade,
      'assignmentGrade': instance.assignmentGrade,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
