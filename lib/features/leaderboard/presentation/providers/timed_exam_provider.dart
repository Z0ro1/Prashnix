import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/models/question_model.dart';
import 'package:flutter/services.dart';
import '../../../profile/presentation/providers/settings_provider.dart';

part 'timed_exam_provider.g.dart';

enum TimedExamStatus { notStarted, running, autoSubmitted, manuallySubmitted }

class TimedExamState {
  final List<QuestionModel> questions;
  final Map<int, String> answers; // questionIndex -> selectedOption
  final int currentIndex;
  final TimedExamStatus status;
  final int timeRemainingSeconds;

  TimedExamState({
    this.questions = const [],
    this.answers = const {},
    this.currentIndex = 0,
    this.status = TimedExamStatus.notStarted,
    this.timeRemainingSeconds = 90 * 60, // 90 minutes
  });

  QuestionModel? get currentQuestion {
    if (questions.isEmpty || currentIndex >= questions.length) return null;
    return questions[currentIndex];
  }

  String get timeFormatted {
    final h = (timeRemainingSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((timeRemainingSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (timeRemainingSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  bool get isTimeCritical => timeRemainingSeconds < 10 * 60; // Under 10 minutes

  int get correctCount {
    int count = 0;
    for (int i = 0; i < questions.length; i++) {
      if (answers[i] == questions[i].correctOption) {
        count++;
      }
    }
    return count;
  }

  int get answeredCount => answers.length;

  TimedExamState copyWith({
    List<QuestionModel>? questions,
    Map<int, String>? answers,
    int? currentIndex,
    TimedExamStatus? status,
    int? timeRemainingSeconds,
  }) {
    return TimedExamState(
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      currentIndex: currentIndex ?? this.currentIndex,
      status: status ?? this.status,
      timeRemainingSeconds: timeRemainingSeconds ?? this.timeRemainingSeconds,
    );
  }
}

@riverpod
class TimedExamNotifier extends _$TimedExamNotifier {
  Timer? _timer;

  @override
  TimedExamState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return TimedExamState(questions: _generateMockExam(100));
  }

  void startExam() {
    if (state.status == TimedExamStatus.running) return;

    state = state.copyWith(status: TimedExamStatus.running);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeRemainingSeconds > 0) {
        state = state.copyWith(timeRemainingSeconds: state.timeRemainingSeconds - 1);
      } else {
        _timer?.cancel();
        state = state.copyWith(status: TimedExamStatus.autoSubmitted);
      }
    });
  }

  void selectOption(String optionIndex) {
    if (state.status != TimedExamStatus.running) return;

    final newAnswers = Map<int, String>.from(state.answers);
    newAnswers[state.currentIndex] = optionIndex;
    
    if (ref.read(settingsProvider).hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
    
    state = state.copyWith(answers: newAnswers);
  }

  void jumpToQuestion(int index) {
    if (index >= 0 && index < state.questions.length) {
      state = state.copyWith(currentIndex: index);
    }
  }

  void nextQuestion() {
    jumpToQuestion(state.currentIndex + 1);
  }

  void prevQuestion() {
    jumpToQuestion(state.currentIndex - 1);
  }

  void submitExam() {
    _timer?.cancel();
    if (ref.read(settingsProvider).hapticsEnabled) {
      HapticFeedback.heavyImpact();
    }
    state = state.copyWith(status: TimedExamStatus.manuallySubmitted);
  }

  List<QuestionModel> _generateMockExam(int count) {
    final List<QuestionModel> list = [];
    final subjects = ['Marathi Grammar', 'Mathematics', 'Reasoning', 'General Knowledge'];
    
    for (int i = 0; i < count; i++) {
      list.add(
        QuestionModel(
          id: i.toString(),
          subjectTag: subjects[i % subjects.length],
          questionText: 'Exam Question ${i + 1}: What is the correct answer?',
          optionA: 'Option A',
          optionB: 'Option B',
          optionC: 'Option C',
          optionD: 'Option D',
          correctOption: 'A', // Mock correct answer
        ),
      );
    }
    return list;
  }
}
