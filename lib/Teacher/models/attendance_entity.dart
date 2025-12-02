class AttendanceEntity {
  final String id;
  final String studentId;
  final String sessionId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String status;
  
  AttendanceEntity({
    required this.id,
    required this.studentId,
    required this.sessionId,
    required this.checkInTime,
    this.checkOutTime,
    this.status = 'present',
  });
  
  factory AttendanceEntity.fromModel(dynamic model) {
    return AttendanceEntity(
      id: model.id,
      studentId: model.studentId,
      sessionId: model.sessionId,
      checkInTime: model.checkInTime,
      checkOutTime: model.checkOutTime,
      status: model.status,
    );
  }
  
  AttendanceEntity copyWith({
    String? id,
    String? studentId,
    String? sessionId,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? status,
  }) {
    return AttendanceEntity(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      sessionId: sessionId ?? this.sessionId,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      status: status ?? this.status,
    );
  }
}