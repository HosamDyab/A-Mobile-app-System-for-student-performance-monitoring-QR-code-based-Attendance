import '../../models/attendance_record.dart';

abstract class AttendanceHistoryState {}

class AttendanceHistoryInitial extends AttendanceHistoryState {}

class AttendanceHistoryLoading extends AttendanceHistoryState {}

class AttendanceHistoryLoaded extends AttendanceHistoryState {
  final List<AttendanceRecord> records;

  AttendanceHistoryLoaded(this.records);
}

class AttendanceHistoryError extends AttendanceHistoryState {
  final String message;

  AttendanceHistoryError(this.message);
}

