// get_students_usecase.dart

import '../../models/student_entity.dart';
import '../repositories/student_repository.dart';

class GetStudentsUseCase {
  final StudentRepository repository;

  GetStudentsUseCase(this.repository);

  Future<List<StudentEntity>> execute({
    String? level,
    String? status,
    String? facultyId,
    String? role,
  }) async {
    return await repository.getAllStudents(
      level: level,
      status: status,
      facultyId: facultyId,
      role: role,
    );
  }
}