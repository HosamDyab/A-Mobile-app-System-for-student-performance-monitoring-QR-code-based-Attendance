

import '../../data/models/Semester.dart';

abstract class GpaState {}

class GpaInitial extends GpaState {}

class GpaLoading extends GpaState {}

class GpaLoaded extends GpaState {
  final List<Semester> semesters;
  final double cumulativeGpa;

  GpaLoaded({required this.semesters, required this.cumulativeGpa});
}

class GpaError extends GpaState {
  final String message;
  GpaError(this.message);
}
