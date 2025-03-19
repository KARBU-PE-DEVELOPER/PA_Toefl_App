import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'speak_game.g.dart';

@JsonSerializable()
class SpeakGame {
  @JsonKey(defaultValue: '', name: 'sentence')
  final String? sentence;
  SpeakGame({
    required this.sentence,
  });

  /// Factory untuk menangani konversi dari JSON ke objek AskAI
  factory SpeakGame.fromJson(Map<String, dynamic> json) {
    return SpeakGame(
      sentence: json['sentence'] ?? '',
    );
  }

  /// Konversi objek SpeakGame ke JSON
  Map<String, dynamic> toJson() => _$SpeakGameToJson(this);

  /// Konversi objek SpeakGame ke JSON dalam bentuk String
  String toStringJson() => jsonEncode(toJson());
}
