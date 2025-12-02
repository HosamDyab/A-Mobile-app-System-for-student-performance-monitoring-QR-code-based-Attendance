// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentModel _$StudentModelFromJson(Map<String, dynamic> json) => StudentModel(
  studentId: json['studentId'] as String,
  userId: json['userId'] as String,
  studentCode: json['studentCode'] as String,
  major: json['major'] as String,
  currentGpa: (json['currentGpa'] as num).toDouble(),
  academicLevel: json['academicLevel'] as String,
  avatarUrl: json['avatarUrl'] as String?,
);

Map<String, dynamic> _$StudentModelToJson(StudentModel instance) =>
    <String, dynamic>{
      'studentId': instance.studentId,
      'userId': instance.userId,
      'studentCode': instance.studentCode,
      'major': instance.major,
      'currentGpa': instance.currentGpa,
      'academicLevel': instance.academicLevel,
      'avatarUrl': instance.avatarUrl,
    };
