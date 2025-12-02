import '../datasources/supabase/faculty_datasource.dart';
import '../../models/course_offering.dart';

class FacultyRepository {
  final FacultyDataSource _dataSource;

  FacultyRepository(this._dataSource);

  Future<List<CourseOffering>> getTodayCourses(String facultyId, String role) async {
    final allCourses = await _dataSource.getFacultyCourses(facultyId, role);
    
    final today = DateTime.now();
    final dayName = _getDayName(today.weekday);
    
    print('📅 Today is: $dayName (${today.toString().split(' ')[0]})');
    
    // Filter courses that contain the current day name in their schedule
    // Case-insensitive comparison to handle database variations
    final todayCourses = allCourses.where((c) {
      final schedule = c.schedule.toLowerCase();
      final day = dayName.toLowerCase();
      
      // Check if schedule starts with the day name (e.g., "Sunday 08:00")
      // or contains it with word boundaries (e.g., "Monday & Wednesday")
      final matches = schedule.startsWith(day) || 
             schedule.contains(' $day ') || 
             schedule.contains('$day,') ||
             schedule.contains('$day&') ||
             schedule.contains('& $day') ||
             schedule.contains(', $day');
      
      if (matches) {
        print('   ✅ ${c.courseCode} matches today ($schedule)');
      } else {
        print('   ❌ ${c.courseCode} does NOT match ($schedule)');
      }
      
      return matches;
    }).toList();
    
    print('🎯 Filtered to ${todayCourses.length} courses for today');
    
    return todayCourses;
  }

  String _getDayName(int weekday) {
    // DateTime.monday is 1, sunday is 7
    switch (weekday) {
      case DateTime.monday: return 'Monday';
      case DateTime.tuesday: return 'Tuesday';
      case DateTime.wednesday: return 'Wednesday';
      case DateTime.thursday: return 'Thursday';
      case DateTime.friday: return 'Friday';
      case DateTime.saturday: return 'Saturday';
      case DateTime.sunday: return 'Sunday';
      default: return '';
    }
  }
}

