import '../../models/teacher_assistant.dart';

abstract class TeacherAssistantState {}

class TeacherAssistantInitial extends TeacherAssistantState {}

class TeacherAssistantLoading extends TeacherAssistantState {}

class TeacherAssistantLoaded extends TeacherAssistantState {
  final List<TeacherAssistant> teacherAssistants;

  TeacherAssistantLoaded(this.teacherAssistants);
}

class TeacherAssistantError extends TeacherAssistantState {
  final String message;

  TeacherAssistantError(this.message);
}

