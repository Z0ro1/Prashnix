import '../../../../core/database/database_service.dart';
import '../../../../core/database/db_constants.dart';
import '../../../../core/models/question_model.dart';

class QuestionRepository {
  final DatabaseService _dbService;

  QuestionRepository({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService();

  Future<List<QuestionModel>> getRandomSprintQuestions(String subject, int limit) async {
    final db = await _dbService.database;

    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableQuestions,
      where: 'subject_tag = ?',
      whereArgs: [subject],
      orderBy: 'RANDOM()',
      limit: limit,
    );

    return maps.map((map) => QuestionModel.fromMap(map)).toList();
  }

  Future<List<QuestionModel>> getQuestionsByNode(int nodeId) async {
    final db = await _dbService.database;

    // First find the lesson subject/tag for this node
    final List<Map<String, dynamic>> lessonMaps = await db.query(
      DbConstants.tableLessons,
      where: 'node_id = ?',
      whereArgs: [nodeId],
      limit: 1,
    );

    if (lessonMaps.isEmpty) return [];

    final subjectTag = lessonMaps.first['subject_tag'] as String;

    // Then fetch questions for that subject (or could be specific IDs if linked table existed)
    // For now, we'll fetch a fixed set for the node based on subject tag.
    final List<Map<String, dynamic>> questionMaps = await db.query(
      DbConstants.tableQuestions,
      where: 'subject_tag = ?',
      whereArgs: [subjectTag],
      limit: 25, // Default limit per node lesson
    );

    return questionMaps.map((map) => QuestionModel.fromMap(map)).toList();
  }

  Future<List<QuestionModel>> getQuestionsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];

    final db = await _dbService.database;
    final placeholders = List.filled(ids.length, '?').join(',');

    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableQuestions,
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );

    return maps.map((map) => QuestionModel.fromMap(map)).toList();
  }

  Future<List<QuestionModel>> getWeeklyTestQuestions(int limit, int highestUnlockedLevel) async {
    final db = await _dbService.database;

    // Build a list of subject tags for unlocked nodes
    // Our seed_db assigned subject_tag = 'node_0', 'node_1', etc.
    final List<String> unlockedTags = [];
    for (int i = 0; i <= highestUnlockedLevel; i++) {
      unlockedTags.add('node_$i');
    }

    final placeholders = List.filled(unlockedTags.length, '?').join(',');
    
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableQuestions,
      where: 'subject_tag IN ($placeholders)',
      whereArgs: unlockedTags,
      orderBy: 'RANDOM()',
      limit: limit,
    );

    // If we didn't get enough questions (e.g. at level 0), optionally fall back to any random questions
    if (maps.isEmpty) {
      final fallbackMaps = await db.query(
        DbConstants.tableQuestions,
        orderBy: 'RANDOM()',
        limit: limit,
      );
      return fallbackMaps.map((map) => QuestionModel.fromMap(map)).toList();
    }

    return maps.map((map) => QuestionModel.fromMap(map)).toList();
  }
}
