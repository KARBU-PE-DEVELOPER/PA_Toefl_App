import 'package:json_annotation/json_annotation.dart';

part 'scramble_game.g.dart';

@JsonSerializable()
class ScrambleData {
  @JsonKey(defaultValue: '', name: 'clue')
  final String clue;

  @JsonKey(defaultValue: '', name: 'answer')
  final String answer;

  ScrambleData({
    required this.clue,
    required this.answer,
  });

  factory ScrambleData.fromJson(Map<String, dynamic> json) =>
      _$ScrambleDataFromJson(json);

  Map<String, dynamic> toJson() => _$ScrambleDataToJson(this);
}

ScrambleData? parseScrambleData(Map<String, dynamic> json) {
  try {
    if (json.containsKey('payload') && json['payload'] is Map<String, dynamic>) {
      return ScrambleData.fromJson(json['payload']);
    }
  } catch (e) {
    print("Error parsing Scramble Data: ${e.toString()}");
  }

  return null;
}
