class QuestionModel {
  final int? id;
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

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      id: map['id'] as int?,
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
