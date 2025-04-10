import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'question-grammarCommentator_detail.g.dart';

@JsonSerializable()
class QuestionGrammarCommentator {
  @JsonKey(defaultValue: '', name: 'question')
  final String? question;
  QuestionGrammarCommentator({
    required this.question,
  });

  /// Factory untuk menangani konversi dari JSON ke objek GramQuestionGrammarCommentator
  factory QuestionGrammarCommentator.fromJson(Map<String, dynamic> json) {
    return QuestionGrammarCommentator(
      question: json['question'] ?? '',
    );
  }

  /// Factory untuk menangani parsing dari JSON String ke objek QuestionGrammarCommentator
  factory QuestionGrammarCommentator.fromJsonString(String jsonString) =>
      QuestionGrammarCommentator.fromJson(jsonDecode(jsonString));

  /// Konversi objek QuestionGrammarCommentator ke JSON
  Map<String, dynamic> toJson() => _$QuestionGrammarCommentatorToJson(this);

  /// Konversi objek QuestionGrammarCommentator ke JSON dalam bentuk String
  String toStringJson() => jsonEncode(toJson());
}
