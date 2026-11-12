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

  /// Checks if a weekly test has been completed locally or synced from cloud.
  Future<bool> isWeeklyTestCompleted(String testId) async {
    final cleanId = testId.replaceFirst('weekly_test_', '');
    final status = await getLocalState('weekly_test_completed_$cleanId');
    if (status == '1') return true;
    final nodeStatus = await getLocalState('status_weekly_test_$cleanId');
    if (nodeStatus == '1') return true;
    final progressStatus = await getLocalState('status_node_weekly_test_$cleanId');
    return progressStatus == '1';
  }

  /// Marks a weekly test as completed and records the final score.
  Future<void> markWeeklyTestCompleted(String testId, {int score = 0}) async {
    final cleanId = testId.replaceFirst('weekly_test_', '');
    await saveLocalState('weekly_test_completed_$cleanId', '1');
    await saveLocalState('status_weekly_test_$cleanId', '1');
    await saveLocalState('weekly_test_score_$cleanId', score.toString());
    await saveLocalState('weekly_test_completed_at_$cleanId', DateTime.now().toIso8601String());
  }

  /// Retrieves the recorded score for a completed weekly test.
  Future<int?> getWeeklyTestScore(String testId) async {
    final cleanId = testId.replaceFirst('weekly_test_', '');
    final scoreStr = await getLocalState('weekly_test_score_$cleanId');
    return scoreStr != null ? int.tryParse(scoreStr) : null;
  }
}
