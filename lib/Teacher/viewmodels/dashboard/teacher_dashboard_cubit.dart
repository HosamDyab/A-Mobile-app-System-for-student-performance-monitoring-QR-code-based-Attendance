import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/repositories/faculty_repository.dart';
import 'teacher_dashboard_state.dart';

class TeacherDashboardCubit extends Cubit<TeacherDashboardState> {
  final FacultyRepository _repository;

  TeacherDashboardCubit(this._repository) : super(TeacherDashboardInitial());

  Future<void> loadTodayCourses(String facultyId, String role) async {
    emit(TeacherDashboardLoading());
    try {
      final courses = await _repository.getTodayCourses(facultyId, role);
      emit(TeacherDashboardLoaded(courses));
    } catch (e) {
      emit(TeacherDashboardError(e.toString()));
    }
  }
}
