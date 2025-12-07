import '../../../../helpers/supabase_remote_data_source.dart';
import '../../../domain/entities/CourseSearchgEntity.dart';

class StudentRepositorySearchImpl implements StudentRepositorySearch {
  final SupabaseRemoteDataSource remote;

  StudentRepositorySearchImpl(this.remote);

  @override
  Future<List<CourseEntitySearch>> searchStudentCourses(
      String studentId, String query) async {

    print(" REPO -> searchStudentCourses() studentId=$studentId query=$query");

    final response = await remote.searchCourses(studentId, query);

    final List<CourseEntitySearch> results = [];

    for (var item in response) {
      try {
        results.add(CourseEntitySearch.fromJson(item));
      } catch (e) {
        print(" Skipped invalid course record: $e");
      }
    }

    print(" RETURNING COURSES (${results.length})");

    return results;
  }

  @override
  Future<List<FacultyEntitySearch>> searchStudentFaculty(
      String studentId, String query) async {

    print("📡 REPO -> searchStudentFaculty() studentId=$studentId query=$query");

    final response = await remote.searchFaculty(studentId, query);

    final List<FacultyEntitySearch> results = [];

    for (var item in response) {
      try {
        results.add(FacultyEntitySearch.fromJson(item));
      } catch (e) {
        print(" Skipped invalid faculty record: $e");
      }
    }

    print(" RETURNING FACULTY (${results.length})");

    return results;
  }
}
