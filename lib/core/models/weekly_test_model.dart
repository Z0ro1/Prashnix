import 'question_model.dart';

class WeeklyTestModel {
  final String id;
  final String title;
  final String? description;
  final String examType;
  final DateTime scheduledDate;
  final String? startTime;
  final int durationMinutes;
  final int totalMarks;
  final int totalQuestions;
  final List<QuestionModel> questions;
  final bool isActive;

  const WeeklyTestModel({
    required this.id,
    required this.title,
    this.description,
    required this.examType,
    required this.scheduledDate,
    this.startTime,
    this.durationMinutes = 90,
    this.totalMarks = 100,
    this.totalQuestions = 100,
    this.questions = const [],
    this.isActive = true,
  });

  factory WeeklyTestModel.fromMap(Map<String, dynamic> map) {
    // Parse questions if embedded in JSONB array
    List<QuestionModel> qList = [];
    if (map['questions'] != null && map['questions'] is List) {
      final rawList = map['questions'] as List;
      qList = rawList.map((q) {
        if (q is Map<String, dynamic>) {
          final optA = (q['optionA'] ?? q['option_a'] ?? '').toString();
          final optB = (q['optionB'] ?? q['option_b'] ?? '').toString();
          final optC = (q['optionC'] ?? q['option_c'] ?? '').toString();
          final optD = (q['optionD'] ?? q['option_d'] ?? '').toString();
          final rawAns = q['correctOption'] ?? q['correct_option'] ?? q['correct_answer'] ?? 'A';

          return QuestionModel(
            id: q['id']?.toString(),
            subjectTag: 'weekly_test',
            subtopicTag: map['exam_type']?.toString(),
            questionText: q['questionText'] ?? q['question_text'] ?? '',
            optionA: optA,
            optionB: optB,
            optionC: optC,
            optionD: optD,
            correctOption: QuestionModel.resolveCorrectOption(
              rawAnswer: rawAns,
              optA: optA,
              optB: optB,
              optC: optC,
              optD: optD,
            ),
            explanation: q['explanation']?.toString(),
            pyqYear: q['pyqYear'] is int ? q['pyqYear'] : null,
            districtTag: q['districtTag']?.toString(),
          );
        }
        return QuestionModel.fromMap(Map<String, dynamic>.from(q as Map));
      }).toList();
    }

    DateTime parsedDate;
    if (map['scheduled_date'] != null) {
      parsedDate = DateTime.tryParse(map['scheduled_date'].toString()) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return WeeklyTestModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'साप्ताहिक महासराव चाचणी',
      description: map['description']?.toString(),
      examType: map['exam_type']?.toString() ?? 'Police Bharti',
      scheduledDate: parsedDate,
      startTime: map['start_time']?.toString(),
      durationMinutes: (map['duration_minutes'] as num?)?.toInt() ?? 90,
      totalMarks: (map['total_marks'] as num?)?.toInt() ?? 100,
      totalQuestions: (map['total_questions'] as num?)?.toInt() ?? (qList.isNotEmpty ? qList.length : 100),
      questions: qList,
      isActive: map['is_active'] == null ? true : (map['is_active'] as bool),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'exam_type': examType,
      'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
      'start_time': startTime,
      'duration_minutes': durationMinutes,
      'total_marks': totalMarks,
      'total_questions': totalQuestions,
      'is_active': isActive,
    };
  }
}
