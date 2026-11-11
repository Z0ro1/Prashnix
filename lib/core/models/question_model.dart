class QuestionModel {
  final String? id;
  final String? displayId;
  final String subjectTag;
  final String? subtopicTag;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctOption;
  final String? explanation;
  final int? pyqYear;
  final String? districtTag;

  const QuestionModel({
    this.id,
    this.displayId,
    required this.subjectTag,
    this.subtopicTag,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctOption,
    this.explanation,
    this.pyqYear,
    this.districtTag,
  });

  /// Returns the 6-digit random display ID (e.g. "717270"), or fallback 6-char snippet if missing.
  String get displayCode {
    if (displayId != null && displayId!.trim().isNotEmpty) {
      return displayId!.trim();
    }
    if (id != null && id!.isNotEmpty) {
      final clean = id!.replaceAll('-', '');
      return clean.length >= 6 ? clean.substring(0, 6).toUpperCase() : clean.toUpperCase();
    }
    return '000000';
  }

  /// Formatted subject name for UI display (handles empty, 'unknown', or raw UUID fallbacks cleanly).
  String get formattedSubject {
    final uuidRegex = RegExp(r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}');
    bool isInvalid(String s) {
      final t = s.trim();
      return t.isEmpty ||
          t.toLowerCase() == 'unknown' ||
          uuidRegex.hasMatch(t) ||
          (t.length >= 20 && t.contains('-'));
    }

    String raw = subjectTag.trim();
    if (isInvalid(raw)) {
      if (subtopicTag != null && !isInvalid(subtopicTag!)) {
        raw = subtopicTag!.trim();
      } else {
        return 'सामान्य अभ्यास';
      }
    }
    final lower = raw.toLowerCase();
    if (isInvalid(raw)) return 'सामान्य अभ्यास';
    if (lower == 'math' || lower == 'maths' || lower == 'mathematics') return 'गणित';
    if (lower == 'marathi' || lower == 'marathi grammar') return 'मराठी व्याकरण';
    if (lower == 'gk' || lower == 'general knowledge') return 'सामान्य ज्ञान';
    if (lower == 'reasoning' || lower == 'mental ability') return 'बुद्धिमत्ता चाचणी';
    if (lower == 'english' || lower == 'english grammar') return 'इंग्रजी व्याकरण';
    return raw;
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      id: map['id'] as String?,
      displayId: map['display_id']?.toString(),
      subjectTag: map['subject_tag'] as String,
      subtopicTag: map['subtopic_tag'] as String?,
      questionText: map['question_text'] as String,
      optionA: map['option_a'] as String,
      optionB: map['option_b'] as String,
      optionC: map['option_c'] as String,
      optionD: map['option_d'] as String,
      correctOption: map['correct_option'] as String,
      explanation: map['explanation'] as String?,
      pyqYear: map['pyq_year'] as int?,
      districtTag: map['district_tag'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (displayId != null) 'display_id': displayId,
      'subject_tag': subjectTag,
      'subtopic_tag': subtopicTag,
      'question_text': questionText,
      'option_a': optionA,
      'option_b': optionB,
      'option_c': optionC,
      'option_d': optionD,
      'correct_option': correctOption,
      'explanation': explanation,
      'pyq_year': pyqYear,
      'district_tag': districtTag,
    };
  }
}
