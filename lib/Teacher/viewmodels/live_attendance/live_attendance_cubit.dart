import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/repositories/live_attendance_repository.dart';
import 'live_attendance_state.dart';

class LiveAttendanceCubit extends Cubit<LiveAttendanceState> {
  final LiveAttendanceRepository repository;
  Timer? _pollingTimer;

  LiveAttendanceCubit(this.repository) : super(const LiveAttendanceInitial());

  /// Start polling for attendance updates
  void startPolling(String instanceId, {int intervalSeconds = 3}) {
    if (instanceId.isEmpty) {
      emit(const LiveAttendanceError('Instance ID cannot be empty'));
      return;
    }

    print('🔄 Starting polling for instance: $instanceId (every ${intervalSeconds}s)');

    // Initial fetch
    fetchAttend(instanceId);

    // Start periodic updates
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
          (_) {
        print('⏱️ Polling tick - fetching attendance...');
        fetchAttend(instanceId, silent: true);
      },
    );
  }

  /// Stop polling when session ends
  void stopPolling() {
    print('🛑 Stopping attendance polling');
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> fetchAttend(String instanceId, {bool silent = false}) async {
    if (instanceId.isEmpty) {
      emit(const LiveAttendanceError('Instance ID cannot be empty'));
      return;
    }

    try {
      // Only show loading state on initial fetch, not during polling
      if (!silent) {
        emit(const LiveAttendanceLoading());
      }

      final data = await repository.getAttendanceForLecture(instanceId);

      if (!silent) {
        print('✅ Initial fetch complete: ${data.length} records');
      } else {
        print('🔄 Poll update: ${data.length} records');
      }

      emit(LiveAttendanceLoaded(data));
    } catch (e) {
      print('❌ Error fetching attendance: $e');
      final errorMessage = e.toString().replaceFirst('Exception: ', '');

      // Only emit error on initial fetch, not during silent polling
      if (!silent) {
        emit(LiveAttendanceError(
          errorMessage.isNotEmpty
              ? errorMessage
              : 'Failed to fetch attendance data. Please try again.',
        ));
      }
    }
  }

  void reset() {
    stopPolling();
    emit(const LiveAttendanceInitial());
  }

  @override
  Future<void> close() {
    stopPolling();
    return super.close();
  }
}