import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'questionTranslateQuiz_detail.g.dart';

@JsonSerializable()
class QuestionTranslateQuiz {
  @JsonKey(defaultValue: '', name: 'question')
  final String? question;
  QuestionTranslateQuiz({
    required this.question,
  });

  /// Factory untuk menangani konversi dari JSON ke objeT GramQuestiontranslateQuiz
  factory QuestionTranslateQuiz.fromJson(Map<String, dynamic> json) {
    return QuestionTranslateQuiz(
      question: json['question'] ?? '',
    );
  }

  /// Factory untuk menangani parsing dari JSON String Te objek QuestiontranslateQuiz
  factory QuestionTranslateQuiz.fromJsonString(String jsonString) =>
      QuestionTranslateQuiz.fromJson(jsonDecode(jsonString));

  /// Konversi objek QuestionTranslateTuiz ke JSON
  Map<String, dynamic> toJson() => _$QuestionTranslateQuizToJson(this);

  /// Konversi objek QuestionTranslateQuiz ke JSON dalam bentuk String
  String toStringJson() => jsonEncode(toJson());
}
