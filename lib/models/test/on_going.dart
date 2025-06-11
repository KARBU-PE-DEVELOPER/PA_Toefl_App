import 'package:flutter/material.dart';
import 'package:toefl/models/test/test_status.dart';

class OngoingTestData {
  final List<UserAnswer> userAnswers;
  final PacketClaim? packetClaim;

  OngoingTestData({
    required this.userAnswers,
    this.packetClaim,
  });

  factory OngoingTestData.fromJson(Map<String, dynamic> json) {
    debugPrint("🔧 Parsing OngoingTestData from API response");

    List<UserAnswer> answers = [];
    if (json['user_answer'] != null) {
      answers = (json['user_answer'] as List)
          .map((e) => UserAnswer.fromJson(e))
          .toList();
      debugPrint("📝 Parsed ${answers.length} user answers");
    }

    PacketClaim? claim;
    if (json['packet_claim'] != null) {
      claim = PacketClaim.fromJson(json['packet_claim']);
      debugPrint(
          "📦 Parsed packet claim: ${claim.completed ? 'completed' : 'ongoing'}");
    }

    return OngoingTestData(
      userAnswers: answers,
      packetClaim: claim,
    );
  }
}

class UserAnswer {
  final String id;
  final int packetClaimId;
  final int questionId;
  final String answerUser;
  final bool correct;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserAnswer({
    required this.id,
    required this.packetClaimId,
    required this.questionId,
    required this.answerUser,
    required this.correct,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserAnswer.fromJson(Map<String, dynamic> json) {
    return UserAnswer(
      id: json['id']?.toString() ?? '',
      packetClaimId: json['packet_claim_id'] ?? 0,
      questionId: json['question_id'] ?? 0,
      answerUser: json['answer_user'] ?? '',
      correct: json['correct'] ?? false,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class PacketClaim {
  final bool completed;
  final String timeStart;

  PacketClaim({
    required this.completed,
    required this.timeStart,
  });

  factory PacketClaim.fromJson(Map<String, dynamic> json) {
    return PacketClaim(
      completed: json['completed'] ?? false,
      timeStart: json['time_start'] ?? '',
    );
  }
}

// Tambahkan extension ini jika belum ada
extension TestStatusExtension on TestStatus {
  TestStatus copyWith({
    String? id,
    String? startTime,
    String? name,
    bool? resetTable,
    bool? isRetake,
  }) {
    return TestStatus(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      name: name ?? this.name,
      resetTable: resetTable ?? this.resetTable,
      isRetake: isRetake ?? this.isRetake,
    );
  }
}
