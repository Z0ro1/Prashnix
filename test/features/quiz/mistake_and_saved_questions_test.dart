import 'package:flutter_test/flutter_test.dart';
import 'package:prashnix/core/models/mistake_model.dart';

void main() {
  group('MistakeModel Bulletproof Persistence Tests', () {
    test('MistakeModel correctly deserializes UUID string id from Supabase/SQLite', () {
      const serverUUID = 'eb3b8acb-9f17-4351-9404-7874860dc304';
      final map = {
        'id': serverUUID,
        'question_id': 'q_101',
        'user_answer': 'B',
        'mistake_count': 2,
        'is_cleared': 0,
        'last_failed_at': '2026-10-28T12:00:00Z',
      };

      final mistake = MistakeModel.fromMap(map);
      expect(mistake.id, equals(serverUUID));
      expect(mistake.questionId, equals('q_101'));
      expect(mistake.userAnswer, equals('B'));
      expect(mistake.mistakeCount, equals(2));
      expect(mistake.isCleared, isFalse);
    });

    test('MistakeModel handles integer or null id gracefully without throwing', () {
      final mapWithInt = {
        'id': 12345,
        'question_id': 'q_102',
        'user_answer': 'A',
        'mistake_count': 1,
        'is_cleared': 1,
        'last_failed_at': '2026-10-28T12:00:00Z',
      };

      final mistake = MistakeModel.fromMap(mapWithInt);
      expect(mistake.id, equals('12345'));
      expect(mistake.isCleared, isTrue);

      final mapWithNull = {
        'id': null,
        'question_id': 'q_103',
        'user_answer': 'C',
        'mistake_count': 1,
        'is_cleared': 0,
        'last_failed_at': '2026-10-28T12:00:00Z',
      };

      final mistakeNull = MistakeModel.fromMap(mapWithNull);
      expect(mistakeNull.id, isNull);
    });

    test('toMap ensures non-null primary key id falls back to questionId', () {
      final newMistake = MistakeModel(
        questionId: 'question_uuid_999',
        userAnswer: 'D',
        lastFailedAt: '2026-10-28T12:00:00Z',
      );

      final map = newMistake.toMap();
      expect(map['id'], equals('question_uuid_999'));
      expect(map['question_id'], equals('question_uuid_999'));
      expect(map['user_answer'], equals('D'));
      expect(map['mistake_count'], equals(1));
      expect(map['is_cleared'], equals(0));
    });
  });
}
