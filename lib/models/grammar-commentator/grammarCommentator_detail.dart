import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'grammarCommentator_detail.g.dart';

@JsonSerializable()
class GrammarCommentator {
  @JsonKey(defaultValue: '', name: 'id')
  final String? id;

  @JsonKey(defaultValue: '', name: 'bot_response')
  final String? botResponse;

  @JsonKey(defaultValue: '', name: 'user_message')
  final String? userMessage;

  @JsonKey(defaultValue: false, name: 'english_correct')
  final bool? englishCorrect;

  @JsonKey(defaultValue: '', name: 'relevance')
  final String? relevance;

  @JsonKey(defaultValue: '', name: 'coherence_score')
  final String? coherenceScore;

  @JsonKey(defaultValue: '', name: 'lexial_score')
  final String? lexialScore;

  @JsonKey(defaultValue: '', name: 'grammar_score')
  final String? grammarScore;

  @JsonKey(defaultValue: '', name: 'incorrect_part')
  final String? incorrectPart;

  @JsonKey(defaultValue: '', name: 'correct_response')
  final String? correctResponse;

  @JsonKey(defaultValue: '', name: 'corrected_sentence')
  final String? correctedSentence;

  @JsonKey(defaultValue: '', name: 'explanation')
  final String? explanation;

  GrammarCommentator({
    required this.id,
    required this.userMessage,
    required this.botResponse,
    required this.englishCorrect,
    required this.relevance,
    required this.coherenceScore,
    required this.lexialScore,
    required this.grammarScore,
    required this.incorrectPart,
    required this.correctResponse,
    required this.correctedSentence,
    required this.explanation,
  });

  /// Factory untuk menangani konversi dari JSON ke objek AskAI
  factory GrammarCommentator.fromJson(Map<String, dynamic> json) {
    return GrammarCommentator(
      id: json['id'] ?? '',
      userMessage: json['user_message'] ?? '',
      botResponse: json['bot_response'] ?? '',
      englishCorrect: json['english_correct'] ?? false,
      relevance: json['relevance'] ?? '',
      coherenceScore: json['conherence_score'] is int
          ? json['conherence_score'].toString() // Konversi ke string jika int
          : json['conherence_score'] ?? '',
      lexialScore: json['lexial_score'] is int
          ? json['lexial_score'].toString() // Konversi ke string jika int
          : json['lexial_score'] ?? '',
      grammarScore: json['grammar_score'] is int
          ? json['grammar_score'].toString() // Konversi ke string jika int
          : json['grammar_score'] ?? '',
      incorrectPart: json['incorrect_part'] ?? '',
      correctResponse: json['correct_response'] ?? '',
      correctedSentence: json['correct_sentence'] ?? '',
      explanation: json['explanation'] ?? '',
    );
  }

  factory GrammarCommentator.fromJsonString(String jsonString) =>
      GrammarCommentator.fromJson(jsonDecode(jsonString));

  /// Konversi objek GrammarCommentator ke JSON
  Map<String, dynamic> toJson() => _$GrammarCommentatorToJson(this);

  /// Konversi objek GrammarCommentator ke JSON dalam bentuk String
  String toStringJson() => jsonEncode(toJson());
}
