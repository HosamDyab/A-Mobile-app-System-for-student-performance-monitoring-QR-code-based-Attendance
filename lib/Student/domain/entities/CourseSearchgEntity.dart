// Updated models to match your actual Supabase database schema

class CourseEntitySearch {
  final String courseCode;
  final String courseName;
  final int academicYear;
  final String semester;
  final int creditHours;
  final bool hasLab;
  final double? totalGrade;
  final String? letterGrade;
  final String? lectureOfferingId;

  CourseEntitySearch({
    required this.courseCode,
    required this.courseName,
    required this.academicYear,
    required this.semester,
    required this.creditHours,
    required this.hasLab,
    this.totalGrade,
    this.letterGrade,
    this.lectureOfferingId,
  });

  factory CourseEntitySearch.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return CourseEntitySearch(
        courseCode: "N/A",
        courseName: "Unknown Course",
        academicYear: 0,
        semester: "Unknown Semester",
        creditHours: 0,
        hasLab: false,
      );
    }

    // Extract from the nested structure returned by your query
    final lectureOfferingId = json['lectureofferingid']?.toString();
    final lectureCourseOffering = json['lecturecourseoffering'] as Map<String, dynamic>? ?? {};
    final course = lectureCourseOffering['course'] as Map<String, dynamic>? ?? {};

    // Try to get evaluation data if it exists
    final evaluation = json['evaluationsheet'] as Map<String, dynamic>?;

    // Parse academic year
    int year = 0;
    final yearStr = lectureCourseOffering['academicyear']?.toString() ?? '0';
    try {
      year = int.parse(yearStr);
    } catch (e) {
      year = 0;
    }

    // Parse has lab
    final hasLabStr = course['haslab']?.toString().toUpperCase();
    final hasLab = hasLabStr == 'YES';

    return CourseEntitySearch(
      courseCode: course['coursecode']?.toString() ?? "N/A",
      courseName: course['coursename']?.toString() ?? "Unknown Course",
      academicYear: year,
      semester: lectureCourseOffering['semester']?.toString() ?? "Unknown Semester",
      creditHours: course['credithours'] as int? ?? 0,
      hasLab: hasLab,
      totalGrade: evaluation?['totalgrade'] != null
          ? (evaluation!['totalgrade'] as num).toDouble()
          : null,
      letterGrade: evaluation?['lettergrade']?.toString(),
      lectureOfferingId: lectureOfferingId,
    );
  }

  // Helper getter for display
  String get displayName => '$courseCode - $courseName';

  // Helper getter for semester display
  String get semesterDisplay => '$semester $academicYear';
}
class FacultyEntitySearch {
  final String facultySnn;
  final String fullName;
  final String email;
  final String? depCode;
  final String? courseOfferingId;
  final int? lectureSlot;

  FacultyEntitySearch({
    required this.facultySnn,
    required this.fullName,
    required this.email,
    this.depCode,
    this.courseOfferingId,
    this.lectureSlot,
  });

  factory FacultyEntitySearch.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return FacultyEntitySearch(
        facultySnn: "N/A",
        fullName: "Unknown Faculty",
        email: "no-email@unknown.edu",
      );
    }

    // Extract from the nested structure
    final faculty = json['faculty'] as Map<String, dynamic>? ?? {};

    return FacultyEntitySearch(
      facultySnn: faculty['facultysnn']?.toString() ?? "N/A",
      fullName: faculty['fullname']?.toString() ?? "Unknown Faculty",
      email: faculty['email']?.toString() ?? "no-email@unknown.edu",
      depCode: faculty['depcode']?.toString(),
      courseOfferingId: json['courseofferingid']?.toString(),
      lectureSlot: json['lectureslot'] as int?,
    );
  }
  String get displayInfo => '$fullName ($email)';
}


// Optional: Model for when you need course + faculty together
class CourseWithFaculty {
  final CourseEntitySearch course;
  final List<FacultyEntitySearch> faculty;

  CourseWithFaculty({
    required this.course,
    required this.faculty,
  });

  factory CourseWithFaculty.fromCourseJson(
      Map<String, dynamic> courseJson,
      List<Map<String, dynamic>> facultyJsonList,
      ) {
    return CourseWithFaculty(
      course: CourseEntitySearch.fromJson(courseJson),
      faculty: facultyJsonList
          .map((json) => FacultyEntitySearch.fromJson(json))
          .toList(),
    );
  }
}

abstract class StudentRepositorySearch {
  Future<List<CourseEntitySearch>> searchStudentCourses(String studentId, String query);
  Future<List<FacultyEntitySearch>> searchStudentFaculty(String studentId, String query);
}
