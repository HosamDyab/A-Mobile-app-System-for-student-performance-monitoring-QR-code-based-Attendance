import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qra/Teacher/services/repositories/live_attendance_repository.dart';
import 'package:qra/Teacher/viewmodels/live_attendance/live_attendance_state.dart';

/// Cubit for managing attendance state and fetching attendance data
class LiveAttendanceCubit extends Cubit<LiveAttendanceState> {
  final LiveAttendanceRepository repository;

  /// Creates an instance of [LiveAttendanceCubit] with the provided repository
  LiveAttendanceCubit(this.repository) : super(const LiveAttendanceInitial());

  /// Fetches attendance data for a given lecture instance ID
  ///
  /// [instanceId] - The unique identifier for the lecture instance
  ///
  /// Emits [LiveAttendanceLoading] while fetching, [LiveAttendanceLoaded] on success,
  /// or [LiveAttendanceError] if an error occurs
  Future<void> fetchAttend(String instanceId) async {
    // Validate input
    if (instanceId.isEmpty) {
      emit(const LiveAttendanceError('Instance ID cannot be empty'));
      return;
    }

    try {
      emit(const LiveAttendanceLoading());

      final data = await repository.getAttendanceForLecture(instanceId);

      // Check if data is null or empty
      emit(LiveAttendanceLoaded(data));
    } catch (e) {
      // Provide more descriptive error messages
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      emit(LiveAttendanceError(
        errorMessage.isNotEmpty
            ? errorMessage
            : 'Failed to fetch attendance data. Please try again.',
      ));
    }
  }

  /// Resets the cubit to its initial state
  void reset() {
    emit(const LiveAttendanceInitial());
  }
}
