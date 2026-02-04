import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;
  static const String _tableName = 'form_data';
  static const String _dbName = 'form_storage.db';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            field_id TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      },
    );
  }

  static Future<void> saveFormData(Map<String, dynamic> formData) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(_tableName);
      for (final entry in formData.entries) {
        final valueStr = json.encode(entry.value);
        await txn.insert(
          _tableName,
          {'field_id': entry.key, 'value': valueStr},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  static Future<Map<String, dynamic>> loadFormData() async {
    final db = await database;
    final rows = await db.query(_tableName);
    final Map<String, dynamic> formData = {};
    for (final row in rows) {
      final fieldId = row['field_id'] as String;
      final valueStr = row['value'] as String;
      try {
        formData[fieldId] = json.decode(valueStr);
      } catch (e) {
        formData[fieldId] = valueStr;
      }
    }
    return formData;
  }

  static Future<void> clearFormData() async {
    final db = await database;
    await db.delete(_tableName);
  }
}
