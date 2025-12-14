
import '../../models/lecture_attendance.dart';

abstract class LiveAttendanceState {
  const LiveAttendanceState();
}

class LiveAttendanceInitial extends LiveAttendanceState {
  const LiveAttendanceInitial();
}

class LiveAttendanceLoading extends LiveAttendanceState {
  const LiveAttendanceLoading();
}

class LiveAttendanceLoaded extends LiveAttendanceState {
  final List<LectureAttendance> attendanceList;

  const LiveAttendanceLoaded(this.attendanceList);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LiveAttendanceLoaded &&
        other.attendanceList.length == attendanceList.length;
  }

  @override
  int get hashCode => attendanceList.hashCode;
}

class LiveAttendanceError extends LiveAttendanceState {
  final String message;

  const LiveAttendanceError(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LiveAttendanceError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}