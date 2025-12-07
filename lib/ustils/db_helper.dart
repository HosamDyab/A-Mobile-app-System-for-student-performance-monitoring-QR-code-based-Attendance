import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'attendance.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        db.execute('''
          CREATE TABLE attendance(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            studentId TEXT,
            sessionId TEXT,
            timestamp TEXT
          )
        ''');
      },
    );
  }

  static Future<void> markAttendance(String studentId, String sessionId) async {
    final db = await database;
    await db.insert('attendance', {
      'studentId': studentId,
      'sessionId': sessionId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getAttendance() async {
    final db = await database;
    return db.query('attendance', orderBy: 'timestamp DESC');
  }
}
