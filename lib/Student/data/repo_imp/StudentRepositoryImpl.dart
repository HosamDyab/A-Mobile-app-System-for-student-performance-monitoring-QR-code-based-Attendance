

import '../../../helpers/supabase_remote_data_source.dart';
import '../../domain/StudentRepository.dart';
import '../../domain/entities/Student.dart';

class StudentRepositoryImpl implements StudentRepository {
  final SupabaseRemoteDataSource supabaseRemoteDataSource;

  StudentRepositoryImpl(this.supabaseRemoteDataSource);

  @override
  Future<Student?> getStudentById(String studentId) async {
    return await supabaseRemoteDataSource.getStudentById(studentId);
  }


}
