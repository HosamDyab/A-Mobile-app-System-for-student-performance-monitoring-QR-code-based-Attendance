import '../../models/course_offering.dart';

abstract class TeacherDashboardState {}

class TeacherDashboardInitial extends TeacherDashboardState {}

class TeacherDashboardLoading extends TeacherDashboardState {}

class TeacherDashboardLoaded extends TeacherDashboardState {
  final List<CourseOffering> courses;
  TeacherDashboardLoaded(this.courses);
}

class TeacherDashboardError extends TeacherDashboardState {
  final String message;
  TeacherDashboardError(this.message);
}

