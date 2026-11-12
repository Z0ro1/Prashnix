import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/services.dart';
import 'settings_provider.dart';
import '../../../../core/models/question_model.dart';
import '../../../gamification/presentation/providers/heart_economy_provider.dart';
import '../../../quiz/data/repositories/mistake_repository.dart';
import 'mistake_provider.dart';
import '../../../../core/state/user_state.dart';

part 'retry_sprint_provider.g.dart';

enum RetryStatus { unanswered, selected, checkedCorrect, checkedIncorrect, finished }

class RetryState {
  final List<QuestionModel> questions;
  final int currentIndex;
  final String? selectedOption;
  final RetryStatus status;
  final int clearedCount;

  RetryState({
    this.questions = const [],
    this.currentIndex = 0,
    this.selectedOption,
    this.status = RetryStatus.unanswered,
    this.clearedCount = 0,
  });

  QuestionModel? get currentQuestion {
    if (questions.isEmpty || currentIndex >= questions.length) return null;
    return questions[currentIndex];
  }

  RetryState copyWith({
    List<QuestionModel>? questions,
    int? currentIndex,
    String? selectedOption,
    RetryStatus? status,
    int? clearedCount,
  }) {
    return RetryState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedOption: selectedOption ?? this.selectedOption,
      status: status ?? this.status,
      clearedCount: clearedCount ?? this.clearedCount,
    );
  }
}

@riverpod
class RetrySprintNotifier extends _$RetrySprintNotifier {
  @override
  RetryState build(List<QuestionModel> initialQuestions) {
    // Deduplicate initial questions by both ID and questionText so every question is unique
    final uniqueQuestions = <QuestionModel>[];
    final seenIds = <String>{};
    final seenTexts = <String>{};

    for (final q in initialQuestions) {
      final idKey = q.id ?? '';
      final textKey = q.questionText.trim().toLowerCase();

      if (idKey.isNotEmpty && seenIds.contains(idKey)) continue;
      if (textKey.isNotEmpty && seenTexts.contains(textKey)) continue;

      if (idKey.isNotEmpty) seenIds.add(idKey);
      if (textKey.isNotEmpty) seenTexts.add(textKey);
      uniqueQuestions.add(q);
    }

    return RetryState(questions: uniqueQuestions);
  }

  void selectOption(String optionIndex) {
    if (state.status == RetryStatus.unanswered || state.status == RetryStatus.selected) {
      if (ref.read(settingsProvider).hapticsEnabled) {
        HapticFeedback.selectionClick();
      }
      state = state.copyWith(
        selectedOption: optionIndex,
        status: RetryStatus.selected,
      );
    }
  }

  void checkAnswer() {
    if (state.status != RetryStatus.selected) return;

    final question = state.currentQuestion;
    if (question == null) return;

    final isCorrect = state.selectedOption == question.correctOption;

    if (isCorrect) {
      if (ref.read(settingsProvider).hapticsEnabled) {
        HapticFeedback.mediumImpact();
      }
      // Clear mistake and award +1 Heart immediately
      if (question.id != null) {
        final MistakeRepository repo = MistakeRepository();
        repo.markMistakeCleared(question.id!);
        ref.read(heartEconomyProvider.notifier).addHearts(1);
      }

      state = state.copyWith(
        status: RetryStatus.checkedCorrect,
        clearedCount: state.clearedCount + 1,
      );
    } else {
      if (ref.read(settingsProvider).hapticsEnabled) {
        HapticFeedback.vibrate(); // Long buzz for incorrect answer
      }
      // User failed again. Increment mistake_count in repo. No heart deduction.
      if (question.id != null) {
        final MistakeRepository repo = MistakeRepository();
        repo.logMistake(question.id!, state.selectedOption!);
      }

      // Do NOT re-append to the end of the sprint session to avoid repeated questions.
      // The mistake remains uncleared in the Mistake Bank for future review.
      state = state.copyWith(
        status: RetryStatus.checkedIncorrect,
      );
    }
  }

  void nextQuestion() {
    if (state.status == RetryStatus.finished) return;

    if (state.currentIndex < state.questions.length - 1) {
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        selectedOption: null,
        status: RetryStatus.unanswered,
      );
    } else {
      // Finished
      final earnedXp = state.clearedCount * 2;
      if (earnedXp > 0) {
        ref.read(userStoreProvider.notifier).addXp(earnedXp);
      }

      // Refresh the mistake bank properly
      ref.read(mistakeProvider.notifier).loadMistakes();
      
      state = state.copyWith(status: RetryStatus.finished);
    }
  }
}
