// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:equatable/equatable.dart';
// import '../../../domain/Attendance.dart';
// import '../../../domain/repo/attendance_repository.dart';
//
// part 'attendance_state.dart';
//
// class AttendanceCubit extends Cubit<AttendanceState> {
//   final AttendanceRepository repository;
//
//   AttendanceCubit(this.repository) : super(AttendanceInitial());
//
//
//   Future<void> fetchStudentAttendance(String studentId) async {
//     emit(AttendanceLoading());
//     try {
//       final data = await repository.getAttendanceForStudent(studentId);
//
//       if (data.isEmpty) {
//         emit(AttendanceLoaded([]));
//       } else {
//         emit(AttendanceLoaded(data));
//       }
//     } catch (e) {
//       emit(AttendanceError('Failed to load attendance: $e'));
//     }
//   }
//
//
//   Future<void> markAttendance(String studentId, String instanceId) async {
//     emit(AttendanceLoading());
//     try {
//       await repository.markAttendance(studentId, instanceId);
//       await fetchStudentAttendance(studentId);
//     } catch (e) {
//       emit(AttendanceError('Failed to mark attendance: $e'));
//     }
//   }
// }
