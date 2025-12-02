import '../../../data/models/StudentDashboard.dart';

abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final StudentDashboard profile;
  final List<dynamic> courses;

  DashboardLoaded(this.profile, this.courses);
}

class DashboardError extends DashboardState {
  final String msg;
  DashboardError(this.msg);
}
