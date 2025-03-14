import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'question-ai_detail.g.dart';

@JsonSerializable()
class QuestionAskAI {
  @JsonKey(defaultValue: '', name: 'question')
  final String? question;
  QuestionAskAI({
    required this.question,
  });

  /// Factory untuk menangani konversi dari JSON ke objek AskAI
  factory QuestionAskAI.fromJson(Map<String, dynamic> json) {
    return QuestionAskAI(
      question: json['question'] ?? '',
    );
  }

  /// Factory untuk menangani parsing dari JSON String ke objek QuestionAskAI
  factory QuestionAskAI.fromJsonString(String jsonString) =>
      QuestionAskAI.fromJson(jsonDecode(jsonString));

  /// Konversi objek QuestionAskAI ke JSON
  Map<String, dynamic> toJson() => _$QuestionAskAIToJson(this);

  /// Konversi objek QuestionAskAI ke JSON dalam bentuk String
  String toStringJson() => jsonEncode(toJson());
}
