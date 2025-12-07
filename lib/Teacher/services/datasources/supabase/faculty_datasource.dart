import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/course_offering.dart';

class FacultyDataSource {
  final supabase = Supabase.instance.client;

  Future<List<CourseOffering>> getFacultyCourses(String facultyId, String role) async {
    try {
      // For Faculty: Query LectureCourseOffering with FacultyId
      if (role == 'faculty') {
        final response = await supabase
            .from('LectureCourseOffering')
            .select('*, Course(*)')
            .eq('FacultyId', facultyId);

        final courses = (response as List<dynamic>)
            .map((e) => CourseOffering.fromJson(e as Map<String, dynamic>))
            .toList();
        
        print('📚 Fetched ${courses.length} courses for faculty $facultyId');
        for (var course in courses) {
          print('   - ${course.courseCode}: ${course.schedule}');
        }
        
        return courses;
      } 
      // For Teacher Assistant: Query SectionCourseOffering with TAId
      else if (role == 'teacher_assistant') {
        final response = await supabase
            .from('SectionCourseOffering')
            .select('*, Course(*)')
            .eq('TAId', facultyId);

        // Map section offerings to course offerings
        final courses = (response as List<dynamic>)
            .map((e) {
              // Convert section data to match lecture offering format
              return CourseOffering(
                id: e['CourseId']?.toString() ?? '',
                courseCode: e['Course'] != null ? e['Course']['Code'] : '',
                courseTitle: e['Course'] != null ? e['Course']['Title'] : '',
                schedule: e['Schedule'] ?? '',
                lectureOfferingId: e['SectionOfferingId']?.toString() ?? '',
              );
            })
            .toList();
        
        print('📚 Fetched ${courses.length} sections for TA $facultyId');
        for (var course in courses) {
          print('   - ${course.courseCode}: ${course.schedule}');
        }
        
        return courses;
      }
      
      return [];
    } catch (e) {
      print('❌ Error fetching courses for $role: $e');
      return [];
    }
  }
}

