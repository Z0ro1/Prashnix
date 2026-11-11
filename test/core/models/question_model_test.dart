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
  });
}
