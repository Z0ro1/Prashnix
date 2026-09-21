import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/saved_question_repository.dart';
import '../../../../core/models/question_model.dart';

part 'saved_questions_provider.g.dart';

@riverpod
class SavedQuestionsNotifier extends _$SavedQuestionsNotifier {
  late final SavedQuestionRepository _repo;

  @override
  FutureOr<List<QuestionModel>> build() async {
    _repo = SavedQuestionRepository();
    return _fetchSavedQuestions();
  }

  Future<List<QuestionModel>> _fetchSavedQuestions() async {
    return await _repo.getSavedQuestions();
  }

  Future<void> toggleSaveStatus(int questionId) async {
    final isSaved = await _repo.isQuestionSaved(questionId);
    if (isSaved) {
      await _repo.removeSavedQuestion(questionId);
    } else {
      await _repo.saveQuestion(questionId);
    }
    
    // Refresh the list
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchSavedQuestions());
  }

  Future<bool> isSaved(int questionId) async {
    return await _repo.isQuestionSaved(questionId);
  }
}
