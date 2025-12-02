import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/datasources/supabase/teacher_assistant_datasource.dart';
import 'teacher_assistant_state.dart';

class TeacherAssistantCubit extends Cubit<TeacherAssistantState> {
  final TeacherAssistantDataSource _dataSource;

  TeacherAssistantCubit(this._dataSource) : super(TeacherAssistantInitial());

  Future<void> loadAllTeacherAssistants() async {
    emit(TeacherAssistantLoading());
    try {
      final tas = await _dataSource.getAllTeacherAssistants();
      emit(TeacherAssistantLoaded(tas));
    } catch (e) {
      emit(TeacherAssistantError(e.toString()));
    }
  }

  Future<void> loadTeacherAssistantsByFaculty(String facultyId) async {
    emit(TeacherAssistantLoading());
    try {
      final tas = await _dataSource.getTeacherAssistantsByFaculty(facultyId);
      emit(TeacherAssistantLoaded(tas));
    } catch (e) {
      emit(TeacherAssistantError(e.toString()));
    }
  }

  Future<void> searchTeacherAssistants(String query) async {
    if (query.isEmpty) {
      loadAllTeacherAssistants();
      return;
    }
    
    emit(TeacherAssistantLoading());
    try {
      final tas = await _dataSource.searchTeacherAssistants(query);
      emit(TeacherAssistantLoaded(tas));
    } catch (e) {
      emit(TeacherAssistantError(e.toString()));
    }
  }
}

