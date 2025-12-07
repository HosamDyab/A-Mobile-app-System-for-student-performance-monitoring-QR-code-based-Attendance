part 'attendance_model.g.dart';

class AttendanceModel {
  final String id;
  final String studentId;
  final String sessionId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String status; // present, absent, late
  
  AttendanceModel({
    required this.id,
    required this.studentId,
    required this.sessionId,
    required this.checkInTime,
    this.checkOutTime,
    this.status = 'present',
  });
  
  factory AttendanceModel.fromJson(Map<String, dynamic> json) => _$AttendanceModelFromJson(json);
  Map<String, dynamic> toJson() => _$AttendanceModelToJson(this);
}