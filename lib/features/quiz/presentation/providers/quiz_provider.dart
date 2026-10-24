import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/models/question_model.dart';
import '../../../profile/presentation/providers/settings_provider.dart';
import '../../data/repositories/mistake_repository.dart';
import '../../../profile/data/repositories/progress_repository.dart';
import '../../data/repositories/question_repository.dart';
import '../../../../core/state/user_state.dart';
import '../../../skill_tree/presentation/providers/skill_tree_provider.dart';
import '../../../../core/config/supabase_config.dart';

part 'quiz_provider.g.dart';

enum QuizStatus { unanswered, selected, checkedCorrect, checkedIncorrect, finished, outOfHearts }

class QuizState {
  final List<QuestionModel> questions;
  final int currentIndex;
  final String? selectedOption;
  final QuizStatus status;
  final int correctAnswers;
  final int baseXpEarned;
  final int streakIncrement;
  final bool isLoading;
  final String? nodeId;

  QuizState({
    this.questions = const [],
    this.currentIndex = 0,
    this.selectedOption,
    this.status = QuizStatus.unanswered,
    this.correctAnswers = 0,
    this.baseXpEarned = 0,
    this.streakIncrement = 0,
    this.isLoading = false,
    this.nodeId,
  });

  QuestionModel? get currentQuestion {
    if (questions.isEmpty || currentIndex >= questions.length) return null;
    return questions[currentIndex];
  }

  QuizState copyWith({
    List<QuestionModel>? questions,
    int? currentIndex,
    String? selectedOption,
    bool clearSelectedOption = false,
    QuizStatus? status,
    int? correctAnswers,
    int? baseXpEarned,
    int? streakIncrement,
    bool? isLoading,
    String? nodeId,
  }) {
    return QuizState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedOption: clearSelectedOption ? null : (selectedOption ?? this.selectedOption),
      status: status ?? this.status,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      baseXpEarned: baseXpEarned ?? this.baseXpEarned,
      streakIncrement: streakIncrement ?? this.streakIncrement,
      isLoading: isLoading ?? this.isLoading,
      nodeId: nodeId ?? this.nodeId,
    );
  }
}

@Riverpod(keepAlive: true)
class QuizNotifier extends _$QuizNotifier {
  @override
  QuizState build() {
    return QuizState(questions: [], isLoading: true);
  }

  Future<void> loadQuestionsForNode(String nodeId) async {
    state = state.copyWith(isLoading: true, nodeId: nodeId);
    try {
      final repo = QuestionRepository();
      List<QuestionModel> newQuestions = [];
      if (nodeId == 'weekly_test') {
        final ProgressRepository progressRepo = ProgressRepository();
        final currentLevelStr = await progressRepo.getLocalState('highest_unlocked_level') ?? '0';
        int currentLevel = int.tryParse(currentLevelStr) ?? 0;
        newQuestions = await repo.getWeeklyTestQuestions(100, currentLevel);
      } else {
        newQuestions = await repo.getQuestionsByNode(nodeId);
      }
      
      state = state.copyWith(
        questions: newQuestions,
        isLoading: false,
        currentIndex: 0,
        clearSelectedOption: true,
        status: QuizStatus.unanswered,
        correctAnswers: 0,
        baseXpEarned: 0,
        streakIncrement: 0,
      );
    } catch (e) {
      print('Error loading questions: $e');
      state = state.copyWith(
        questions: [],
        isLoading: false,
        currentIndex: 0,
        clearSelectedOption: true,
        status: QuizStatus.unanswered,
        correctAnswers: 0,
        baseXpEarned: 0,
        streakIncrement: 0,
      );
    }
  }

  void selectOption(String optionIndex) {
    // optionIndex like 'A', 'B', 'C', 'D'
    if (state.status == QuizStatus.unanswered || state.status == QuizStatus.selected) {
      if (ref.read(settingsProvider).hapticsEnabled) {
        HapticFeedback.selectionClick();
      }
      state = state.copyWith(
        selectedOption: optionIndex,
        status: QuizStatus.selected,
      );
    }
  }

  void checkAnswer() {
    if (state.status != QuizStatus.selected) return;

    final question = state.currentQuestion;
    if (question == null) return;

    final isCorrect = state.selectedOption == question.correctOption;

    if (isCorrect) {
      if (ref.read(settingsProvider).hapticsEnabled) {
        HapticFeedback.mediumImpact();
      }
      state = state.copyWith(
        status: QuizStatus.checkedCorrect,
        correctAnswers: state.correctAnswers + 1,
        baseXpEarned: state.baseXpEarned + 10, // 10 XP per correct answer
      );
    } else {
      if (ref.read(settingsProvider).hapticsEnabled) {
        HapticFeedback.vibrate(); // Long buzz for incorrect answer
      }
      state = state.copyWith(
        status: QuizStatus.checkedIncorrect,
      );
      
      // Log mistake to MistakeRepository
      if (question.id != null) {
        final MistakeRepository mistakeRepo = MistakeRepository();
        mistakeRepo.logMistake(question.id!, state.selectedOption!);
      }

      // Deduct heart
      ref.read(userStoreProvider.notifier).useHeart();
      
      // Endless Retry: Re-append the failed question to the end of the queue
      final updatedQuestions = List<QuestionModel>.from(state.questions)..add(question);
      state = state.copyWith(questions: updatedQuestions);
    }
  }

  void nextQuestion() {
    if (ref.read(userStoreProvider).heartCount <= 0) {
      state = state.copyWith(status: QuizStatus.outOfHearts);
      return;
    }

    if (state.currentIndex < state.questions.length - 1) {
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        clearSelectedOption: true,
        status: QuizStatus.unanswered,
      );
    } else {
      // Quiz finished
      if (state.correctAnswers == state.questions.length) { // Dynamic perfect score base
        // Perfect bonus
        if (ref.read(settingsProvider).hapticsEnabled) {
          HapticFeedback.heavyImpact();
        }
        state = state.copyWith(baseXpEarned: state.baseXpEarned + 50);
      } else {
        if (ref.read(settingsProvider).hapticsEnabled) {
          HapticFeedback.mediumImpact();
        }
      }
      
      // Update User Store XP
      ref.read(userStoreProvider.notifier).addXp(state.baseXpEarned);
      
      // Tell SkillTreeNotifier to progress the fractional lesson
      if (state.nodeId != null) {
        ref.read(skillTreeProvider.notifier).completeLesson(state.nodeId!);
      }
      
      // Mark lesson complete and trigger cloud sync
      _completeLessonAndSync();

      state = state.copyWith(
        status: QuizStatus.finished,
        streakIncrement: 1, // Increase streak by 1 for completing a lesson
      );
    }
  }

  Future<void> _completeLessonAndSync() async {
    try {
      final ProgressRepository progressRepo = ProgressRepository();
      
      // Get current level
      final currentLevelStr = await progressRepo.getLocalState('highest_unlocked_level') ?? '0';
      int currentLevel = int.tryParse(currentLevelStr) ?? 0;
      
      // Increment
      currentLevel++;
      await progressRepo.saveLocalState('highest_unlocked_level', currentLevel.toString());

      // Trigger cloud sync
      final supabase = SupabaseConfig.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        await supabase.from('profiles').update({'weekly_test_level': currentLevel}).eq('id', userId);
      }
    } catch (e) {
      // Ignore errors for now
    }
  }
}
