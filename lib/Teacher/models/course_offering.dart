class CourseOffering {
  final String id;                 // lectureofferingid OR sectionofferingid
  final String courseCode;         // coursecode
  final String courseTitle;        // coursename
  final String schedule;           // formatted string "Sunday | 10:00 - 12:00"
  final String offeringId;         // same as id

  CourseOffering({
    required this.id,
    required this.courseCode,
    required this.courseTitle,
    required this.schedule,
    required this.offeringId,
  });

  /// Factory used when reading lecturecourseoffering (Doctor)
  factory CourseOffering.fromLectureJson(Map<String, dynamic> json) {
    final timeslot = json['Timeslot'];

    final schedule = timeslot != null
        ? "${timeslot['dayofweek']} | ${timeslot['starttime']} - ${timeslot['endtime']}"
        : "No Schedule";

    return CourseOffering(
      id: json['lectureofferingid']?.toString() ?? '',
      courseCode: json['coursecode'] ?? '',
      courseTitle: json['Course']?['coursename'] ?? '',
      schedule: schedule,
      offeringId: json['lectureofferingid']?.toString() ?? '',
    );
  }

  /// Factory used when reading sectioncourseoffering (TA)
  factory CourseOffering.fromSectionJson(Map<String, dynamic> json) {
    final section = json['sectionoffering'];
    final timeslot = section['Timeslot'];

    final schedule = timeslot != null
        ? "${timeslot['dayofweek']} | ${timeslot['starttime']} - ${timeslot['endtime']}"
        : "No Schedule";

    return CourseOffering(
      id: section['sectionofferingid']?.toString() ?? '',
      courseCode: section['coursecode'] ?? '',
      courseTitle: section['Course']?['coursename'] ?? '',
      schedule: schedule,
      offeringId: section['sectionofferingid']?.toString() ?? '',
    );
  }
}
