import '../../models/grade_entity.dart';
import '../datasources/supabase/grade_datasource.dart';

class GradeRepository {
  final GradeDataSource _dataSource;
  
  GradeRepository(this._dataSource);
  
  Future<GradeEntity> submitGrade({
    required String studentId,
    required String examGrade,
    required String assignmentGrade,
  }) async {
    final model = await _dataSource.submitGrade(
      studentId: studentId,
      examGrade: examGrade,
      assignmentGrade: assignmentGrade,
    );
    return GradeEntity.fromModel(model);
  }
  
  Future<List<GradeEntity>> getStudentGrades(String studentId) async {
    final models = await _dataSource.getStudentGrades(studentId);
    return models.map((model) => GradeEntity.fromModel(model)).toList();
  }
}