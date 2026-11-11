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
import '../../data/repositories/weekly_test_repository.dart';
import '../../../gamification/presentation/providers/heart_economy_provider.dart';
import '../../../gamification/presentation/providers/streak_provider.dart';

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
  final int initialQuestionCount;
  final int mistakesCount;
  final Set<String> awardedQuestionKeys;

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
    this.initialQuestionCount = 0,
    this.mistakesCount = 0,
    this.awardedQuestionKeys = const {},
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
    int? initialQuestionCount,
    int? mistakesCount,
    Set<String>? awardedQuestionKeys,
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
      initialQuestionCount: initialQuestionCount ?? this.initialQuestionCount,
      mistakesCount: mistakesCount ?? this.mistakesCount,
      awardedQuestionKeys: awardedQuestionKeys ?? this.awardedQuestionKeys,
    );
  }
}

@Riverpod(keepAlive: true)
class QuizNotifier extends _$QuizNotifier {
  bool _isCompleting = false;

  @override
  QuizState build() {
    _isCompleting = false;
    return QuizState(questions: [], isLoading: true);
  }

  void setQuestionsDirectly(List<QuestionModel> questions, {String nodeId = 'weekly_test'}) {
    _isCompleting = false;
    state = state.copyWith(
      questions: questions,
      isLoading: false,
      nodeId: nodeId,
      currentIndex: 0,
      clearSelectedOption: true,
      status: QuizStatus.unanswered,
      correctAnswers: 0,
      baseXpEarned: 0,
      streakIncrement: 0,
      initialQuestionCount: questions.length,
      mistakesCount: 0,
      awardedQuestionKeys: const {},
    );
  }

  Future<void> loadQuestionsForNode(String nodeId, {int lessonIndex = 0}) async {
    _isCompleting = false;
    state = state.copyWith(isLoading: true, nodeId: nodeId);
    try {
      final repo = QuestionRepository();
      List<QuestionModel> newQuestions = [];
      if (nodeId.startsWith('weekly_test')) {
        String? examType;
        if (nodeId.startsWith('weekly_test_')) {
          examType = nodeId.replaceFirst('weekly_test_', '');
        }
        final weeklyRepo = WeeklyTestRepository(questionRepo: repo);
        final weeklyTest = await weeklyRepo.getActiveWeeklyTest(examType: examType);
        if (weeklyTest != null && weeklyTest.questions.isNotEmpty) {
          newQuestions = weeklyTest.questions;
        } else {
          final ProgressRepository progressRepo = ProgressRepository();
          final currentLevelStr = await progressRepo.getLocalState('highest_unlocked_level') ?? '0';
          int currentLevel = int.tryParse(currentLevelStr) ?? 0;
          newQuestions = await repo.getWeeklyTestQuestions(100, currentLevel);
        }
      } else {
        newQuestions = await repo.getQuestionsByNode(nodeId, lessonIndex: lessonIndex);
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
        initialQuestionCount: newQuestions.length,
        mistakesCount: 0,
        awardedQuestionKeys: const {},
      );
    } catch (e) {
      state = state.copyWith(
        questions: [],
        isLoading: false,
        currentIndex: 0,
        clearSelectedOption: true,
        status: QuizStatus.unanswered,
        correctAnswers: 0,
        baseXpEarned: 0,
        streakIncrement: 0,
        initialQuestionCount: 0,
        mistakesCount: 0,
        awardedQuestionKeys: const {},
      );
    }
  }

  void selectOption(String optionIndex) {
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

      // Security check: Only award +2 XP once per unique question to prevent retry farming
      final questionKey = question.id ?? 'q_${state.currentIndex}';
      final maxAllowedQuestionXp = state.initialQuestionCount > 0 ? state.initialQuestionCount * 2 : 20;
      final isNewQuestion = !state.awardedQuestionKeys.contains(questionKey);
      final canAwardXp = isNewQuestion && (state.baseXpEarned + 2 <= maxAllowedQuestionXp);

      final updatedAwardedKeys = Set<String>.from(state.awardedQuestionKeys)..add(questionKey);
      final updatedXp = canAwardXp ? state.baseXpEarned + 2 : state.baseXpEarned;

      state = state.copyWith(
        status: QuizStatus.checkedCorrect,
        correctAnswers: state.correctAnswers + 1,
        baseXpEarned: updatedXp,
        awardedQuestionKeys: updatedAwardedKeys,
      );
    } else {
      if (ref.read(settingsProvider).hapticsEnabled) {
        HapticFeedback.vibrate();
      }

      // Log mistake to MistakeRepository
      if (question.id != null) {
        final MistakeRepository mistakeRepo = MistakeRepository();
        mistakeRepo.logMistake(question.id!, state.selectedOption!);
      }

      // Endless Retry: Re-append the failed question to the end of the queue
      final updatedQuestions = List<QuestionModel>.from(state.questions)..add(question);
      state = state.copyWith(
        status: QuizStatus.checkedIncorrect,
        questions: updatedQuestions,
        mistakesCount: state.mistakesCount + 1,
      );
    }
  }

  void nextQuestion() {
    // Double-tap race condition guard
    if (state.status == QuizStatus.finished || _isCompleting) return;

    if (state.currentIndex < state.questions.length - 1) {
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        clearSelectedOption: true,
        status: QuizStatus.unanswered,
      );
    } else {
      _isCompleting = true;
      final isWeeklyTest = state.nodeId?.startsWith('weekly_test') ?? false;

      int completionBonus = 0;
      if (isWeeklyTest) {
        // 100-Question Championship Test completion reward (+1000 XP & Heart Refill)
        completionBonus = 1000;
        ref.read(heartEconomyProvider.notifier).refillFull();
      } else if (state.mistakesCount == 0) {
        // Perfect Lesson bonus (0 mistakes on first try): +100 XP
        if (ref.read(settingsProvider).hapticsEnabled) {
          HapticFeedback.heavyImpact();
        }
        completionBonus = 100;
      } else {
        // Standard completion reward with retries: +30 XP
        if (ref.read(settingsProvider).hapticsEnabled) {
          HapticFeedback.mediumImpact();
        }
        completionBonus = 30;
      }

      final totalXpForLesson = state.baseXpEarned + completionBonus;
      state = state.copyWith(baseXpEarned: totalXpForLesson);
      
      // Update User Store XP exactly once
      ref.read(userStoreProvider.notifier).addXp(totalXpForLesson);
      
      // Update streak and record daily activity
      ref.read(streakProvider.notifier).recordDailyActivity(xpEarned: totalXpForLesson);
      
      // Tell SkillTreeNotifier to progress the fractional lesson
      if (state.nodeId != null) {
        ref.read(skillTreeProvider.notifier).completeLesson(state.nodeId!);
      }
      
      // Mark lesson complete and trigger cloud sync
      _completeLessonAndSync();

      state = state.copyWith(
        status: QuizStatus.finished,
        streakIncrement: 1,
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
