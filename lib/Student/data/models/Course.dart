
class Course {
  int? id;
  int semesterId;
  String name;
  int credits;
  String grade;

  Course({
    this.id,
    required this.semesterId,
    required this.name,
    required this.credits,
    required this.grade,
  });

  factory Course.fromMap(Map<String, dynamic> m) => Course(
    id: m['id'] as int?,
    semesterId: m['semesterId'] as int,
    name: m['name'] as String,
    credits: m['credits'] as int,
    grade: m['grade'] as String,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'semesterId': semesterId,
    'name': name,
    'credits': credits,
    'grade': grade,
  };
}
