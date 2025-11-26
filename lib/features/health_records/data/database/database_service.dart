import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/health_record.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  static Future<void> initialize() async {
    // Database initialization for Android/iOS
    debugPrint('Database service ready for mobile platforms');
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('health_records.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    try {
      // Get database path for mobile platforms (Android/iOS)
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);
      
      debugPrint('Database path: $path');

      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
        onOpen: (db) {
          debugPrint('Database opened successfully');
        },
      );
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE health_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        steps INTEGER NOT NULL,
        calories INTEGER NOT NULL,
        water INTEGER NOT NULL
      )
    ''');

    // Insert dummy data
    await _insertDummyData(db);
  }

  Future<void> _insertDummyData(Database db) async {
    final now = DateTime.now();
    final dummyRecords = [
      HealthRecord(
        date: formatDate(now),
        steps: 8500,
        calories: 2200,
        water: 2000,
      ),
      HealthRecord(
        date: formatDate(now.subtract(const Duration(days: 1))),
        steps: 7200,
        calories: 1950,
        water: 1800,
      ),
      HealthRecord(
        date: formatDate(now.subtract(const Duration(days: 2))),
        steps: 10000,
        calories: 2400,
        water: 2500,
      ),
      HealthRecord(
        date: formatDate(now.subtract(const Duration(days: 3))),
        steps: 6500,
        calories: 1800,
        water: 1500,
      ),
    ];

    for (var record in dummyRecords) {
      await db.insert('health_records', record.toMap());
    }
  }

  String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // CREATE
  Future<int> createRecord(HealthRecord record) async {
    final db = await database;
    return await db.insert('health_records', record.toMap());
  }

  // READ - Get all records
  Future<List<HealthRecord>> getRecords() async {
    final db = await database;
    final result = await db.query(
      'health_records',
      orderBy: 'date DESC',
    );
    return result.map((map) => HealthRecord.fromMap(map)).toList();
  }

  // READ - Get records by date
  Future<List<HealthRecord>> getRecordsByDate(String date) async {
    final db = await database;
    final result = await db.query(
      'health_records',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'date DESC',
    );
    return result.map((map) => HealthRecord.fromMap(map)).toList();
  }

  // READ - Get today's records
  Future<List<HealthRecord>> getTodayRecords() async {
    final today = formatDate(DateTime.now());
    return getRecordsByDate(today);
  }

  // UPDATE
  Future<int> updateRecord(HealthRecord record) async {
    final db = await database;
    return await db.update(
      'health_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  // DELETE
  Future<int> deleteRecord(int id) async {
    final db = await database;
    return await db.delete(
      'health_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<HealthRecord>> getRecordsBetween(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.query(
      'health_records',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [formatDate(start), formatDate(end)],
      orderBy: 'date ASC',
    );
    return result.map((map) => HealthRecord.fromMap(map)).toList();
  }

  Future<HealthRecord?> getLatestRecord() async {
    final db = await database;
    final result = await db.query(
      'health_records',
      orderBy: 'date DESC',
      limit: 1,
    );
    if (result.isEmpty) return null;
    return HealthRecord.fromMap(result.first);
  }
}

