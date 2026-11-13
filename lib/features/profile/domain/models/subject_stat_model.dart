enum SubjectMasteryLevel {
  weak, // < 60% accuracy (or critical mistakes)
  moderate, // 60% - 79% accuracy
  strong, // >= 80% accuracy
  calibrating, // < 5 attempts (cold start)
}

extension SubjectMasteryLevelExt on SubjectMasteryLevel {
  String get labelMarathi {
    switch (this) {
      case SubjectMasteryLevel.weak:
        return 'कच्चा विषय ⚠️';
      case SubjectMasteryLevel.moderate:
        return 'मध्यम पकड';
      case SubjectMasteryLevel.strong:
        return 'मजबूत 🔥';
      case SubjectMasteryLevel.calibrating:
        return 'डेटा गोळा होत आहे';
    }
  }
}

class SubtopicStatModel {
  final String subtopicName;
  final int totalAttempts;
  final int correctCount;
  final int incorrectCount;
  final double accuracyPct;
  final SubjectMasteryLevel masteryLevel;

  const SubtopicStatModel({
    required this.subtopicName,
    required this.totalAttempts,
    required this.correctCount,
    required this.incorrectCount,
    required this.accuracyPct,
    required this.masteryLevel,
  });

  static SubjectMasteryLevel calculateMastery(int total, double accuracy) {
    if (total < 3) return SubjectMasteryLevel.calibrating;
    if (accuracy >= 80.0) return SubjectMasteryLevel.strong;
    if (accuracy >= 60.0) return SubjectMasteryLevel.moderate;
    return SubjectMasteryLevel.weak;
  }
}

class SubjectStatModel {
  final String rawSubjectTag;
  final String formattedSubjectName;
  final int totalAttempts;
  final int correctCount;
  final int incorrectCount;
  final double accuracyPct;
  final SubjectMasteryLevel masteryLevel;
  final List<SubtopicStatModel> subtopics;

  const SubjectStatModel({
    required this.rawSubjectTag,
    required this.formattedSubjectName,
    required this.totalAttempts,
    required this.correctCount,
    required this.incorrectCount,
    required this.accuracyPct,
    required this.masteryLevel,
    this.subtopics = const [],
  });

  bool get isWeak => masteryLevel == SubjectMasteryLevel.weak;

  static SubjectMasteryLevel calculateMastery(int total, double accuracy) {
    if (total < 5) return SubjectMasteryLevel.calibrating;
    if (accuracy >= 80.0) return SubjectMasteryLevel.strong;
    if (accuracy >= 60.0) return SubjectMasteryLevel.moderate;
    return SubjectMasteryLevel.weak;
  }
}

class OverallAnalyticsSummary {
  final int totalAttempts;
  final int totalCorrect;
  final int totalIncorrect;
  final double overallAccuracyPct;
  final List<SubjectStatModel> subjectStats;

  const OverallAnalyticsSummary({
    this.totalAttempts = 0,
    this.totalCorrect = 0,
    this.totalIncorrect = 0,
    this.overallAccuracyPct = 0.0,
    this.subjectStats = const [],
  });
}

