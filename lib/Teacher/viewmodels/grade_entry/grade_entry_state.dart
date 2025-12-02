import 'package:qra/Teacher/models/grade_entity.dart';
// part of 'grade_entry_cubit.dart';



abstract class GradeEntryState {}

class GradeEntryInitial extends GradeEntryState {}

class GradeEntryLoading extends GradeEntryState {}

class GradeEntrySuccess extends GradeEntryState {
  final GradeEntity grade;
  
  GradeEntrySuccess({required this.grade});
}

class GradeEntryError extends GradeEntryState {
  final String message;
  
  GradeEntryError({required this.message});
}