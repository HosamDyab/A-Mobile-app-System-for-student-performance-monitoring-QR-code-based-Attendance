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
      final List<StudentEntity> students = await getStudentsUseCase.execute(
        facultyId: event.facultyId,
        role: event.role,
      );
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
    final List<StudentEntity> students = await getStudentsUseCase.execute(
      facultyId: event.facultyId,
      role: event.role,
    );
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
        facultyId: event.facultyId,
        role: event.role,
      );
      emit(StudentsLoaded(students: students));
    } catch (e) {
      emit(StudentsError(message: e.toString()));
    }
  }
}

abstract class StudentsEvent {}

class LoadStudentsEvent extends StudentsEvent {
  final String? facultyId;
  final String? role;
  
  LoadStudentsEvent({this.facultyId, this.role});
}

class SearchStudentsEvent extends StudentsEvent {
  final String query;
  final String? facultyId;
  final String? role;
  
  SearchStudentsEvent(this.query, {this.facultyId, this.role});
}

class FilterStudentsEvent extends StudentsEvent {
  final String? level;
  final String? status;
  final String? facultyId;
  final String? role;
  
  FilterStudentsEvent({this.level, this.status, this.facultyId, this.role});
}
