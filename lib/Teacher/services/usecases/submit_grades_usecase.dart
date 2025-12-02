import '../../models/grade_entity.dart';
import '../repositories/grade_repository.dart';

class SubmitGradesUseCase {
  final GradeRepository repository;
  
  SubmitGradesUseCase(this.repository);
  
  Future<GradeEntity> execute({
    required String studentId,
    required String examGrade,
    required String assignmentGrade,
  }) async {
    return await repository.submitGrade(
      studentId: studentId,
      examGrade: examGrade,
      assignmentGrade: assignmentGrade,
    );
  }
}