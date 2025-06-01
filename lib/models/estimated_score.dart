import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'estimated_score.g.dart';

@JsonSerializable()
class EstimatedScore {
  @JsonKey(name: 'target_user')
  int targetUser;

  @JsonKey(name: 'user_score')
  String userScore; // Pastikan ini String, bukan int

  @JsonKey(name: 'score_listening')
  String scoreListening; // Pastikan ini String, bukan int

  @JsonKey(name: 'score_structure')
  String scoreStructure; // Pastikan ini String, bukan int

  @JsonKey(name: 'score_reading')
  String scoreReading; // Pastikan ini String, bukan int

  EstimatedScore({
    required this.targetUser,
    required this.userScore,
    required this.scoreListening,
    required this.scoreStructure,
    required this.scoreReading,
  });

  factory EstimatedScore.fromJson(Map<String, dynamic> json) =>
      _$EstimatedScoreFromJson(json);
  Map<String, dynamic> toJson() => _$EstimatedScoreToJson(this);

  factory EstimatedScore.fromJsonString(String jsonString) =>
      _$EstimatedScoreFromJson(json.decode(jsonString));
  String toJsonString() => json.encode(toJson());

  // Helper methods untuk konversi ke double jika diperlukan untuk kalkulasi
  double get userScoreAsDouble => double.tryParse(userScore) ?? 0.0;
  double get scoreListeningAsDouble => double.tryParse(scoreListening) ?? 0.0;
  double get scoreStructureAsDouble => double.tryParse(scoreStructure) ?? 0.0;
  double get scoreReadingAsDouble => double.tryParse(scoreReading) ?? 0.0;
}
