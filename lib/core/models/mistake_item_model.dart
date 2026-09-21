import 'mistake_model.dart';
import 'question_model.dart';

class MistakeItemModel {
  final MistakeModel mistake;
  final QuestionModel question;

  const MistakeItemModel({
    required this.mistake,
    required this.question,
  });
}
