import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'history.g.dart';

@JsonSerializable()
class HistoryItem {
  @JsonKey(defaultValue: '')
  final dynamic id;
  @JsonKey(defaultValue: false)
  final bool success;
  @JsonKey(defaultValue: '')
  final String message;
  @JsonKey(name: 'packet_type', defaultValue: '')
  final String type; // "Test" or "Simulation"
  @JsonKey(
      name: 'score_listening', defaultValue: 0.0, fromJson: _stringToDouble)
  final double listeningScore;
  @JsonKey(
      name: 'score_structure', defaultValue: 0.0, fromJson: _stringToDouble)
  final double structureScore;
  @JsonKey(name: 'score_reading', defaultValue: 0.0, fromJson: _stringToDouble)
  final double readingScore;
  @JsonKey(name: 'score_toefl', defaultValue: 0.0, fromJson: _stringToDouble)
  final double totalScore;
  @JsonKey(name: 'created_at', defaultValue: '')
  final String? createdAt;
  @JsonKey(name: 'answered_question', defaultValue: 0)
  final int answeredQuestion;

  HistoryItem({
    required this.id,
    this.success = false,
    this.message = '',
    required this.type,
    required this.listeningScore,
    required this.structureScore,
    required this.readingScore,
    required this.totalScore,
    this.createdAt,
    this.answeredQuestion = 0,
  });

  // Helper function to convert String to double - HARUS STATIC
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

  factory HistoryItem.fromJson(Map<String, dynamic> json) =>
      _$HistoryItemFromJson(json);

  factory HistoryItem.fromJsonString(String jsonString) =>
      _$HistoryItemFromJson(jsonDecode(jsonString));

  // Factory for API response dengan payload
  factory HistoryItem.fromApiResponse(Map<String, dynamic> json, String type,
      {String? createdAt}) {
    final payload = json['payload'] as Map<String, dynamic>?;

    if (payload == null) {
      return HistoryItem(
        id: '',
        success: json['success'] ?? false,
        message: json['message'] ?? 'No data',
        type: type,
        listeningScore: 0.0,
        structureScore: 0.0,
        readingScore: 0.0,
        totalScore: 0.0,
        createdAt: createdAt ?? '2025-06-01T13:16:06.000Z',
        answeredQuestion: 0,
      );
    }

    return HistoryItem(
      id: payload['id'] ?? '',
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      type: type,
      listeningScore: _stringToDouble(payload['score_listening']),
      structureScore: _stringToDouble(payload['score_structure']),
      readingScore: _stringToDouble(payload['score_reading']),
      totalScore: _stringToDouble(payload['score_toefl']),
      createdAt: createdAt ?? '2025-06-01T13:16:06.000Z',
      answeredQuestion: payload['answered_question'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => _$HistoryItemToJson(this);

  String toStringJson() => jsonEncode(toJson());

  // Helper methods untuk display
  String get formattedDateTime {
    if (createdAt == null || createdAt!.isEmpty) return '2025-06-01 13:16';

    try {
      final dateTime = DateTime.parse(createdAt!);
      final dateStr =
          '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
      final timeStr =
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      return '$dateStr $timeStr';
    } catch (e) {
      return '2025-06-01 13:16';
    }
  }

  String get displayListening =>
      listeningScore > 0 ? listeningScore.toStringAsFixed(0) : '0';
  String get displayStructure =>
      structureScore > 0 ? structureScore.toStringAsFixed(0) : '0';
  String get displayReading =>
      readingScore > 0 ? readingScore.toStringAsFixed(0) : '0';
  String get displayTotal =>
      totalScore > 0 ? totalScore.toStringAsFixed(0) : '0';

  // Method untuk check apakah item valid
  // Ubah kondisi: tampilkan jika success=true DAN ada answered_question > 0
  bool get isValid => success && answeredQuestion > 0;

  // Method untuk check apakah ujian sudah dimulai
  bool get hasStarted => success && answeredQuestion > 0;

  // Method untuk check apakah ujian sudah selesai
  bool get isCompleted => success && totalScore > 0;
}
