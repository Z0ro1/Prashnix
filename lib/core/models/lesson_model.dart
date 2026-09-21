class LessonModel {
  final int? id;
  final int nodeId;
  final int lessonOrder;
  final String subjectTag;
  final bool isCompleted;
  final int highScore;
  final String? completedAt;

  const LessonModel({
    this.id,
    required this.nodeId,
    required this.lessonOrder,
    required this.subjectTag,
    this.isCompleted = false,
    this.highScore = 0,
    this.completedAt,
  });

  factory LessonModel.fromMap(Map<String, dynamic> map) {
    return LessonModel(
      id: map['id'] as int?,
      nodeId: map['node_id'] as int,
      lessonOrder: map['lesson_order'] as int,
      subjectTag: map['subject_tag'] as String,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      highScore: map['high_score'] as int? ?? 0,
      completedAt: map['completed_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'node_id': nodeId,
      'lesson_order': lessonOrder,
      'subject_tag': subjectTag,
      'is_completed': isCompleted ? 1 : 0,
      'high_score': highScore,
      'completed_at': completedAt,
    };
  }
}
