import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prashnix/core/models/question_model.dart';
import 'package:prashnix/features/profile/presentation/providers/retry_sprint_provider.dart';

void main() {
  group('RetrySprint Deduplication & Single-Attempt Session Tests', () {
    const q1 = QuestionModel(
      id: 'q1',
      subjectTag: 'History',
      questionText: 'Who was Shivaji Maharaj?',
      optionA: 'King',
      optionB: 'Teacher',
      optionC: 'Doctor',
      optionD: 'Soldier',
      correctOption: 'A',
    );

    const q1DuplicateId = QuestionModel(
      id: 'q1',
      subjectTag: 'History',
      questionText: 'Who was Shivaji Maharaj? (copy)',
      optionA: 'King',
      optionB: 'Teacher',
      optionC: 'Doctor',
      optionD: 'Soldier',
      correctOption: 'A',
    );

    const q1DuplicateText = QuestionModel(
      id: 'q2_different_id',
      subjectTag: 'History',
      questionText: 'Who was Shivaji Maharaj?',
      optionA: 'King',
      optionB: 'Teacher',
      optionC: 'Doctor',
      optionD: 'Soldier',
      correctOption: 'A',
    );

    const q2 = QuestionModel(
      id: 'q2',
      subjectTag: 'Geography',
      questionText: 'What is the capital of Maharashtra?',
      optionA: 'Pune',
      optionB: 'Mumbai',
      optionC: 'Nagpur',
      optionD: 'Nashik',
      correctOption: 'B',
    );

    test('RetrySprintNotifier automatically filters out duplicates by ID and text in build()', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final duplicateList = [q1, q1DuplicateId, q1DuplicateText, q2];
      final state = container.read(retrySprintProvider(duplicateList));

      expect(state.questions.length, equals(2));
      expect(state.questions[0].id, equals('q1'));
      expect(state.questions[1].id, equals('q2'));
    });

    test('RetryState transitions correctly without question duplication', () {
      final state = RetryState(questions: [q1, q2], currentIndex: 0);

      expect(state.questions.length, equals(2));
      expect(state.currentIndex, equals(0));
      expect(state.status, equals(RetryStatus.unanswered));

      // After incorrect check: questions length stays 2 (no re-appending)
      final incorrectState = state.copyWith(
        status: RetryStatus.checkedIncorrect,
      );
      expect(incorrectState.questions.length, equals(2));
      expect(incorrectState.status, equals(RetryStatus.checkedIncorrect));

      // Next question advances cleanly
      final nextState = incorrectState.copyWith(
        currentIndex: 1,
        selectedOption: null,
        status: RetryStatus.unanswered,
      );
      expect(nextState.currentIndex, equals(1));
      expect(nextState.currentQuestion?.id, equals('q2'));
    });
  });
}
