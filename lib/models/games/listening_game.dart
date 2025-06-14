import 'package:json_annotation/json_annotation.dart';

part 'listening_game.g.dart';

@JsonSerializable()
class ListeningGame {
  final List<String> sentence;

  ListeningGame({required this.sentence});

  factory ListeningGame.fromJson(Map<String, dynamic> json) =>
      _$ListeningGameFromJson(json);

  Map<String, dynamic> toJson() => _$ListeningGameToJson(this);
}

