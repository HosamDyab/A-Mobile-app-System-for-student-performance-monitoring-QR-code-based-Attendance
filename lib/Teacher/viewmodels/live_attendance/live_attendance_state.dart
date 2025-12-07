 
import 'package:qra/Teacher/models/lecture_attendance.dart';

/// Base class for attendance states
abstract class LiveAttendanceState {
  const LiveAttendanceState();
}

/// Initial state when the cubit is first created
class LiveAttendanceInitial extends LiveAttendanceState {
  const LiveAttendanceInitial();
}

/// State indicating that attendance data is being fetched
class LiveAttendanceLoading extends LiveAttendanceState {
  const LiveAttendanceLoading();
}

/// State containing the successfully loaded attendance data
class LiveAttendanceLoaded extends LiveAttendanceState {
  final List<LectureAttendance> attendanceList;

  LiveAttendanceLoaded(this.attendanceList);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LiveAttendanceLoaded && 
           other.attendanceList.length == attendanceList.length;
  }

  @override
  int get hashCode => attendanceList.hashCode;
}

/// State indicating an error occurred while fetching attendance
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
