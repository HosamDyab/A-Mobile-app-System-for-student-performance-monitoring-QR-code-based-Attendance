import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qra/Teacher/services/usecases/generate_qr_code_usecase.dart';
import 'package:qra/Teacher/services/usecases/mark_attendance_usecase.dart';
import 'package:qra/Teacher/services/usecases/get_students_usecase.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final GenerateQRCodeUseCase generateQRCodeUseCase;
  final MarkAttendanceUseCase markAttendanceUseCase;
  final GetStudentsUseCase getStudentsUseCase;

  AttendanceBloc({
    required this.generateQRCodeUseCase,
    required this.markAttendanceUseCase,
    required this.getStudentsUseCase,
  }) : super(AttendanceInitial()) {
    on<GenerateQRCodeEvent>(_onGenerateQRCode);
    on<MarkAttendanceEvent>(_onMarkAttendance);
    on<GetLiveAttendanceEvent>(_onGetLiveAttendance);
    on<EndSessionEvent>(_onEndSession);
  }

  Future<void> _onGenerateQRCode(
    GenerateQRCodeEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());
    try {
      final sessionId = await generateQRCodeUseCase.execute();
      emit(AttendanceQRGenerated(sessionId: sessionId));
    } catch (e) {
      emit(AttendanceError(message: e.toString()));
    }
  }

  Future<void> _onMarkAttendance(
    MarkAttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());
    try {
      final attendance = await markAttendanceUseCase.execute(event.studentId);
      emit(AttendanceMarked(attendance: attendance));
    } catch (e) {
      emit(AttendanceError(message: e.toString()));
    }
  }

  Future<void> _onGetLiveAttendance(
  GetLiveAttendanceEvent event,
  Emitter<AttendanceState> emit,
) async {
  emit(AttendanceLoading());
  try {
    // This now returns students with studentCode, academicLevel, etc.
    final students = await getStudentsUseCase.execute();
    emit(AttendanceLive(students: students));
  } catch (e) {
    emit(AttendanceError(message: e.toString()));
  }
}

  Future<void> _onEndSession(
    EndSessionEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());
    try {
      // In a real app, you would call an API to end the session
      await Future.delayed(const Duration(seconds: 1));
      emit(AttendanceEnded());
    } catch (e) {
      emit(AttendanceError(message: e.toString()));
    }
  }
}

abstract class AttendanceEvent {}

class GenerateQRCodeEvent extends AttendanceEvent {}

class MarkAttendanceEvent extends AttendanceEvent {
  final String studentId;

  MarkAttendanceEvent(this.studentId);
}

class GetLiveAttendanceEvent extends AttendanceEvent {}

class EndSessionEvent extends AttendanceEvent {}
