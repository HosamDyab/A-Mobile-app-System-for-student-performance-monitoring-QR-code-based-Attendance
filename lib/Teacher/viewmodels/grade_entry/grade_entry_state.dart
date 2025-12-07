abstract class GradeEntryState {}

class GradeEntryInitial extends GradeEntryState {}

class GradeEntryLoading extends GradeEntryState {}

class GradeEntrySuccess extends GradeEntryState {
  final String? message;

  GradeEntrySuccess({this.message});
}

class GradeEntryError extends GradeEntryState {
  final String message;

  GradeEntryError({required this.message});
}
