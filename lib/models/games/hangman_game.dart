import 'package:json_annotation/json_annotation.dart';

part 'hangman_game.g.dart';

@JsonSerializable()
class HangmanData {
  @JsonKey(defaultValue: '', name: 'clue')
  final String clue;

  @JsonKey(defaultValue: '', name: 'answer')
  final String answer;

  HangmanData({
    required this.clue,
    required this.answer,
  });

  factory HangmanData.fromJson(Map<String, dynamic> json) =>
      _$HangmanDataFromJson(json);

  Map<String, dynamic> toJson() => _$HangmanDataToJson(this);
}

HangmanData? parseHangmanData(Map<String, dynamic> json) {
  try {
    if (json.containsKey('payload') && json['payload'] is Map<String, dynamic>) {
      return HangmanData.fromJson(json['payload']);
    }
  } catch (e) {
    print("Error parsing Hangman Data: ${e.toString()}");
  }

  return null;
}
