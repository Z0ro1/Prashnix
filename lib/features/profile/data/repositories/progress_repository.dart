import '../../../../core/database/database_service.dart';
import '../../../../core/database/db_constants.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

class ProgressRepository {
  final DatabaseService _dbService;

  ProgressRepository({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService();

  Future<void> saveLocalState(String key, String value) async {
    final db = await _dbService.database;

    await db.insert(
      DbConstants.tableProgress,
      {'key': key, 'value': value},
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  Future<String?> getLocalState(String key) async {
    final db = await _dbService.database;

    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableProgress,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }
    return null;
  }
}
