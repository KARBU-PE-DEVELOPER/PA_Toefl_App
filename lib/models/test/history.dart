import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'history.g.dart';

@JsonSerializable()
class HistoryItem {
  @JsonKey(name: 'packet_id')
  final int packetId;

  @JsonKey(name: 'packet_type', defaultValue: '')
  final String type;

  @JsonKey(name: 'time_start', defaultValue: '')
  final String timeStart;

  @JsonKey(name: 'score')
  final ScoreData score;

  HistoryItem({
    required this.packetId,
    required this.type,
    required this.timeStart,
    required this.score,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) =>
      _$HistoryItemFromJson(json);

  Map<String, dynamic> toJson() => _$HistoryItemToJson(this);

  String toStringJson() => jsonEncode(toJson());

  // Helper methods untuk display
  String get formattedDateTime {
    if (timeStart.isEmpty) return '';

    try {
      // Format dari API: "2025-06-13 12:06:22"
      final parts = timeStart.split(' ');
      if (parts.length == 2) {
        final dateParts = parts[0].split('-');
        final timeParts = parts[1].split(':');

        if (dateParts.length == 3 && timeParts.length >= 2) {
          return '${dateParts[0]}-${dateParts[1].padLeft(2, '0')}-${dateParts[2].padLeft(2, '0')} ${timeParts[0].padLeft(2, '0')}:${timeParts[1].padLeft(2, '0')}';
        }
      }
      return timeStart;
    } catch (e) {
      return timeStart;
    }
  }

  // Getter untuk scores
  String get displayListening => score.displayListening;
  String get displayStructure => score.displayStructure;
  String get displayReading => score.displayReading;
  String get displayTotal => score.displayTotal;
  String get levelProficiency => score.levelProficiency;

  // Method untuk check apakah ujian sudah selesai (ada score)
  bool get isCompleted => score.totalScore > 0;

  // Untuk compatibility dengan kode lama
  bool get isValid => true; // Semua data dari history API dianggap valid
  bool get hasStarted =>
      true; // Semua data dari history API dianggap sudah dimulai
}

@JsonSerializable()
class ScoreData {
  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'packet_claim_id')
  final int packetClaimId;

  @JsonKey(name: 'score_toefl', fromJson: _stringToDouble)
  final double totalScore;

  @JsonKey(name: 'score_structure', fromJson: _stringToDouble)
  final double structureScore;

  @JsonKey(name: 'score_listening', fromJson: _stringToDouble)
  final double listeningScore;

  @JsonKey(name: 'score_reading', fromJson: _stringToDouble)
  final double readingScore;

  @JsonKey(name: 'level_profiency', defaultValue: '')
  final String levelProficiency;

  @JsonKey(name: 'created_at', defaultValue: '')
  final String createdAt;

  @JsonKey(name: 'updated_at', defaultValue: '')
  final String updatedAt;

  ScoreData({
    required this.id,
    required this.packetClaimId,
    required this.totalScore,
    required this.structureScore,
    required this.listeningScore,
    required this.readingScore,
    required this.levelProficiency,
    required this.createdAt,
    required this.updatedAt,
  });

  // Helper function to convert String to double
  static double _stringToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  factory ScoreData.fromJson(Map<String, dynamic> json) =>
      _$ScoreDataFromJson(json);

  Map<String, dynamic> toJson() => _$ScoreDataToJson(this);

  // Display methods
  String get displayListening => listeningScore.toStringAsFixed(0);
  String get displayStructure => structureScore.toStringAsFixed(0);
  String get displayReading => readingScore.toStringAsFixed(0);
  String get displayTotal => totalScore.toStringAsFixed(0);
}

// Response wrapper untuk API
@JsonSerializable()
class HistoryResponse {
  @JsonKey(name: 'success')
  final bool success;

  @JsonKey(name: 'message')
  final String message;

  @JsonKey(name: 'payload')
  final List<HistoryItem> payload;

  HistoryResponse({
    required this.success,
    required this.message,
    required this.payload,
  });

  factory HistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$HistoryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$HistoryResponseToJson(this);
}
