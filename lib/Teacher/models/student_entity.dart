// class StudentEntity {
//   final String id;
//   final String name;
//   final String grade;
//   final String level;
//   final bool isPresent;
//   final DateTime? lastAttendance;
//   final String? avatarUrl;
  
//   StudentEntity({
//     required this.id,
//     required this.name,
//     required this.grade,
//     required this.level,
//     this.isPresent = false,
//     this.lastAttendance,
//     this.avatarUrl,
//   });
  
//   factory StudentEntity.fromModel(dynamic model) {
//     return StudentEntity(
//       id: model.id,
//       name: model.name,
//       grade: model.grade,
//       level: model.level,
//       isPresent: model.isPresent,
//       lastAttendance: model.lastAttendance,
//       avatarUrl: model.avatarUrl,
//     );
//   }
  
//   StudentEntity copyWith({
//     String? id,
//     String? name,
//     String? grade,
//     String? level,
//     bool? isPresent,
//     DateTime? lastAttendance,
//     String? avatarUrl,
//   }) {
//     return StudentEntity(
//       id: id ?? this.id,
//       name: name ?? this.name,
//       grade: grade ?? this.grade,
//       level: level ?? this.level,
//       isPresent: isPresent ?? this.isPresent,
//       lastAttendance: lastAttendance ?? this.lastAttendance,
//       avatarUrl: avatarUrl ?? this.avatarUrl,
//     );
//   }
// }
class StudentEntity {
  final String studentId;
  final String userId;
  final String studentCode;
  final String major;
  final double currentGpa;
  final String academicLevel;
  final String? fullName; // ← Make it nullable
  final String? avatarUrl;

  StudentEntity({
    required this.studentId,
    required this.userId,
    required this.studentCode,
    required this.major,
    required this.currentGpa,
    required this.academicLevel,
    this.fullName,
    this.avatarUrl,
  });

  factory StudentEntity.fromModel(dynamic model) {
    return StudentEntity(
      studentId: model.studentId,
      userId: model.userId,
      studentCode: model.studentCode,
      major: model.major,
      currentGpa: model.currentGpa,
      academicLevel: model.academicLevel,
      fullName: model.fullName, // ← This might be null
      avatarUrl: model.avatarUrl,
    );
  }

  StudentEntity copyWith({
    String? studentId,
    String? userId,
    String? studentCode,
    String? major,
    double? currentGpa,
    String? academicLevel,
    String? fullName,
    String? avatarUrl,
  }) {
    return StudentEntity(
      studentId: studentId ?? this.studentId,
      userId: userId ?? this.userId,
      studentCode: studentCode ?? this.studentCode,
      major: major ?? this.major,
      currentGpa: currentGpa ?? this.currentGpa,
      academicLevel: academicLevel ?? this.academicLevel,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}