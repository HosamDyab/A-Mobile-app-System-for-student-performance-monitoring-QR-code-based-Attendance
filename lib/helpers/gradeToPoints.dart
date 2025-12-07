import '../Student/data/models/Course.dart';
import '../Student/data/models/Semester.dart';


double gradeToPoints(String grade) {

  switch (grade) {
    case 'A+': return 4.0;
    case 'A':  return 4.0;
    case 'A-': return 3.7;
    case 'B+': return 3.3;
    case 'B':  return 3.0;
    case 'B-': return 2.7;
    case 'C+': return 2.3;
    case 'C':  return 2.0;
    case 'C-': return 1.7;
    case 'D+': return 1.3;
    case 'D':  return 1.0;
    default:   return 0.0;
  }
}

double calculateSemesterGpa(List<Course> courses) {
  double totalQ = 0;
  int totalCredits = 0;
  for (final c in courses) {
    final pts = gradeToPoints(c.grade);
    totalQ += pts * c.credits;
    totalCredits += c.credits;
  }
  return totalCredits == 0 ? 0.0 : totalQ / totalCredits;
}

double calculateCumulativeGpa(List<Semester> semesters) {
  double totalPoints = 0;
  int totalCredits = 0;
  for (final s in semesters) {
    // ensure semester totalCredits is consistent with its courses
    totalPoints += s.gpa * s.totalCredits;
    totalCredits += s.totalCredits;
  }
  return totalCredits == 0 ? 0.0 : totalPoints / totalCredits;
}
