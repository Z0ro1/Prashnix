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

  /// Returns whether a given candidate choice is correct, supporting:
  /// - Letter choice ("A", "B", "C", "D")
  /// - Lowercase ("a", "b", "c", "d")
  /// - Full option text (e.g. "मुंबई", "4", "27")
  /// - Whitespace-trimmed comparisons
  bool isAnswerCorrect(String? candidateAnswer) {
    if (candidateAnswer == null) return false;
    final trimmed = candidateAnswer.trim();
    if (trimmed.isEmpty) return false;

    final upper = trimmed.toUpperCase();
    final cleanCorrect = correctOption.trim().toUpperCase();

    // 1. Direct letter match (A == A, B == B, etc.)
    if (upper == cleanCorrect) return true;

    // 2. Exact match against correct option text
    final correctText = correctOptionText.trim();
    if (correctText.isNotEmpty) {
      if (trimmed == correctText) return true;
      if (trimmed.toLowerCase() == correctText.toLowerCase()) return true;
    }

    return false;
  }

  /// Returns the text corresponding to the correct option.
  String get correctOptionText {
    final clean = correctOption.trim().toUpperCase();
    switch (clean) {
      case 'A': return optionA;
      case 'B': return optionB;
      case 'C': return optionC;
      case 'D': return optionD;
      default: return optionA;
    }
  }

  /// Bulletproof resolver that converts any raw answer representation (option text, numeric value,
  /// letter label, or Marathi indicator) into a canonical 'A', 'B', 'C', or 'D'.
  static String resolveCorrectOption({
    required dynamic rawAnswer,
    required String optA,
    required String optB,
    required String optC,
    required String optD,
  }) {
    if (rawAnswer == null) return 'A';
    final ans = rawAnswer.toString().trim();
    if (ans.isEmpty) return 'A';

    final a = optA.trim();
    final b = optB.trim();
    final c = optC.trim();
    final d = optD.trim();

    // 1. Exact match against option text (Highest priority: protects numbers like "3", "4", "2")
    if (ans == a && a.isNotEmpty) return 'A';
    if (ans == b && b.isNotEmpty) return 'B';
    if (ans == c && c.isNotEmpty) return 'C';
    if (ans == d && d.isNotEmpty) return 'D';

    // 2. Case-insensitive & whitespace-trimmed match
    final lowerAns = ans.toLowerCase();
    if (lowerAns == a.toLowerCase() && a.isNotEmpty) return 'A';
    if (lowerAns == b.toLowerCase() && b.isNotEmpty) return 'B';
    if (lowerAns == c.toLowerCase() && c.isNotEmpty) return 'C';
    if (lowerAns == d.toLowerCase() && d.isNotEmpty) return 'D';

    // 3. Normalized letter indicators: A, B, C, D (or Marathi options पर्याय अ, पर्याय ब, पर्याय क, पर्याय ड, or (A), [B])
    final clean = ans.replaceAll(RegExp(r'^[(\[\{]|[)\]\}\.:]$'), '').trim().toUpperCase();
    if (clean == 'A' || clean == 'OPTION A' || clean == 'पर्याय अ' || clean == 'अ') return 'A';
    if (clean == 'B' || clean == 'OPTION B' || clean == 'पर्याय ब' || clean == 'ब') return 'B';
    if (clean == 'C' || clean == 'OPTION C' || clean == 'पर्याय क' || clean == 'क') return 'C';
    if (clean == 'D' || clean == 'OPTION D' || clean == 'पर्याय ड' || clean == 'ड') return 'D';

    // 4. Numeric option index: 1, 2, 3, 4 (or Marathi numerals १, २, ३, ४)
    // ONLY check index if none of the options matched the number in steps 1 & 2!
    if (clean == '1' || clean == 'OPTION 1' || clean == 'पर्याय १' || clean == '१') return 'A';
    if (clean == '2' || clean == 'OPTION 2' || clean == 'पर्याय २' || clean == '२') return 'B';
    if (clean == '3' || clean == 'OPTION 3' || clean == 'पर्याय ३' || clean == '३') return 'C';
    if (clean == '4' || clean == 'OPTION 4' || clean == 'पर्याय ४' || clean == '४') return 'D';

    // 5. Substring / contains match (only for answers with 3+ characters to prevent single letter/digit collisions)
    if (lowerAns.length >= 3) {
      if (a.isNotEmpty && (a.toLowerCase().contains(lowerAns) || lowerAns.contains(a.toLowerCase()))) return 'A';
      if (b.isNotEmpty && (b.toLowerCase().contains(lowerAns) || lowerAns.contains(b.toLowerCase()))) return 'B';
      if (c.isNotEmpty && (c.toLowerCase().contains(lowerAns) || lowerAns.contains(c.toLowerCase()))) return 'C';
      if (d.isNotEmpty && (d.toLowerCase().contains(lowerAns) || lowerAns.contains(d.toLowerCase()))) return 'D';
    }

    return 'A';
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    final optA = (map['option_a'] ?? '').toString();
    final optB = (map['option_b'] ?? '').toString();
    final optC = (map['option_c'] ?? '').toString();
    final optD = (map['option_d'] ?? '').toString();
    final rawCorrect = (map['correct_option'] ?? map['correct_answer'] ?? 'A').toString();

    final resolvedCorrect = resolveCorrectOption(
      rawAnswer: rawCorrect,
      optA: optA,
      optB: optB,
      optC: optC,
      optD: optD,
    );

    return QuestionModel(
      id: map['id']?.toString(),
      displayId: map['display_id']?.toString(),
      subjectTag: (map['subject_tag'] ?? 'unknown').toString(),
      subtopicTag: map['subtopic_tag']?.toString(),
      questionText: (map['question_text'] ?? '').toString(),
      optionA: optA,
      optionB: optB,
      optionC: optC,
      optionD: optD,
      correctOption: resolvedCorrect,
      explanation: map['explanation']?.toString(),
      pyqYear: map['pyq_year'] is int ? map['pyq_year'] as int : null,
      districtTag: map['district_tag']?.toString(),
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
