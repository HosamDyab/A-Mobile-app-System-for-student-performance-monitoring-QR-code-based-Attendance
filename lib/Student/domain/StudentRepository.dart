
import 'entities/Student.dart';

abstract class StudentRepository {
  Future<Student?> getStudentById(String studentId);
}
