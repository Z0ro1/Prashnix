import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_service.dart';
import '../../../../core/database/db_constants.dart';
import '../../../../core/models/question_model.dart';
import '../../../quiz/data/repositories/question_repository.dart';
import '../../../../core/config/supabase_config.dart';

class SavedQuestionRepository {
  final DatabaseService _dbService;

  SavedQuestionRepository({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService();

  Future<void> saveQuestion(String questionId) async {
    final db = await _dbService.database;
    final now = DateTime.now().toIso8601String();
    await db.insert(
      DbConstants.tableSavedQuestions,
      {
        'question_id': questionId,
        'saved_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    // Fire and forget to Supabase
    try {
      final supabase = SupabaseConfig.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        await supabase.from('saved_questions').upsert({
          'user_id': userId,
          'question_id': questionId,
          'saved_at': now,
        }, onConflict: 'user_id, question_id');
      }
    } catch (_) {}
  }

  Future<void> removeSavedQuestion(String questionId) async {
    final db = await _dbService.database;
    await db.delete(
      DbConstants.tableSavedQuestions,
      where: 'question_id = ?',
      whereArgs: [questionId],
    );

    // Fire and forget to Supabase
    try {
      final supabase = SupabaseConfig.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        await supabase.from('saved_questions').delete()
          .eq('user_id', userId).eq('question_id', questionId);
      }
    } catch (_) {}
  }

  Future<bool> isQuestionSaved(String questionId) async {
    final db = await _dbService.database;
    final result = await db.query(
      DbConstants.tableSavedQuestions,
      where: 'question_id = ?',
      whereArgs: [questionId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<List<String>> getSavedQuestionIds() async {
    final db = await _dbService.database;
    final result = await db.query(
      DbConstants.tableSavedQuestions,
      columns: ['question_id'],
    );
    return result.map((e) => e['question_id'] as String).toList();
  }

  Future<List<QuestionModel>> getSavedQuestions() async {
    final db = await _dbService.database;
    
    // First, get the ordered list of saved question IDs
    final List<Map<String, dynamic>> savedRows = await db.query(
      DbConstants.tableSavedQuestions,
      columns: ['question_id'],
      orderBy: 'saved_at DESC',
    );
    
    if (savedRows.isEmpty) return [];
    
    final List<String> savedIds = savedRows.map((e) => e['question_id'] as String).toList();
    
    // Use QuestionRepository to safely fetch them (from local or Supabase)
    // This ensures we never lose access to a saved question even if local cache is cleared.
    final questionRepo = QuestionRepository(dbService: _dbService);
    final List<QuestionModel> questions = await questionRepo.getQuestionsByIds(savedIds);
    
    // Reorder them to match saved_at DESC
    final Map<String, QuestionModel> questionMap = {
      for (var q in questions) 
        if (q.id != null) q.id!: q
    };
    
    final List<QuestionModel> orderedQuestions = [];
    for (final id in savedIds) {
      if (questionMap.containsKey(id)) {
        orderedQuestions.add(questionMap[id]!);
      }
    }
    
    return orderedQuestions;
  }
}
