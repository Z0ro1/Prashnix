import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/subject_stat_model.dart';
import '../../data/repositories/analytics_repository.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository();
});

class SubjectAnalyticsState {
  final OverallAnalyticsSummary summary;
  final bool isLoading;
  final String? errorMessage;

  const SubjectAnalyticsState({
    this.summary = const OverallAnalyticsSummary(),
    this.isLoading = false,
    this.errorMessage,
  });

  SubjectAnalyticsState copyWith({
    OverallAnalyticsSummary? summary,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SubjectAnalyticsState(
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class SubjectAnalyticsNotifier extends Notifier<SubjectAnalyticsState> {
  late final AnalyticsRepository _repository;

  @override
  SubjectAnalyticsState build() {
    _repository = ref.watch(analyticsRepositoryProvider);
    Future.microtask(() => loadStats());
    return const SubjectAnalyticsState(isLoading: true);
  }

  Future<void> loadStats() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final summary = await _repository.getOverallSummary();
      state = state.copyWith(summary: summary, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> refresh() async {
    await loadStats();
  }
}

final subjectAnalyticsProvider =
    NotifierProvider<SubjectAnalyticsNotifier, SubjectAnalyticsState>(() {
  return SubjectAnalyticsNotifier();
});
