
import 'Course.dart';

class Semester {
  int? id;
  String title;
  double gpa;
  int rank;
  int totalCredits;
  List<Course> courses;

  Semester({
    this.id,
    required this.title,
    this.gpa = 0.0,
    this.rank = 0,
    this.totalCredits = 0,
    List<Course>? courses,
  }) : courses = courses ?? [];

  factory Semester.fromMap(Map<String, dynamic> m, List<Course> courses) {
    return Semester(
      id: m['id'] as int?,
      title: m['title'] as String,
      gpa: (m['gpa'] as num?)?.toDouble() ?? 0.0,
      rank: (m['rank'] as int?) ?? 0,
      totalCredits: (m['totalCredits'] as int?) ?? 0,
      courses: courses,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'gpa': gpa,
    'rank': rank,
    'totalCredits': totalCredits,
  };
}
