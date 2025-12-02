import 'package:qra/Teacher/models/student_entity.dart';
// part of 'attendance_bloc.dart';



abstract class AttendanceState {}

class AttendanceInitial extends AttendanceState {}

class AttendanceLoading extends AttendanceState {}

class AttendanceQRGenerated extends AttendanceState {
  final String sessionId;
  
  AttendanceQRGenerated({required this.sessionId});
}

class AttendanceMarked extends AttendanceState {
  final dynamic attendance;
  
  AttendanceMarked({required this.attendance});
}

class AttendanceLive extends AttendanceState {
  final List<StudentEntity> students;
  
  AttendanceLive({required this.students});
}

class AttendanceEnded extends AttendanceState {}

class AttendanceError extends AttendanceState {
  final String message;
  
  AttendanceError({required this.message});
}