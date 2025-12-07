
import 'package:qra/Teacher/models/student_entity.dart';
// part of 'students_bloc.dart';


abstract class StudentsState {}

class StudentsInitial extends StudentsState {}

class StudentsLoading extends StudentsState {}

class StudentsLoaded extends StudentsState {
  final List<StudentEntity> students;
  
  StudentsLoaded({required this.students});
}

class StudentsError extends StudentsState {
  final String message;
  
  StudentsError({required this.message});
}