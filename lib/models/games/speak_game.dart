import 'package:json_annotation/json_annotation.dart';

part 'speak_game.g.dart';

@JsonSerializable()
class SpeakGame {
  final List sentence;

  SpeakGame({required this.sentence});

  factory SpeakGame.fromJson(Map<String, dynamic> json) =>
      _$SpeakGameFromJson(json);

  Map<String, dynamic> toJson() => _$SpeakGameToJson(this);
}
