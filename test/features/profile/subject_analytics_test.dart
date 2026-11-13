import 'package:flutter_test/flutter_test.dart';
import 'package:prashnix/features/profile/domain/models/subject_stat_model.dart';
import 'package:prashnix/features/profile/presentation/providers/subject_analytics_provider.dart';

void main() {
  group('Subject & Topic Weakness Heatmap Tests', () {
    test('SubjectMasteryLevel.calculateMastery correctly assigns levels', () {
      // Cold start: < 5 attempts
      expect(SubjectStatModel.calculateMastery(4, 50.0), SubjectMasteryLevel.calibrating);
      expect(SubjectStatModel.calculateMastery(0, 0.0), SubjectMasteryLevel.calibrating);

      // Strong: >= 80%
      expect(SubjectStatModel.calculateMastery(10, 80.0), SubjectMasteryLevel.strong);
      expect(SubjectStatModel.calculateMastery(50, 95.0), SubjectMasteryLevel.strong);

      // Moderate: 60% - 79.9%
      expect(SubjectStatModel.calculateMastery(10, 60.0), SubjectMasteryLevel.moderate);
      expect(SubjectStatModel.calculateMastery(20, 75.0), SubjectMasteryLevel.moderate);

      // Weak: < 60%
      expect(SubjectStatModel.calculateMastery(5, 59.9), SubjectMasteryLevel.weak);
      expect(SubjectStatModel.calculateMastery(10, 40.0), SubjectMasteryLevel.weak);
      expect(SubjectStatModel.calculateMastery(15, 0.0), SubjectMasteryLevel.weak);
    });

    test('SubjectMasteryLevel labels return correct Marathi strings', () {
      expect(SubjectMasteryLevel.weak.labelMarathi, 'कच्चा विषय ⚠️');
      expect(SubjectMasteryLevel.moderate.labelMarathi, 'मध्यम पकड');
      expect(SubjectMasteryLevel.strong.labelMarathi, 'मजबूत 🔥');
      expect(SubjectMasteryLevel.calibrating.labelMarathi, 'डेटा गोळा होत आहे');
    });

    test('SubjectStatModel isWeak getter accurately reflects weak status', () {
      const weakSubject = SubjectStatModel(
        rawSubjectTag: 'Maths',
        formattedSubjectName: 'अंकगणित',
        totalAttempts: 10,
        correctCount: 4,
        incorrectCount: 6,
        accuracyPct: 40.0,
        masteryLevel: SubjectMasteryLevel.weak,
      );

      const strongSubject = SubjectStatModel(
        rawSubjectTag: 'Marathi',
        formattedSubjectName: 'मराठी व्याकरण',
        totalAttempts: 10,
        correctCount: 9,
        incorrectCount: 1,
        accuracyPct: 90.0,
        masteryLevel: SubjectMasteryLevel.strong,
      );

      expect(weakSubject.isWeak, isTrue);
      expect(strongSubject.isWeak, isFalse);
    });

    test('SubtopicStatModel calculateMastery calculates correctly', () {
      expect(SubtopicStatModel.calculateMastery(2, 50.0), SubjectMasteryLevel.calibrating);
      expect(SubtopicStatModel.calculateMastery(5, 85.0), SubjectMasteryLevel.strong);
      expect(SubtopicStatModel.calculateMastery(5, 65.0), SubjectMasteryLevel.moderate);
      expect(SubtopicStatModel.calculateMastery(5, 30.0), SubjectMasteryLevel.weak);
    });

    test('OverallAnalyticsSummary defaults initialize safely', () {
      const summary = OverallAnalyticsSummary();
      expect(summary.totalAttempts, 0);
      expect(summary.totalCorrect, 0);
      expect(summary.totalIncorrect, 0);
      expect(summary.overallAccuracyPct, 0.0);
      expect(summary.subjectStats, isEmpty);
    });

    test('SubjectAnalyticsState copyWith works properly', () {
      const initialState = SubjectAnalyticsState(isLoading: true);
      final updated = initialState.copyWith(
        isLoading: false,
        summary: const OverallAnalyticsSummary(
          totalAttempts: 20,
          totalCorrect: 15,
          totalIncorrect: 5,
          overallAccuracyPct: 75.0,
        ),
      );

      expect(updated.isLoading, isFalse);
      expect(updated.summary.totalAttempts, 20);
      expect(updated.summary.overallAccuracyPct, 75.0);
      expect(updated.errorMessage, isNull);
    });
  });
}

