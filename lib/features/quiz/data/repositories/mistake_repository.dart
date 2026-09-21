import '../../../../core/database/database_service.dart';
import '../../../../core/database/db_constants.dart';
import '../../../../core/models/mistake_model.dart';

class MistakeRepository {
  final DatabaseService _dbService;

  MistakeRepository({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService();

  Future<void> logMistake(int questionId, String userAnswer) async {
    final db = await _dbService.database;

    // Check if mistake already exists for this question
    final List<Map<String, dynamic>> existing = await db.query(
      DbConstants.tableMistakes,
      where: 'question_id = ?',
      whereArgs: [questionId],
      limit: 1,
    );

    final now = DateTime.now().toIso8601String();

    if (existing.isNotEmpty) {
      final mistake = MistakeModel.fromMap(existing.first);
      await db.update(
        DbConstants.tableMistakes,
        {
          'mistake_count': mistake.mistakeCount + 1,
          'user_answer': userAnswer, // Update with the latest wrong answer
          'is_cleared': 0, // Reset to not cleared
          'last_failed_at': now,
        },
        where: 'id = ?',
        whereArgs: [mistake.id],
      );
    } else {
      final newMistake = MistakeModel(
        questionId: questionId,
        userAnswer: userAnswer,
        lastFailedAt: now,
      );
      await db.insert(DbConstants.tableMistakes, newMistake.toMap());
    }
  }

  Future<List<MistakeModel>> getUnclearedMistakes() async {
    final db = await _dbService.database;

    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableMistakes,
      where: 'is_cleared = ?',
      whereArgs: [0],
      orderBy: 'last_failed_at DESC',
    );

    return maps.map((map) => MistakeModel.fromMap(map)).toList();
  }

  Future<void> markMistakeCleared(int questionId) async {
    final db = await _dbService.database;

    await db.update(
      DbConstants.tableMistakes,
      {'is_cleared': 1},
      where: 'question_id = ?',
      whereArgs: [questionId],
    );
  }
}
