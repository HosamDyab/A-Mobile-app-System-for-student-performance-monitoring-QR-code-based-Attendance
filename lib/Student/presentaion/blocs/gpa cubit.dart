
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../helpers/LocalDatabase GPA calculator.dart';
import '../../../helpers/gradeToPoints.dart';
import '../../data/models/Course.dart';
import '../../data/models/Semester.dart';
import 'gpa state.dart';


class GpaCubit extends Cubit<GpaState> {
  GpaCubit() : super(GpaInitial());

  Future<void> loadAll() async {
    emit(GpaLoading());
    try {
      final semesters = await LocalDb.loadAllSemestersWithCourses();

      for (final s in semesters) {
        s.totalCredits = s.courses.fold<int>(0, (a, b) => a + b.credits);
        s.gpa = calculateSemesterGpa(s.courses);
      }
      final cumulative = calculateCumulativeGpa(semesters);
      emit(GpaLoaded(semesters: semesters, cumulativeGpa: cumulative));
    } catch (e) {
      emit(GpaError(e.toString()));
    }
  }

  Future<void> addSemester(String title, {int rank = 0}) async {
    final sem = Semester(title: title, rank: rank);
    final id = await LocalDb.insertSemester(sem);
    sem.id = id;
    await loadAll();
  }

  Future<void> deleteSemester(int id) async {
    await LocalDb.deleteSemester(id);
    await loadAll();
  }

  Future<void> addCourse(int semesterId, String name, int credits, String grade) async {
    final c = Course(semesterId: semesterId, name: name, credits: credits, grade: grade);
    final id = await LocalDb.insertCourse(c);
    c.id = id;

    await _recalculateSemester(semesterId);
    await loadAll();
  }

  Future<void> updateCourse(Course course) async {
    await LocalDb.updateCourse(course);
    await _recalculateSemester(course.semesterId);
    await loadAll();
  }

  Future<void> deleteCourse(int courseId, int semesterId) async {
    await LocalDb.deleteCourse(courseId);
    await _recalculateSemester(semesterId);
    await loadAll();
  }

  Future<void> _recalculateSemester(int semesterId) async {
    final existingSem = await LocalDb.getSemesterById(semesterId);
    if (existingSem == null) return;

    final courses = existingSem.courses;
    final gpa = calculateSemesterGpa(courses);
    final totalCredits = courses.fold<int>(0, (a, b) => a + b.credits);

    final updatedSem = Semester(
        id: semesterId,
        title: existingSem.title,   // ✅ keep the title
        rank: existingSem.rank,     // ✅ keep the rank
        gpa: gpa,
        totalCredits: totalCredits,
        courses: courses
    );

    await LocalDb.updateSemester(updatedSem);
  }

}
//done