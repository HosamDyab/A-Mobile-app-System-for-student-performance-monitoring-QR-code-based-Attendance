import '../../models/student_entity.dart';
import '../datasources/supabase/student_datasource.dart';

class StudentRepository {
  final StudentDataSource _dataSource;
  
  StudentRepository(this._dataSource);
  
  Future<List<StudentEntity>> getAllStudents({
    String? level, 
    String? status,
    String? facultyId,
    String? role,
  }) async {
    final models = await _dataSource.getAllStudents(
      level: level, 
      status: status,
      facultyId: facultyId,
      role: role,
    );
    return models.map((model) => StudentEntity.fromModel(model)).toList();
  }
  
  Future<StudentEntity> getStudentById(String id) async {
    final model = await _dataSource.getStudentById(id);
    return StudentEntity.fromModel(model);
  }
  
  Future<List<StudentEntity>> searchStudents(String query) async {
    final models = await _dataSource.searchStudents(query);
    return models.map((model) => StudentEntity.fromModel(model)).toList();
  }
}
