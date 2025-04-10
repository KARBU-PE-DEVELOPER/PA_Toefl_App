import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'grammarTranslator_detail.g.dart';

@JsonSerializable()
class GrammarTranslator {
  @JsonKey(defaultValue: '', name: 'id')
  final String? id;

  @JsonKey(defaultValue: '', name: 'user_message')
  final String? userMessage;

  @JsonKey(defaultValue: '', name: 'bot_response')
  final String? botResponse;

  @JsonKey(defaultValue: false, name: 'english_correct')
  final bool? isCorrect;

  @JsonKey(defaultValue: false, name: 'answer_match')
  final bool? answerMatch;

  @JsonKey(defaultValue: '', name: 'incorrect_word')
  final String? incorrectWord;

  @JsonKey(defaultValue: '', name: 'english_sentence')
  final String? englishSentence;

  @JsonKey(name: 'accuracy_score')
  final String? accuracyScore;

  @JsonKey(defaultValue: '', name: 'explanation')
  final String? explanation;

  GrammarTranslator({
    required this.id,
    required this.userMessage,
    required this.botResponse,
    required this.isCorrect,
    required this.answerMatch,
    required this.incorrectWord,
    required this.englishSentence,
    required this.accuracyScore,
    required this.explanation,
  });

  /// Factory untuk menangani konversi dari JSON ke objek GrammarTranslator
  factory GrammarTranslator.fromJson(Map<String, dynamic> json) {
    return GrammarTranslator(
      id: json['id'] ?? '',
      userMessage: json['user_message'] ?? '',
      botResponse: json['bot_response'] ?? '',
      isCorrect: json['english_correct'] ?? false,
      answerMatch: json['answer_match'] ?? false,
      incorrectWord: json['incorrect_word'] ?? '',
      englishSentence: json['english_sentence'] ?? '',
      accuracyScore: json['accuracy_score'] is int
          ? json['accuracy_score'].toString() // Konversi ke string jika int
          : json['accuracy_score'] ?? '',
      explanation: json['explanation'] ?? '',
    );
  }

  /// Factory untuk menangani parsing dari JSON String ke objek GrammarTranslator
  factory GrammarTranslator.fromJsonString(String jsonString) =>
      GrammarTranslator.fromJson(jsonDecode(jsonString));

  /// Konversi objek AskAI ke JSON
  Map<String, dynamic> toJson() => _$GrammarTranslatorToJson(this);

  /// Konversi objek AskAI ke JSON dalam bentuk String
  String toStringJson() => jsonEncode(toJson());

}
