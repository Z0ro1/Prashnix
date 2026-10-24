import '../../../../core/database/database_service.dart';
import '../../../../core/database/db_constants.dart';
import '../../../../core/models/mistake_model.dart';
import '../../../../core/config/supabase_config.dart';

class MistakeRepository {
  final DatabaseService _dbService;

  MistakeRepository({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService();

  Future<void> logMistake(String questionId, String userAnswer) async {
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

    // Fire and forget to Supabase
    try {
      final supabase = SupabaseConfig.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        final mistakeCount = existing.isNotEmpty ? (existing.first['mistake_count'] as int) + 1 : 1;
        await supabase.from('user_mistakes').upsert({
          'user_id': userId,
          'question_id': questionId,
          'user_answer': userAnswer,
          'mistake_count': mistakeCount,
          'is_cleared': false,
          'last_failed_at': now,
        }, onConflict: 'user_id, question_id');
      }
    } catch (_) {}
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

  Future<void> markMistakeCleared(String questionId) async {
    final db = await _dbService.database;

    await db.update(
      DbConstants.tableMistakes,
      {'is_cleared': 1},
      where: 'question_id = ?',
      whereArgs: [questionId],
    );

    // Fire and forget to Supabase
    try {
      final supabase = SupabaseConfig.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        await supabase.from('user_mistakes').update({
          'is_cleared': true,
        }).eq('user_id', userId).eq('question_id', questionId);
      }
    } catch (_) {}
  }
}
