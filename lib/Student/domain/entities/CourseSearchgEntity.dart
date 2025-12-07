class CourseEntitySearch {
  final String title;
  final int academicYear;
  final String semester;
  final double? totalGrade;
  final String? letterGrade;

  CourseEntitySearch({
    required this.title,
    required this.academicYear,
    required this.semester,
    this.totalGrade,
    this.letterGrade,
  });

  factory CourseEntitySearch.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return CourseEntitySearch(
        title: "Unknown Course",
        academicYear: 0,
        semester: "Unknown Semester",
      );
    }

    final sco = json["SectionCourseOffering"] as Map<String, dynamic>? ?? {};
    final course = sco["Course"] as Map<String, dynamic>? ?? {};
    final grades = sco["SectionGrade"] as List<dynamic>? ?? [];

    double? total;
    String? letter;

    if (grades.isNotEmpty) {
      final latest = grades.last as Map<String, dynamic>;
      total = latest["Total"] != null ? (latest["Total"] as num).toDouble() : null;
      letter = latest["LetterGrade"]?.toString();
    }

    return CourseEntitySearch(
      title: course["Title"]?.toString() ?? "Unknown Course",
      academicYear: sco["AcademicYear"] is int ? sco["AcademicYear"] : 0,
      semester: sco["Semester"]?.toString() ?? "Unknown Semester",
      totalGrade: total,
      letterGrade: letter,
    );
  }
}

class FacultyEntitySearch {
  final String fullName;
  final String email;

  FacultyEntitySearch({
    required this.fullName,
    required this.email,
  });

  factory FacultyEntitySearch.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return FacultyEntitySearch(
        fullName: "Unknown Faculty",
        email: "no-email@unknown.edu",
      );
    }

    final sco = json["SectionCourseOffering"] as Map<String, dynamic>? ?? {};
    final lecture = sco["LectureOffering"] as Map<String, dynamic>? ?? {};
    final faculty = lecture["Faculty"] as Map<String, dynamic>? ?? {};
    final user = faculty["User"] as Map<String, dynamic>? ?? {};

    return FacultyEntitySearch(
      fullName: user["FullName"]?.toString() ?? "Unknown Faculty",
      email: user["Email"]?.toString() ?? "no-email@unknown.edu",
    );
  }
}


abstract class StudentRepositorySearch {
  Future<List<CourseEntitySearch>> searchStudentCourses(String studentId, String query);
  Future<List<FacultyEntitySearch>> searchStudentFaculty(String studentId, String query);
}
