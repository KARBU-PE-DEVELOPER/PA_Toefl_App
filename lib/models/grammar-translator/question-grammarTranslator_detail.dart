import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'question-grammarTranslator_detail.g.dart';

@JsonSerializable()
class QuestionGrammarTranslator {
  @JsonKey(defaultValue: '', name: 'question')
  final String? question;
  QuestionGrammarTranslator({
    required this.question,
  });

  /// Factory untuk menangani konversi dari JSON ke objek GramQuestionGrammarTranslator
  factory QuestionGrammarTranslator.fromJson(Map<String, dynamic> json) {
    return QuestionGrammarTranslator(
      question: json['question'] ?? '',
    );
  }

  /// Factory untuk menangani parsing dari JSON String ke objek QuestionGrammarTranslator
  factory QuestionGrammarTranslator.fromJsonString(String jsonString) =>
      QuestionGrammarTranslator.fromJson(jsonDecode(jsonString));

  /// Konversi objek QuestionGrammarTranslator ke JSON
  Map<String, dynamic> toJson() => _$QuestionGrammarTranslatorToJson(this);

  /// Konversi objek QuestionGrammarTranslator ke JSON dalam bentuk String
  String toStringJson() => jsonEncode(toJson());
}
