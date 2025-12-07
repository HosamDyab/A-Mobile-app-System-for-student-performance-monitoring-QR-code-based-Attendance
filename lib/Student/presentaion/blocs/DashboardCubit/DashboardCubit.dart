import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../helpers/supabase_remote_data_source.dart';
import 'DashboardState.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final SupabaseRemoteDataSource remote;

  DashboardCubit(this.remote) : super(DashboardInitial());

  Future<void> loadDashboard(String studentId) async {
    emit(DashboardLoading());

    try {
      final profile = await remote.getStudentDashboard(studentId);
      final courses = await remote.getCurrentCourses(studentId);

      emit(DashboardLoaded(profile!, courses));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
