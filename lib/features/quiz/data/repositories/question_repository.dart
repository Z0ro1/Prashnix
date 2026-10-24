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

  Future<List<QuestionModel>> getQuestionsByNode(String nodeId) async {
    final db = await _dbService.database;
    final subjectTag = nodeId;

    // 1. Try to fetch freshest questions from Supabase (Real-time sync)
    try {
      if (kDebugMode) {
        print('[QuestionRepository] Fetching freshest questions from Supabase for node: $subjectTag...');
      }
      // Since questions belong to lessons, and lessons belong to nodes, we join them
      final response = await SupabaseConfig.client
          .from('questions')
          .select('*, lessons!inner(node_id)')
          .eq('lessons.node_id', subjectTag)
          .limit(50);

      if (response.isNotEmpty) {
        final batch = db.batch();
        
        // Clear local cache for this node to ensure deleted questions are actually removed locally
        batch.delete(
          DbConstants.tableQuestions, 
          where: 'subject_tag = ?', 
          whereArgs: [subjectTag]
        );

        for (final row in response) {
          final content = row['content'] as Map<String, dynamic>? ?? {};
          final text = content['text'] as String? ?? 'Empty Question';
          final options = List<String>.from(content['options'] as List? ?? []);
          final explanation = content['explanation'] as String?;
          final pyqYear = content['pyq_year'] as int?;
          final districtTag = content['district_tag'] as String?;
          
          final optA = options.isNotEmpty ? options[0] : '';
          final optB = options.length > 1 ? options[1] : '';
          final optC = options.length > 2 ? options[2] : '';
          final optD = options.length > 3 ? options[3] : '';
          
          final correctAns = row['correct_answer'] ?? 
                             row['correct_option'] ?? 
                             content['correct_option'] ?? 
                             content['correct_answer'];
          final correctIndex = _resolveCorrectOption(
            rawAnswer: correctAns,
            optA: optA,
            optB: optB,
            optC: optC,
            optD: optD,
          );

          batch.insert(
            DbConstants.tableQuestions,
            {
              'id': row['id'],
              'subject_tag': subjectTag,
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
        if (kDebugMode) {
          print('[QuestionRepository] Synced ${response.length} questions to local DB.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[QuestionRepository] Failed to fetch from Supabase (Offline Mode): $e');
      }
    }

    // 2. Fetch from local SQLite and return
    List<Map<String, dynamic>> questionMaps = await db.query(
      DbConstants.tableQuestions,
      where: 'subject_tag = ?',
      whereArgs: [subjectTag],
      limit: 25,
    );

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
            final content = row['content'] as Map<String, dynamic>? ?? {};
            final text = content['text'] as String? ?? 'Empty Question';
            final options = List<String>.from(content['options'] as List? ?? []);
            final explanation = content['explanation'] as String?;
            final pyqYear = content['pyq_year'] as int?;
            final districtTag = content['district_tag'] as String?;
            
            final optA = options.isNotEmpty ? options[0] : '';
            final optB = options.length > 1 ? options[1] : '';
            final optC = options.length > 2 ? options[2] : '';
            final optD = options.length > 3 ? options[3] : '';
            
            final correctAns = row['correct_answer'] ?? 
                               row['correct_option'] ?? 
                               content['correct_option'] ?? 
                               content['correct_answer'];
            final correctIndex = _resolveCorrectOption(
              rawAnswer: correctAns,
              optA: optA,
              optB: optB,
              optC: optC,
              optD: optD,
            );

            batch.insert(
              DbConstants.tableQuestions,
              {
                'id': row['id'],
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

  static String _resolveCorrectOption({
    required dynamic rawAnswer,
    required String optA,
    required String optB,
    required String optC,
    required String optD,
  }) {
    if (rawAnswer == null) return 'A';
    final ansStr = rawAnswer.toString().trim();
    if (ansStr.isEmpty) return 'A';

    // 1. Direct letter or number indicators (e.g. "A", "b", "(C)", "1", "option 2")
    final clean = ansStr.replaceAll(RegExp(r'^[(\[]|[)\]]$'), '').trim().toUpperCase();
    if (clean == 'A' || clean == '1' || clean == 'OPTION A' || clean == 'OPTION 1') return 'A';
    if (clean == 'B' || clean == '2' || clean == 'OPTION B' || clean == 'OPTION 2') return 'B';
    if (clean == 'C' || clean == '3' || clean == 'OPTION C' || clean == 'OPTION 3') return 'C';
    if (clean == 'D' || clean == '4' || clean == 'OPTION D' || clean == 'OPTION 4') return 'D';

    // 2. Exact match against option text
    if (ansStr == optA) return 'A';
    if (ansStr == optB) return 'B';
    if (ansStr == optC) return 'C';
    if (ansStr == optD) return 'D';

    // 3. Case-insensitive & trimmed match
    final lower = ansStr.toLowerCase();
    if (optA.isNotEmpty && lower == optA.trim().toLowerCase()) return 'A';
    if (optB.isNotEmpty && lower == optB.trim().toLowerCase()) return 'B';
    if (optC.isNotEmpty && lower == optC.trim().toLowerCase()) return 'C';
    if (optD.isNotEmpty && lower == optD.trim().toLowerCase()) return 'D';

    // 4. Fallback if option text contains the answer or vice-versa
    if (optA.isNotEmpty && optA.trim().toLowerCase().contains(lower)) return 'A';
    if (optB.isNotEmpty && optB.trim().toLowerCase().contains(lower)) return 'B';
    if (optC.isNotEmpty && optC.trim().toLowerCase().contains(lower)) return 'C';
    if (optD.isNotEmpty && optD.trim().toLowerCase().contains(lower)) return 'D';

    return 'A';
  }
}
