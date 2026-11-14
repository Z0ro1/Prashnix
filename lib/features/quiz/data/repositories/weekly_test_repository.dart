import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/models/question_model.dart';
import '../../../../core/models/weekly_test_model.dart';
import 'question_repository.dart';

class WeeklyTestRepository {
  final QuestionRepository _questionRepo;

  WeeklyTestRepository({QuestionRepository? questionRepo})
      : _questionRepo = questionRepo ?? QuestionRepository();

  /// Fetches the current or upcoming Weekly Test for the given exam type.
  Future<WeeklyTestModel?> getActiveWeeklyTest({String? examType}) async {
    // 1. Try Supabase dedicated weekly_tests table
    try {
      var query = SupabaseConfig.client
          .from('weekly_tests')
          .select('*')
          .eq('is_active', true);

      if (examType != null && examType.isNotEmpty) {
        query = query.eq('exam_type', examType);
      }

      final response = await query.order('scheduled_date', ascending: true).limit(1);

      if (response.isNotEmpty) {
        final test = WeeklyTestModel.fromMap(response.first);
        if (test.questions.isNotEmpty) {
          return test;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[WeeklyTestRepository] weekly_tests table query failed, trying nodes: $e');
      }
    }

    // 2. Fallback: Try Supabase nodes with node_type = 'weekly_test'
    try {
      final response = await SupabaseConfig.client
          .from('nodes')
          .select('*, lessons(*, questions(*))')
          .eq('node_type', 'weekly_test')
          .limit(5);

      if (response.isNotEmpty) {
        for (final node in response) {
          Map<String, dynamic> meta = {};
          if (node['info_note'] != null && node['info_note'].toString().startsWith('{')) {
            try {
              meta = jsonDecode(node['info_note']);
            } catch (_) {}
          }

          final nodeExam = meta['exam_type'] ?? 'Police Bharti';
          if (examType != null && examType.isNotEmpty && nodeExam != examType) {
            continue;
          }

          final List<QuestionModel> nodeQuestions = [];
          final lessons = node['lessons'] as List? ?? [];
          for (final lesson in lessons) {
            final questions = lesson['questions'] as List? ?? [];
            for (final q in questions) {
              final content = q['content'] as Map<String, dynamic>? ?? {};
              final opts = List<String>.from(content['options'] as List? ?? []);
              final optA = opts.isNotEmpty ? opts[0] : '';
              final optB = opts.length > 1 ? opts[1] : '';
              final optC = opts.length > 2 ? opts[2] : '';
              final optD = opts.length > 3 ? opts[3] : '';
              final resolvedCorrect = QuestionModel.resolveCorrectOption(
                rawAnswer: q['correct_answer'] ?? q['correct_option'],
                optA: optA,
                optB: optB,
                optC: optC,
                optD: optD,
              );

              nodeQuestions.add(QuestionModel(
                id: q['id']?.toString(),
                subjectTag: 'weekly_test',
                subtopicTag: nodeExam,
                questionText: content['text'] ?? '',
                optionA: optA,
                optionB: optB,
                optionC: optC,
                optionD: optD,
                correctOption: resolvedCorrect,
                explanation: content['explanation'],
                pyqYear: content['pyq_year'] is int ? content['pyq_year'] : null,
                districtTag: content['district_tag']?.toString(),
              ));
            }
          }

          if (nodeQuestions.isNotEmpty) {
            final scheduled = meta['scheduled_date'] != null
                ? DateTime.tryParse(meta['scheduled_date']) ?? DateTime.now()
                : DateTime.now();

            return WeeklyTestModel(
              id: node['id'],
              title: node['title'] ?? 'साप्ताहिक महासराव १०० प्रश्न चाचणी',
              examType: nodeExam,
              scheduledDate: scheduled,
              startTime: meta['start_time'],
              durationMinutes: meta['duration_minutes'] ?? 90,
              totalMarks: meta['total_marks'] ?? 100,
              totalQuestions: nodeQuestions.length,
              questions: nodeQuestions,
              isActive: meta['is_active'] ?? true,
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[WeeklyTestRepository] nodes fallback failed: $e');
      }
    }

    // 3. Fallback: Build an offline 100-question practice test from local SQLite
    try {
      final localQuestions = await _questionRepo.getWeeklyTestQuestions(100, 10);
      if (localQuestions.isNotEmpty) {
        final now = DateTime.now();
        final diff = (7 - now.weekday) % 7;
        final daysToAdd = diff == 0 ? 7 : diff;
        var nextSunday = now.add(Duration(days: daysToAdd));
        nextSunday = DateTime(nextSunday.year, nextSunday.month, nextSunday.day, 12, 0, 0);

        return WeeklyTestModel(
          id: 'local_weekly_test_${(examType ?? 'Police Bharti').replaceAll(' ', '_')}_${nextSunday.year}_${nextSunday.month}_${nextSunday.day}',
          title: 'महाराष्ट्र पोलीस भरती १००-प्रश्न साप्ताहिक चाचणी',
          examType: examType ?? 'Police Bharti',
          scheduledDate: nextSunday,
          startTime: '12:00',
          durationMinutes: 90,
          totalMarks: 100,
          totalQuestions: localQuestions.length,
          questions: localQuestions,
          isActive: true,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('[WeeklyTestRepository] local fallback failed: $e');
      }
    }

    return null;
  }
}
