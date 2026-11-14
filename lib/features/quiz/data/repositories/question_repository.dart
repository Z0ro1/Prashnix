import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../../core/config/supabase_config.dart';
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

  Future<List<QuestionModel>> getQuestionsByNode(String nodeId, {int lessonIndex = 0}) async {
    final db = await _dbService.database;
    final subjectTag = nodeId;
    String? targetLessonId;

    // 1. Try to fetch freshest questions from Supabase (Real-time sync)
    try {
      if (kDebugMode) {
        print('[QuestionRepository] Fetching lessons and questions for node: $subjectTag, lessonIndex: $lessonIndex...');
      }

      // Fetch ordered lessons for this node
      final lessonsResponse = await SupabaseConfig.client
          .from('lessons')
          .select('id, title, order_index')
          .eq('node_id', subjectTag)
          .order('order_index', ascending: true);

      if (lessonsResponse.isNotEmpty) {
        final safeIndex = (lessonIndex >= 0 && lessonIndex < lessonsResponse.length)
            ? lessonIndex
            : (lessonIndex % lessonsResponse.length);
        targetLessonId = lessonsResponse[safeIndex]['id']?.toString();
      }

      // Fetch questions specifically for this lesson if targetLessonId found, otherwise by node
      List<dynamic> response;
      if (targetLessonId != null) {
        response = await SupabaseConfig.client
            .from('questions')
            .select('*')
            .eq('lesson_id', targetLessonId)
            .limit(30);
      } else {
        response = await SupabaseConfig.client
            .from('questions')
            .select('*, lessons!inner(node_id)')
            .eq('lessons.node_id', subjectTag)
            .limit(50);
      }

      if (response.isNotEmpty) {
        final batch = db.batch();

        for (final row in response) {
          final rawContent = row['content'];
          final content = (rawContent is Map) ? rawContent.cast<String, dynamic>() : <String, dynamic>{};
          final text = content['text'] as String? ?? 'Empty Question';
          final rawOptions = content['options'];
          final options = (rawOptions is List)
              ? rawOptions.map((e) => e?.toString() ?? '').toList()
              : <String>[];
          final explanation = content['explanation'] as String?;
          final pyqYear = content['pyq_year'] as int?;
          final districtTag = content['district_tag'] as String?;
          
          final optA = options.isNotEmpty ? options[0] : '';
          final optB = options.length > 1 ? options[1] : '';
          final optC = options.length > 2 ? options[2] : '';
          final optD = options.length > 3 ? options[3] : '';

          // Bulletproof Validation: Skip invalid or incomplete questions so learners never encounter broken screens
          if (options.length < 4 ||
              optA.trim().isEmpty ||
              optB.trim().isEmpty ||
              optC.trim().isEmpty ||
              optD.trim().isEmpty ||
              text.trim().length < 3 ||
              text == 'Empty Question') {
            continue;
          }
          
          final correctAns = row['correct_answer'] ?? 
                             row['correct_option'] ?? 
                             content['correct_option'] ?? 
                             content['correct_answer'];
          final correctIndex = QuestionModel.resolveCorrectOption(
            rawAnswer: correctAns,
            optA: optA,
            optB: optB,
            optC: optC,
            optD: optD,
          );

          final lessonIdTag = row['lesson_id']?.toString() ?? targetLessonId;
          final displayId = row['display_id']?.toString();

          batch.insert(
            DbConstants.tableQuestions,
            {
              'id': row['id'],
              'display_id': displayId,
              'subject_tag': subjectTag,
              'subtopic_tag': lessonIdTag,
              'question_text': text,
              'option_a': optA,
              'option_b': optB,
              'option_c': optC,
              'option_d': optD,
              'correct_option': correctIndex,
              'explanation': explanation,
              'pyq_year': pyqYear,
              'district_tag': districtTag,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
        if (kDebugMode) {
          print('[QuestionRepository] Synced ${response.length} questions to local DB for lesson $targetLessonId.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[QuestionRepository] Failed to fetch from Supabase (Offline Mode): $e');
      }
    }

    // 2. Fetch from local SQLite and return
    List<Map<String, dynamic>> questionMaps = [];
    if (targetLessonId != null) {
      questionMaps = await db.query(
        DbConstants.tableQuestions,
        where: 'subject_tag = ? AND subtopic_tag = ?',
        whereArgs: [subjectTag, targetLessonId],
        limit: 25,
      );
    }

    // Fallback: Offset by lessonIndex * 25
    if (questionMaps.isEmpty) {
      final safeLessonIndex = lessonIndex >= 0 ? lessonIndex : 0;
      final offset = safeLessonIndex * 25;
      questionMaps = await db.query(
        DbConstants.tableQuestions,
        where: 'subject_tag = ?',
        whereArgs: [subjectTag],
        offset: offset,
        limit: 25,
      );

      // If offset exceeds available rows, wrap back to the first 25
      if (questionMaps.isEmpty) {
        questionMaps = await db.query(
          DbConstants.tableQuestions,
          where: 'subject_tag = ?',
          whereArgs: [subjectTag],
          limit: 25,
        );
      }
    }

    return questionMaps.map((map) => QuestionModel.fromMap(map)).toList();
  }

  Future<List<QuestionModel>> getQuestionsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final db = await _dbService.database;
    final placeholders = List.filled(ids.length, '?').join(',');

    // 1. Fetch whatever we have locally
    List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableQuestions,
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
    
    List<QuestionModel> localQuestions = maps.map((map) => QuestionModel.fromMap(map)).toList();
    
    // 2. Identify missing IDs
    final localIds = localQuestions.map((q) => q.id).toSet();
    final missingIds = ids.where((id) => !localIds.contains(id)).toList();
    
    // 3. If there are missing questions, fetch them from Supabase
    if (missingIds.isNotEmpty) {
      if (kDebugMode) {
        print('[QuestionRepository] Fetching ${missingIds.length} missing questions from Supabase...');
      }
      try {
        final response = await SupabaseConfig.client
            .from('questions')
            .select()
            .inFilter('id', missingIds);

        if (response.isNotEmpty) {
          final batch = db.batch();
          for (final row in response) {
            final rawContent = row['content'];
            final content = (rawContent is Map) ? rawContent.cast<String, dynamic>() : <String, dynamic>{};
            final text = content['text'] as String? ?? 'Empty Question';
            final rawOptions = content['options'];
            final options = (rawOptions is List)
                ? rawOptions.map((e) => e?.toString() ?? '').toList()
                : <String>[];
            final explanation = content['explanation'] as String?;
            final pyqYear = content['pyq_year'] as int?;
            final districtTag = content['district_tag'] as String?;
            
            final optA = options.isNotEmpty ? options[0] : '';
            final optB = options.length > 1 ? options[1] : '';
            final optC = options.length > 2 ? options[2] : '';
            final optD = options.length > 3 ? options[3] : '';

            // Bulletproof Validation: Skip invalid or incomplete questions
            if (options.length < 4 ||
                optA.trim().isEmpty ||
                optB.trim().isEmpty ||
                optC.trim().isEmpty ||
                optD.trim().isEmpty ||
                text.trim().length < 3 ||
                text == 'Empty Question') {
              continue;
            }
            
            final correctAns = row['correct_answer'] ?? 
                               row['correct_option'] ?? 
                               content['correct_option'] ?? 
                               content['correct_answer'];
            final correctIndex = QuestionModel.resolveCorrectOption(
              rawAnswer: correctAns,
              optA: optA,
              optB: optB,
              optC: optC,
              optD: optD,
            );
            final displayId = row['display_id']?.toString();

            batch.insert(
              DbConstants.tableQuestions,
              {
                'id': row['id'],
                'display_id': displayId,
                'subject_tag': 'unknown',
                'subtopic_tag': row['lesson_id'],
                'question_text': text,
                'option_a': optA,
                'option_b': optB,
                'option_c': optC,
                'option_d': optD,
                'correct_option': correctIndex,
                'explanation': explanation,
                'pyq_year': pyqYear,
                'district_tag': districtTag,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          await batch.commit(noResult: true);

          // 4. Re-query local database for the complete set
          maps = await db.query(
            DbConstants.tableQuestions,
            where: 'id IN ($placeholders)',
            whereArgs: ids,
          );
          
          localQuestions = maps.map((map) => QuestionModel.fromMap(map)).toList();
        }
      } catch (e) {
        if (kDebugMode) {
          print('[QuestionRepository] Failed to fetch missing questions: $e');
        }
      }
    }

    return localQuestions;
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
