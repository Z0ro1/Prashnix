import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/models/mistake_item_model.dart';
import '../../../../core/models/question_model.dart';
import '../../../gamification/presentation/providers/heart_economy_provider.dart';
import '../../../quiz/data/repositories/mistake_repository.dart';
import '../../../quiz/data/repositories/question_repository.dart';

part 'mistake_provider.g.dart';

class MistakeState {
  final List<MistakeItemModel> mistakes;
  final String activeFilter; // 'All', 'Marathi Grammar', etc.
  final bool isLoading;

  const MistakeState({
    this.mistakes = const [],
    this.activeFilter = 'All',
    this.isLoading = true,
  });

  List<MistakeItemModel> get filteredMistakes {
    if (activeFilter == 'All') return mistakes;
    return mistakes.where((m) => m.question.subjectTag == activeFilter).toList();
  }

  List<String> get availableFilters {
    final Set<String> filters = {'All'};
    for (var m in mistakes) {
      filters.add(m.question.subjectTag);
    }
    return filters.toList();
  }

  MistakeState copyWith({
    List<MistakeItemModel>? mistakes,
    String? activeFilter,
    bool? isLoading,
  }) {
    return MistakeState(
      mistakes: mistakes ?? this.mistakes,
      activeFilter: activeFilter ?? this.activeFilter,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@riverpod
class MistakeNotifier extends _$MistakeNotifier {
  late final MistakeRepository _mistakeRepo;
  late final QuestionRepository _questionRepo;

  @override
  MistakeState build() {
    _mistakeRepo = MistakeRepository();
    _questionRepo = QuestionRepository();
    
    // Load initial data
    _loadMistakes();
    
    return const MistakeState();
  }

  Future<void> _loadMistakes() async {
    state = state.copyWith(isLoading: true);
    
    final dbMistakes = await _mistakeRepo.getUnclearedMistakes();
    
    if (dbMistakes.isEmpty) {
      state = state.copyWith(mistakes: [], isLoading: false);
      return;
    }

    // Because questions are currently mocked/demo, we might not have them in DB
    // I'll attempt to fetch them. If not found, I will generate mock QuestionModels
    // so the UI works seamlessly.
    final List<int> qIds = dbMistakes.map((m) => m.questionId).toList();
    List<QuestionModel> questions = await _questionRepo.getQuestionsByIds(qIds);

    // Fallback: Generate mock if missing from DB for demo purposes
    final List<MistakeItemModel> items = [];
    for (var m in dbMistakes) {
      QuestionModel? q;
      try {
        q = questions.firstWhere((element) => element.id == m.questionId);
      } catch (e) {
        // Create mock
        q = QuestionModel(
          id: m.questionId,
          subjectTag: 'Mock Subject',
          questionText: 'Mock Question for ID ${m.questionId}',
          optionA: 'Option A',
          optionB: 'Option B',
          optionC: 'Option C',
          optionD: 'Option D',
          correctOption: 'C',
          explanation: 'This is a mock explanation for question ${m.questionId}.',
        );
      }
      items.add(MistakeItemModel(mistake: m, question: q));
    }

    state = state.copyWith(mistakes: items, isLoading: false);
  }

  void setFilter(String filter) {
    state = state.copyWith(activeFilter: filter);
  }

  Future<void> clearMistake(int questionId) async {
    await _mistakeRepo.markMistakeCleared(questionId);
    
    // Award heart
    ref.read(heartEconomyProvider.notifier).addHearts(1);

    // Refresh list
    await _loadMistakes();
  }
}
