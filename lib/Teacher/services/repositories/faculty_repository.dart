import '../datasources/supabase/faculty_datasource.dart';
import '../../models/course_offering.dart';

class FacultyRepository {
  final FacultyDataSource _dataSource;

  FacultyRepository(this._dataSource);

   final Map<String, String> dayMapping = {
    'SUN': 'Sunday',
    'MON': 'Monday',
    'TUE': 'Tuesday',
    'WED': 'Wednesday',
    'THU': 'Thursday',
    'FRI': 'Friday',
    'SAT': 'Saturday',
  };

  Future<List<CourseOffering>> getTodayCourses(String facultyId, String role) async {
     final allCourses = await _dataSource.getFacultyCourses(facultyId, role);

    final today = DateTime.now();
    final todayFullName = _getDayName(today.weekday).toLowerCase();

    print('📅 Today is: $todayFullName');

    final todayCourses = allCourses.where((course) {
      final schedule = course.schedule;

       final prefix = schedule.split('|').first.trim().toUpperCase();

       final fullDay = dayMapping[prefix]?.toLowerCase() ?? prefix.toLowerCase();

      final isMatch = fullDay == todayFullName;

      print("   ${isMatch ? '✅' : '❌'} ${course.courseCode} → $fullDay vs $todayFullName");

      return isMatch;
    }).toList();

    print('  Total courses today: ${todayCourses.length}');
    return todayCourses;
  }

   String _getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }
}
