class CourseOffering {
  final String id;
  final String courseCode;
  final String courseTitle;
  final String schedule; // e.g., "Sunday 10:00-12:00"
  final String lectureOfferingId;

  CourseOffering({
    required this.id,
    required this.courseCode,
    required this.courseTitle,
    required this.schedule,
    required this.lectureOfferingId,
  });

  factory CourseOffering.fromJson(Map<String, dynamic> json) {
    return CourseOffering(
      id: json['CourseId']?.toString() ?? '',
      courseCode: json['Course'] != null ? json['Course']['Code'] : '',
      courseTitle: json['Course'] != null ? json['Course']['Title'] : '',
      schedule: json['Schedule'] ?? '',
      lectureOfferingId: json['LectureOfferingId']?.toString() ?? '',
    );
  }
}

