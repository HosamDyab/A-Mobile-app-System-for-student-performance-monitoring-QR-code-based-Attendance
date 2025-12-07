class GradeEntity {
  final String id;
  final String studentId;
  final String examGrade;
  final String assignmentGrade;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  GradeEntity({
    required this.id,
    required this.studentId,
    required this.examGrade,
    required this.assignmentGrade,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory GradeEntity.fromModel(dynamic model) {
    return GradeEntity(
      id: model.id,
      studentId: model.studentId,
      examGrade: model.examGrade,
      assignmentGrade: model.assignmentGrade,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }
  
  GradeEntity copyWith({
    String? id,
    String? studentId,
    String? examGrade,
    String? assignmentGrade,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GradeEntity(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      examGrade: examGrade ?? this.examGrade,
      assignmentGrade: assignmentGrade ?? this.assignmentGrade,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}