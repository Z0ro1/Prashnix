class MistakeModel {
  final int? id;
  final int questionId;
  final String userAnswer;
  final int mistakeCount;
  final bool isCleared;
  final String lastFailedAt;

  const MistakeModel({
    this.id,
    required this.questionId,
    required this.userAnswer,
    this.mistakeCount = 1,
    this.isCleared = false,
    required this.lastFailedAt,
  });

  factory MistakeModel.fromMap(Map<String, dynamic> map) {
    return MistakeModel(
      id: map['id'] as int?,
      questionId: map['question_id'] as int,
      userAnswer: map['user_answer'] as String,
      mistakeCount: map['mistake_count'] as int? ?? 1,
      isCleared: (map['is_cleared'] as int? ?? 0) == 1,
      lastFailedAt: map['last_failed_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'question_id': questionId,
      'user_answer': userAnswer,
      'mistake_count': mistakeCount,
      'is_cleared': isCleared ? 1 : 0,
      'last_failed_at': lastFailedAt,
    };
  }
}
