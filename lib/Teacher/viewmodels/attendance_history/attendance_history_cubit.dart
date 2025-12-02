import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/datasources/supabase/attendance_history_datasource.dart';
import 'attendance_history_state.dart';

class AttendanceHistoryCubit extends Cubit<AttendanceHistoryState> {
  final AttendanceHistoryDataSource _dataSource;

  AttendanceHistoryCubit(this._dataSource) : super(AttendanceHistoryInitial());

  Future<void> loadAttendanceHistory({
    String? courseCode,
    int? weekNumber,
    DateTime? startDate,
    DateTime? endDate,
    String? facultyId,
  }) async {
    emit(AttendanceHistoryLoading());
    try {
      final records = await _dataSource.getAllAttendanceRecords(
        courseCode: courseCode,
        weekNumber: weekNumber,
        startDate: startDate,
        endDate: endDate,
        facultyId: facultyId,
      );
      emit(AttendanceHistoryLoaded(records));
    } catch (e) {
      emit(AttendanceHistoryError(e.toString()));
    }
  }

  Future<void> searchAttendance(String query) async {
    if (query.isEmpty) {
      loadAttendanceHistory();
      return;
    }
    
    emit(AttendanceHistoryLoading());
    try {
      final records = await _dataSource.searchAttendance(query);
      emit(AttendanceHistoryLoaded(records));
    } catch (e) {
      emit(AttendanceHistoryError(e.toString()));
    }
  }
}

