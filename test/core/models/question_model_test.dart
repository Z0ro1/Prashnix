import 'package:flutter_test/flutter_test.dart';
import 'package:prashnix/core/models/question_model.dart';

void main() {
  group('QuestionModel displayId and displayCode Tests', () {
    test('displayCode returns displayId when present', () {
      const question = QuestionModel(
        id: '93fa4f46-6b21-4f12-9cbb-96df99388df1',
        displayId: '717270',
        subjectTag: 'history',
        questionText: 'Who founded the Maurya Empire?',
        optionA: 'Chandragupta Maurya',
        optionB: 'Ashoka',
        optionC: 'Bindusara',
        optionD: 'Harsha',
        correctOption: 'A',
      );

      expect(question.displayId, '717270');
      expect(question.displayCode, '717270');
    });

    test('displayCode falls back to first 6 chars of UUID if displayId is null or empty', () {
      const questionWithNull = QuestionModel(
        id: '93fa4f46-6b21-4f12-9cbb-96df99388df1',
        displayId: null,
        subjectTag: 'history',
        questionText: 'Test question',
        optionA: 'A',
        optionB: 'B',
        optionC: 'C',
        optionD: 'D',
        correctOption: 'A',
      );
      expect(questionWithNull.displayCode, '93FA4F');

      const questionWithEmpty = QuestionModel(
        id: 'a1b2c3d4-0000-0000-0000-000000000000',
        displayId: '   ',
        subjectTag: 'history',
        questionText: 'Test question',
        optionA: 'A',
        optionB: 'B',
        optionC: 'C',
        optionD: 'D',
        correctOption: 'A',
      );
      expect(questionWithEmpty.displayCode, 'A1B2C3');
    });

    test('fromMap and toMap correctly parse and serialize display_id', () {
      final map = {
        'id': 'uuid-1234',
        'display_id': 606713, // int from some json/sql drivers
        'subject_tag': 'geography',
        'question_text': 'What is the capital?',
        'option_a': 'A',
        'option_b': 'B',
        'option_c': 'C',
        'option_d': 'D',
        'correct_option': 'B',
      };

      final question = QuestionModel.fromMap(map);
      expect(question.displayId, '606713');
      expect(question.displayCode, '606713');

      final serialized = question.toMap();
      expect(serialized['display_id'], '606713');
      expect(serialized['id'], 'uuid-1234');
    });

    test('resolveCorrectOption correctly prioritizes numerical answers matching option text', () {
      // Critical regression test: x = 4, where option C is '4' and option D is '12'
      final resolved = QuestionModel.resolveCorrectOption(
        rawAnswer: '4',
        optA: '6',
        optB: '9',
        optC: '4',
        optD: '12',
      );
      expect(resolved, 'C'); // Under old bug, this incorrectly returned 'D'

      // Critical regression test: cube root of 27 = 3, where option D is '3'
      final resolvedCube = QuestionModel.resolveCorrectOption(
        rawAnswer: '3',
        optA: '9',
        optB: '4',
        optC: '5',
        optD: '3',
      );
      expect(resolvedCube, 'D'); // Under old bug, this incorrectly returned 'C'

      // Critical regression test: y = 2, where option C is '2' and option B is '8'
      final resolvedY = QuestionModel.resolveCorrectOption(
        rawAnswer: '2',
        optA: '5',
        optB: '8',
        optC: '2',
        optD: '4',
      );
      expect(resolvedY, 'C'); // Under old bug, this incorrectly returned 'B'
    });

    test('resolveCorrectOption handles Marathi text options, whitespace and numerals', () {
      // Exact Marathi text match with surrounding whitespace
      final resolvedMarathi = QuestionModel.resolveCorrectOption(
        rawAnswer: '   मुंबई  ',
        optA: 'पुणे',
        optB: 'नागपूर',
        optC: 'मुंबई',
        optD: 'नाशिक',
      );
      expect(resolvedMarathi, 'C');

      // Marathi option indicator 'पर्याय ब'
      final resolvedIndicator = QuestionModel.resolveCorrectOption(
        rawAnswer: 'पर्याय ब',
        optA: '10',
        optB: '20',
        optC: '30',
        optD: '40',
      );
      expect(resolvedIndicator, 'B');

      // Numeric 1-based index when options are not numbers
      final resolvedIndex = QuestionModel.resolveCorrectOption(
        rawAnswer: '2',
        optA: 'पुणे',
        optB: 'मुंबई',
        optC: 'नागपूर',
        optD: 'नाशिक',
      );
      expect(resolvedIndex, 'B');
    });

    test('isAnswerCorrect accurately accepts both letter labels and option texts', () {
      const q = QuestionModel(
        id: 'q1',
        subjectTag: 'math',
        questionText: '27 चे घनमूळ किती?',
        optionA: '9',
        optionB: '4',
        optionC: '5',
        optionD: '3',
        correctOption: 'D',
      );

      // Letter comparisons
      expect(q.isAnswerCorrect('D'), isTrue);
      expect(q.isAnswerCorrect('d'), isTrue);
      expect(q.isAnswerCorrect('A'), isFalse);
      expect(q.isAnswerCorrect('C'), isFalse);

      // Text comparisons
      expect(q.isAnswerCorrect('3'), isTrue);
      expect(q.isAnswerCorrect('  3  '), isTrue);
      expect(q.isAnswerCorrect('9'), isFalse);
      expect(q.isAnswerCorrect('5'), isFalse);
      expect(q.isAnswerCorrect(null), isFalse);
      expect(q.isAnswerCorrect(''), isFalse);

      expect(q.correctOptionText, '3');
    });
  });
}
