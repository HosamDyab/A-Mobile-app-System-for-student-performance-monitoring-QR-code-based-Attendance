import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qra/Teacher/services/usecases/get_students_usecase.dart';
import 'package:qra/Teacher/models/student_entity.dart';
import 'students_state.dart';

class StudentsBloc extends Bloc<StudentsEvent, StudentsState> {
  final GetStudentsUseCase getStudentsUseCase;
  
  StudentsBloc(this.getStudentsUseCase) : super(StudentsInitial()) {
    on<LoadStudentsEvent>(_onLoadStudents);
    on<SearchStudentsEvent>(_onSearchStudents);
    on<FilterStudentsEvent>(_onFilterStudents);
  }
  
  Future<void> _onLoadStudents(
    LoadStudentsEvent event,
    Emitter<StudentsState> emit,
  ) async {
    emit(StudentsLoading());
    try {
      final List<StudentEntity> students = await getStudentsUseCase.execute();
      emit(StudentsLoaded(students: students));
    } catch (e) {
      emit(StudentsError(message: e.toString()));
    }
  }
  
  Future<void> _onSearchStudents(
  SearchStudentsEvent event,
  Emitter<StudentsState> emit,
) async {
  emit(StudentsLoading());
  try {
    final List<StudentEntity> students = await getStudentsUseCase.execute();
    final filtered = students.where((student) => 
      student.studentId.toLowerCase().contains(event.query.toLowerCase()) ||
      student.studentCode.toLowerCase().contains(event.query.toLowerCase()) ||
      (student.fullName?.toLowerCase().contains(event.query.toLowerCase()) ?? false)).toList();
    emit(StudentsLoaded(students: filtered));
  } catch (e) {
    emit(StudentsError(message: e.toString()));
  }
}
  
  Future<void> _onFilterStudents(
    FilterStudentsEvent event,
    Emitter<StudentsState> emit,
  ) async {
    emit(StudentsLoading());
    try {
      final List<StudentEntity> students = await getStudentsUseCase.execute(
        level: event.level,
        status: event.status,
      );
      emit(StudentsLoaded(students: students));
    } catch (e) {
      emit(StudentsError(message: e.toString()));
    }
  }
}

abstract class StudentsEvent {}

class LoadStudentsEvent extends StudentsEvent {}

class SearchStudentsEvent extends StudentsEvent {
  final String query;
  
  SearchStudentsEvent(this.query);
}

class FilterStudentsEvent extends StudentsEvent {
  final String? level;
  final String? status;
  
  FilterStudentsEvent({this.level, this.status});
}
