import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prashnix/core/models/question_model.dart';
import 'package:prashnix/features/quiz/presentation/providers/quiz_provider.dart';

void main() {
  group('QuizProvider State Reset & Double-Navigation Prevention Tests', () {
    test('QuizState correctly defaults to unanswered and not finished', () {
      final state = QuizState();
      expect(state.status, equals(QuizStatus.unanswered));
      expect(state.isLoading, isFalse);
      expect(state.questions, isEmpty);
      expect(state.currentIndex, equals(0));
    });

    test('resetQuiz clears finished status and all residual quiz data', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(quizProvider.notifier);
      
      notifier.setQuestionsDirectly([
        const QuestionModel(
          id: 'q1',
          subjectTag: 'Math',
          questionText: 'Sample Q1',
          optionA: 'A',
          optionB: 'B',
          optionC: 'C',
          optionD: 'D',
          correctOption: 'A',
        ),
      ]);

      expect(container.read(quizProvider).status, equals(QuizStatus.unanswered));
      expect(container.read(quizProvider).questions.length, equals(1));

      // Reset
      notifier.resetQuiz();

      final resetState = container.read(quizProvider);
      expect(resetState.status, equals(QuizStatus.unanswered));
      expect(resetState.questions, isEmpty);
      expect(resetState.isLoading, isFalse);
      expect(resetState.currentIndex, equals(0));
      expect(resetState.correctAnswers, equals(0));
    });

    test('setQuestionsDirectly cleanses stale finished status from prior lesson', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(quizProvider.notifier);

      final questions = [
        const QuestionModel(
          id: 'q_test_1',
          subjectTag: 'Math',
          questionText: 'What is 2+2?',
          optionA: '4',
          optionB: '3',
          optionC: '2',
          optionD: '1',
          correctOption: 'A',
        ),
      ];

      notifier.setQuestionsDirectly(questions, nodeId: 'node_test');
      final state = container.read(quizProvider);

      expect(state.status, equals(QuizStatus.unanswered));
      expect(state.isLoading, isFalse);
      expect(state.nodeId, equals('node_test'));
      expect(state.questions.length, equals(1));
    });
  });
}
