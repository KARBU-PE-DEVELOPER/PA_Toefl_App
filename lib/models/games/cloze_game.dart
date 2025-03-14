import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'cloze_game.g.dart';

@JsonSerializable()
class ClozeGame {
  @JsonKey(defaultValue: '', name: 'question')
  final String question;

  @JsonKey(defaultValue: '', name: 'key_answer')
  final String keyAnswer;

  @JsonKey(defaultValue: [], name: 'answers')
  final List<String> answers;

  ClozeGame({
    required this.question,
    required this.keyAnswer,
    required this.answers,
  });

  factory ClozeGame.fromJson(Map<String, dynamic> json) =>
      _$ClozeGameFromJson(json);

  Map<String, dynamic> toJson() => _$ClozeGameToJson(this);


  static List<ClozeGame> fromJsonList(String jsonString) {
    final data = json.decode(jsonString);
    if (data is Map<String, dynamic> && data.containsKey('payload')) {
      return (data['payload'] as List)
          .map((item) => ClozeGame.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
