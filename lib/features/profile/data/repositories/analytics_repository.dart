import '../../../../core/database/database_service.dart';
import '../../../../core/database/db_constants.dart';
import '../../../../core/models/question_model.dart';
import '../../domain/models/subject_stat_model.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

class AnalyticsRepository {
  final DatabaseService _dbService;

  AnalyticsRepository({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService();

  /// Logs an individual question attempt (correct or incorrect) atomically to local SQLite.
  Future<void> logAttempt({
    required String questionId,
    required String subjectTag,
    String? subtopicTag,
    required bool isCorrect,
    DateTime? timestamp,
  }) async {
    try {
      final db = await _dbService.database;
      final now = (timestamp ?? DateTime.now()).toIso8601String();

      await db.insert(
        DbConstants.tableQuestionAttempts,
        {
          'question_id': questionId,
          'subject_tag': subjectTag.trim(),
          'subtopic_tag': subtopicTag?.trim(),
          'is_correct': isCorrect ? 1 : 0,
          'attempted_at': now,
        },
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  /// Retrieves high-speed aggregated subject & subtopic mastery statistics.
  Future<OverallAnalyticsSummary> getOverallSummary() async {
    final db = await _dbService.database;

    // Fast aggregation grouped by subject and subtopic
    final List<Map<String, dynamic>> rawRows = await db.rawQuery('''
      SELECT 
        a.subject_tag,
        a.subtopic_tag,
        COUNT(a.id) AS total_count,
        SUM(CASE WHEN a.is_correct = 1 THEN 1 ELSE 0 END) AS correct_count,
        SUM(CASE WHEN a.is_correct = 0 THEN 1 ELSE 0 END) AS incorrect_count
      FROM ${DbConstants.tableQuestionAttempts} a
      GROUP BY a.subject_tag, a.subtopic_tag
    ''');

    if (rawRows.isEmpty) {
      return const OverallAnalyticsSummary();
    }

    int overallTotal = 0;
    int overallCorrect = 0;
    int overallIncorrect = 0;

    // Group rows by normalized subject name
    final Map<String, List<Map<String, dynamic>>> subjectGroupMap = {};

    for (final row in rawRows) {
      final rawSubject = (row['subject_tag'] as String?)?.trim() ?? 'General';
      final total = (row['total_count'] as num?)?.toInt() ?? 0;
      final correct = (row['correct_count'] as num?)?.toInt() ?? 0;
      final incorrect = (row['incorrect_count'] as num?)?.toInt() ?? 0;

      overallTotal += total;
      overallCorrect += correct;
      overallIncorrect += incorrect;

      subjectGroupMap.putIfAbsent(rawSubject, () => []).add(row);
    }

    final List<SubjectStatModel> subjectStats = [];

    for (final entry in subjectGroupMap.entries) {
      final rawSubject = entry.key;
      final rows = entry.value;

      int subTotal = 0;
      int subCorrect = 0;
      int subIncorrect = 0;

      final List<SubtopicStatModel> subtopics = [];

      for (final r in rows) {
        final total = (r['total_count'] as num?)?.toInt() ?? 0;
        final correct = (r['correct_count'] as num?)?.toInt() ?? 0;
        final incorrect = (r['incorrect_count'] as num?)?.toInt() ?? 0;
        final rawSubtopic = r['subtopic_tag'] as String?;

        subTotal += total;
        subCorrect += correct;
        subIncorrect += incorrect;

        if (rawSubtopic != null && rawSubtopic.trim().isNotEmpty) {
          final double subtopicPct = total > 0 ? (correct / total) * 100.0 : 0.0;
          subtopics.add(
            SubtopicStatModel(
              subtopicName: rawSubtopic.trim(),
              totalAttempts: total,
              correctCount: correct,
              incorrectCount: incorrect,
              accuracyPct: subtopicPct,
              masteryLevel: SubtopicStatModel.calculateMastery(total, subtopicPct),
            ),
          );
        }
      }

      final double subjectAccuracy = subTotal > 0 ? (subCorrect / subTotal) * 100.0 : 0.0;

      // Normalise subject title for clean Marathi display
      final dummyQuestion = QuestionModel(
        subjectTag: rawSubject,
        questionText: '',
        optionA: '',
        optionB: '',
        optionC: '',
        optionD: '',
        correctOption: 'A',
      );
      final formattedName = dummyQuestion.formattedSubject;

      // Sort subtopics by lowest accuracy first (weakest subtopics on top)
      subtopics.sort((a, b) => a.accuracyPct.compareTo(b.accuracyPct));

      subjectStats.add(
        SubjectStatModel(
          rawSubjectTag: rawSubject,
          formattedSubjectName: formattedName,
          totalAttempts: subTotal,
          correctCount: subCorrect,
          incorrectCount: subIncorrect,
          accuracyPct: subjectAccuracy,
          masteryLevel: SubjectStatModel.calculateMastery(subTotal, subjectAccuracy),
          subtopics: subtopics,
        ),
      );
    }

    // Sort subjects: Weakest subjects (<60%) first so students see critical areas immediately
    subjectStats.sort((a, b) {
      if (a.masteryLevel == SubjectMasteryLevel.weak && b.masteryLevel != SubjectMasteryLevel.weak) {
        return -1;
      }
      if (b.masteryLevel == SubjectMasteryLevel.weak && a.masteryLevel != SubjectMasteryLevel.weak) {
        return 1;
      }
      return a.accuracyPct.compareTo(b.accuracyPct);
    });

    final double overallPct = overallTotal > 0 ? (overallCorrect / overallTotal) * 100.0 : 0.0;

    return OverallAnalyticsSummary(
      totalAttempts: overallTotal,
      totalCorrect: overallCorrect,
      totalIncorrect: overallIncorrect,
      overallAccuracyPct: overallPct,
      subjectStats: subjectStats,
    );
  }

  /// Fetches questions for a targeted drill in a weak subject, prioritizing past failed questions.
  Future<List<QuestionModel>> getQuestionsForTargetedDrill(
    String rawSubjectTag, {
    int limit = 10,
  }) async {
    final db = await _dbService.database;

    // 1. Try fetching questions in this subject that the user previously failed
    final List<Map<String, dynamic>> failedRows = await db.rawQuery('''
      SELECT q.* FROM ${DbConstants.tableQuestions} q
      INNER JOIN ${DbConstants.tableMistakes} m ON q.id = m.question_id
      WHERE q.subject_tag = ? AND m.is_cleared = 0
      ORDER BY m.mistake_count DESC, m.last_failed_at DESC
      LIMIT ?
    ''', [rawSubjectTag, limit]);

    final List<QuestionModel> result = failedRows.map((m) => QuestionModel.fromMap(m)).toList();

    // 2. If fewer than limit, fill up with unattempted/random questions in the same subject
    if (result.length < limit) {
      final existingIds = result.map((q) => q.id).whereType<String>().toList();
      final needed = limit - result.length;

      String whereClause = 'subject_tag = ?';
      final whereArgs = <dynamic>[rawSubjectTag];

      if (existingIds.isNotEmpty) {
        final placeholders = List.filled(existingIds.length, '?').join(',');
        whereClause += ' AND id NOT IN ($placeholders)';
        whereArgs.addAll(existingIds);
      }

      final List<Map<String, dynamic>> fillRows = await db.query(
        DbConstants.tableQuestions,
        where: whereClause,
        whereArgs: whereArgs,
        limit: needed,
      );

      result.addAll(fillRows.map((m) => QuestionModel.fromMap(m)));
    }

    return result;
  }
}

