
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../Student/data/models/Course.dart';
import '../Student/data/models/Semester.dart';


class LocalDb {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'gpa_calc.db');
    return openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE semesters (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          gpa REAL,
          rank INTEGER,
          totalCredits INTEGER
        );
      ''');
      await db.execute('''
        CREATE TABLE courses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          semesterId INTEGER NOT NULL,
          name TEXT NOT NULL,
          credits INTEGER NOT NULL,
          grade TEXT NOT NULL,
          FOREIGN KEY (semesterId) REFERENCES semesters(id) ON DELETE CASCADE
        );
      ''');
    });
  }


  static Future<int> insertSemester(Semester s) async {
    final database = await db;
    return await database.insert('semesters', s.toMap());
  }

  static Future<int> updateSemester(Semester s) async {
    final database = await db;
    return await database.update('semesters', s.toMap(), where: 'id = ?', whereArgs: [s.id]);
  }

  static Future<int> deleteSemester(int id) async {
    final database = await db;

    await database.delete('courses', where: 'semesterId = ?', whereArgs: [id]);
    return await database.delete('semesters', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Map<String, dynamic>>> getAllSemestersMaps() async {
    final database = await db;
    return await database.query('semesters', orderBy: 'id DESC');
  }


  static Future<int> insertCourse(Course c) async {
    final database = await db;
    return await database.insert('courses', c.toMap());
  }

  static Future<int> updateCourse(Course c) async {
    final database = await db;
    return await database.update('courses', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
  }

  static Future<int> deleteCourse(int id) async {
    final database = await db;
    return await database.delete('courses', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Map<String, dynamic>>> getCoursesBySemesterId(int semesterId) async {
    final database = await db;
    return await database.query('courses', where: 'semesterId = ?', whereArgs: [semesterId], orderBy: 'id ASC');
  }


  static Future<List<Semester>> loadAllSemestersWithCourses() async {
    final semMaps = await getAllSemestersMaps();
    List<Semester> list = [];
    for (final m in semMaps) {
      final semId = m['id'] as int;
      final courseMaps = await getCoursesBySemesterId(semId);
      final courses = courseMaps.map((c) => Course.fromMap(c)).toList();
      list.add(Semester.fromMap(m, courses));
    }
    return list;
  }

  static Future<Semester?> getSemesterById(int id) async {
    final database = await db;
    final maps = await database.query('semesters', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;

    final semMap = maps.first;
    final courseMaps = await getCoursesBySemesterId(id);
    final courses = courseMaps.map((c) => Course.fromMap(c)).toList();
    return Semester.fromMap(semMap, courses);
  }

}
