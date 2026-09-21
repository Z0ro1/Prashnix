import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_service.dart';
import '../../../../core/database/db_constants.dart';
import '../../../../core/models/question_model.dart';

class SavedQuestionRepository {
  final DatabaseService _dbService;

  SavedQuestionRepository({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService();

  Future<void> saveQuestion(int questionId) async {
    final db = await _dbService.database;
    await db.insert(
      DbConstants.tableSavedQuestions,
      {
        'question_id': questionId,
        'saved_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeSavedQuestion(int questionId) async {
    final db = await _dbService.database;
    await db.delete(
      DbConstants.tableSavedQuestions,
      where: 'question_id = ?',
      whereArgs: [questionId],
    );
  }

  Future<bool> isQuestionSaved(int questionId) async {
    final db = await _dbService.database;
    final result = await db.query(
      DbConstants.tableSavedQuestions,
      where: 'question_id = ?',
      whereArgs: [questionId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<List<int>> getSavedQuestionIds() async {
    final db = await _dbService.database;
    final result = await db.query(
      DbConstants.tableSavedQuestions,
      columns: ['question_id'],
    );
    return result.map((e) => e['question_id'] as int).toList();
  }

  Future<List<QuestionModel>> getSavedQuestions() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT q.* 
      FROM ${DbConstants.tableQuestions} q
      INNER JOIN ${DbConstants.tableSavedQuestions} sq 
      ON q.id = sq.question_id
      ORDER BY sq.saved_at DESC
    ''');
    
    return maps.map((map) => QuestionModel.fromMap(map)).toList();
  }
}
