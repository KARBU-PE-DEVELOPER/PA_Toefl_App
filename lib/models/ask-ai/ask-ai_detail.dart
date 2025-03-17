// import 'dart:convert';

// import 'package:json_annotation/json_annotation.dart';

// part 'ask-ai_detail.g.dart';

// @JsonSerializable()
// class AskAI {
//   @JsonKey(defaultValue: '', name: 'id')
//   final String id;
//   @JsonKey(defaultValue: '', name: 'user_message')
//   final String userMessage;
//   @JsonKey(defaultValue: '', name: 'bot_response')
//   final String botResponse;
//   @JsonKey(defaultValue: false, name: 'english_correct')
//   final bool isCorrect;
//   @JsonKey(defaultValue: '', name: 'incorrect_word')
//   final String incorrectWord;
//   @JsonKey(defaultValue: '', name: 'english_sentence')
//   final String englishSentence;
//   @JsonKey(defaultValue: '', name: 'accuracy_score')
//   final String accuracyScore;
//   @JsonKey(defaultValue: '', name: 'explanation')
//   final String explanation;
  
//   AskAI({
//     required this.id,
//     required this.userMessage,
//     required this.botResponse,
//     required this.isCorrect,
//     required this.incorrectWord,
//     required this.englishSentence,
//     required this.accuracyScore,
//     required this.explanation,
//   });

//   factory AskAI.fromJson(Map<String, dynamic> json) =>
//       _$AskAIFromJson(json);

//   factory AskAI.fromJsonString(String jsonString) =>
//       _$AskAIFromJson(jsonDecode(jsonString));

//   Map<String, dynamic> toJson() => _$AskAIToJson(this);

//   String toStringJson() => jsonEncode(toJson());
// }
