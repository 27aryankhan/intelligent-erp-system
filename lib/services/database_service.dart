import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'hitam_scraper_service.dart';

/// Offline-First SQLite Database for HITAM ERP
/// Provides instant 0ms data retrieval and persists cached attendance, accounts, and outbox.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'hitam_erp.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // 1. Accounts Table
        await db.execute('''
          CREATE TABLE accounts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT UNIQUE NOT NULL,
            role TEXT NOT NULL,
            last_synced_at TEXT
          );
        ''');

        // 2. Cached Attendance Table
        await db.execute('''
          CREATE TABLE cached_attendance (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            subject_code TEXT,
            subject_name TEXT NOT NULL,
            classes_held INTEGER NOT NULL,
            classes_attended INTEGER NOT NULL,
            percentage REAL NOT NULL
          );
        ''');

        // 3. Cached Timetable Table
        await db.execute('''
          CREATE TABLE cached_timetable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            day_name TEXT NOT NULL,
            period_slot INTEGER NOT NULL,
            subject_title TEXT NOT NULL,
            time_range TEXT,
            room_no TEXT
          );
        ''');

        // 4. Faculty Offline Attendance Outbox
        await db.execute('''
          CREATE TABLE faculty_outbox (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            period INTEGER NOT NULL,
            section TEXT NOT NULL,
            absentees_json TEXT NOT NULL,
            is_synced INTEGER DEFAULT 0
          );
        ''');
      },
    );
  }

  /// Saves or updates the active user account record
  Future<void> saveAccount(String userId, String role) async {
    final db = await database;
    await db.insert(
      'accounts',
      {
        'user_id': userId,
        'role': role,
        'last_synced_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Replaces cached attendance records for a user with the latest scraped data
  Future<void> cacheAttendance(String userId, List<SubjectAttendance> records) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('cached_attendance', where: 'user_id = ?', whereArgs: [userId]);
      for (var record in records) {
        await txn.insert('cached_attendance', {
          'user_id': userId,
          'subject_code': record.subjectCode,
          'subject_name': record.subjectName,
          'classes_held': record.classesHeld,
          'classes_attended': record.classesAttended,
          'percentage': record.percentage,
        });
      }
      await txn.update(
        'accounts',
        {'last_synced_at': DateTime.now().toIso8601String()},
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    });
  }

  /// Retrieves cached attendance for instant 0ms offline load
  Future<List<SubjectAttendance>> getCachedAttendance(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cached_attendance',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return maps.map((m) => SubjectAttendance.fromMap(m)).toList();
  }

  /// Clears cache on logout
  Future<void> clearUserCache(String userId) async {
    final db = await database;
    await db.delete('cached_attendance', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('accounts', where: 'user_id = ?', whereArgs: [userId]);
  }
}
