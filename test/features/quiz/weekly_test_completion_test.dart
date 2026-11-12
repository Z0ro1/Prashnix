import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prashnix/core/models/question_model.dart';
import 'package:prashnix/core/models/weekly_test_model.dart';
import 'package:prashnix/features/quiz/presentation/providers/quiz_provider.dart';

void main() {
  group('Weekly Test Completion & Anti-Exploit Tests', () {
    test('WeeklyTestModel creates with date and unique ID per Sunday', () {
      final now = DateTime(2026, 11, 15, 12, 0);
      final model = WeeklyTestModel(
        id: 'local_weekly_test_Police_Bharti_2026_11_15',
        title: 'साप्ताहिक चाचणी',
        examType: 'Police Bharti',
        scheduledDate: now,
        questions: const [
          QuestionModel(
            id: 'q1',
            subjectTag: 'weekly_test',
            questionText: 'Test Q1',
            optionA: '1',
            optionB: '2',
            optionC: '3',
            optionD: '4',
            correctOption: 'A',
          ),
        ],
      );

      expect(model.id, equals('local_weekly_test_Police_Bharti_2026_11_15'));
      expect(model.questions.length, equals(1));
      expect(model.isActive, isTrue);
    });

    test('QuizNotifier does not complete or award bonus when questions are empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(quizProvider.notifier);
      notifier.resetQuiz();

      expect(container.read(quizProvider).questions, isEmpty);

      // Attempt nextQuestion on empty questions
      notifier.nextQuestion();

      expect(container.read(quizProvider).status, isNot(equals(QuizStatus.finished)));
      expect(container.read(quizProvider).baseXpEarned, equals(0));
    });

    test('QuizNotifier setQuestionsDirectly sets weekly_test nodeId properly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(quizProvider.notifier);
      final questions = [
        const QuestionModel(
          id: 'q1',
          subjectTag: 'weekly_test',
          questionText: 'Test Q1',
          optionA: '1',
          optionB: '2',
          optionC: '3',
          optionD: '4',
          correctOption: 'A',
        ),
        const QuestionModel(
          id: 'q2',
          subjectTag: 'weekly_test',
          questionText: 'Test Q2',
          optionA: 'A',
          optionB: 'B',
          optionC: 'C',
          optionD: 'D',
          correctOption: 'B',
        ),
      ];

      notifier.setQuestionsDirectly(questions, nodeId: 'weekly_test_test123');

      final state = container.read(quizProvider);
      expect(state.nodeId, equals('weekly_test_test123'));
      expect(state.questions.length, equals(2));
      expect(state.currentIndex, equals(0));
      expect(state.status, equals(QuizStatus.unanswered));
    });
  });
}

