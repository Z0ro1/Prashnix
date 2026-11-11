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

  /// Batch load all progress keys in a single instant query to avoid N+1 query lag.
  Future<Map<String, String>> getAllLocalStates() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(DbConstants.tableProgress);
    final result = <String, String>{};
    for (final row in maps) {
      final k = row['key'] as String?;
      final v = row['value'] as String?;
      if (k != null && v != null) {
        result[k] = v;
      }
    }
    return result;
  }
}
