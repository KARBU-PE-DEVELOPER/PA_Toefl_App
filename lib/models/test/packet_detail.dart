import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../utils/utils.dart';

part 'packet_detail.g.dart';

@JsonSerializable()
class PacketDetail extends Equatable {
  @JsonKey(defaultValue: '')
  final dynamic id;
  @JsonKey(name: 'packet_name')
  final String name;
  final List<Question> questions;

  PacketDetail({
    required this.id,
    required this.name,
    required this.questions,
  });

  // Helper function to parse ID as String
  static String _parseId(dynamic id) => id.toString();

  factory PacketDetail.fromJson(Map<String, dynamic> json) =>
      _$PacketDetailFromJson(json);

  factory PacketDetail.fromJsonString(String jsonString) =>
      _$PacketDetailFromJson(Utils.stringToJson(jsonString));

  Map<String, dynamic> toJson() => _$PacketDetailToJson(this);

  String toStringJson() => toJson().toString();

  @override
  List<Object?> get props => [id, name, questions];
}

@JsonSerializable()
class Question {
  @JsonKey(fromJson: _parseId, defaultValue: '')
  final String id; // Changed to String
  @JsonKey(defaultValue: '')
  final String question;
  @JsonKey(name: 'type_question', defaultValue: '')
  final String typeQuestion;
  @JsonKey(name: 'nested_question_id', fromJson: _parseId, defaultValue: '')
  final String nestedQuestionId;
  @JsonKey(name: 'multiple_choices', defaultValue: [])
  final List<Choice> choices;
  @JsonKey(defaultValue: '', name: 'nested_question')
  final String bigQuestion;
  @JsonKey(defaultValue: '')
  String answer;
  @JsonKey(defaultValue: 0)
  final int bookmarked;
  @JsonKey(defaultValue: 0)
  final int number;
  @JsonKey(name: 'packet_claim', defaultValue: '')
  final String packetClaim;

  Question({
    required this.id,
    required this.question,
    required this.typeQuestion,
    required this.nestedQuestionId,
    required this.choices,
    required this.bigQuestion,
    required this.answer,
    required this.bookmarked,
    required this.number,
    required this.packetClaim,
  });

  // Helper function to parse ID as String
  static String _parseId(dynamic id) => id.toString();

  factory Question.fromJson(Map<String, dynamic> json) =>
      _$QuestionFromJson(json);

  factory Question.fromJsonString(String jsonString) =>
      _$QuestionFromJson(Utils.stringToJson(jsonString));

  Map<String, dynamic> toJson() => _$QuestionToJson(this);

  String toStringJson() => toJson().toString();
}

@JsonSerializable()
class Choice {
  @JsonKey(fromJson: _parseId, defaultValue: '')
  final String id; // Changed to String
  @JsonKey(defaultValue: '')
  final String choice;

  Choice({
    required this.id,
    required this.choice,
  });

  // Helper function to parse ID as String
  static String _parseId(dynamic id) => id.toString();

  factory Choice.fromJson(Map<String, dynamic> json) => _$ChoiceFromJson(json);

  factory Choice.fromJsonString(String jsonString) =>
      _$ChoiceFromJson(jsonDecode(jsonString));

  Map<String, dynamic> toJson() => _$ChoiceToJson(this);

  String toStringJson() => jsonEncode(toJson());
}

@JsonSerializable()
class UserAnswer {
  final int id;

  @JsonKey(name: 'packet_claim_id')
  final int packetClaimId;

  @JsonKey(name: 'question_id')
  final int questionId;

  @JsonKey(name: 'answer_user')
  final String answerUser;

  final bool correct;

  @JsonKey(name: 'created_at')
  final String createdAt;

  @JsonKey(name: 'updated_at')
  final String updatedAt;

  UserAnswer({
    required this.id,
    required this.packetClaimId,
    required this.questionId,
    required this.answerUser,
    required this.correct,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserAnswer.fromJson(Map<String, dynamic> json) =>
      _$UserAnswerFromJson(json);

  Map<String, dynamic> toJson() => _$UserAnswerToJson(this);
}

@JsonSerializable()
class PacketClaim {
  final bool completed;

  @JsonKey(name: 'time_start')
  final String? timeStart;

  @JsonKey(name: 'remaining_time')
  final int remainingTime;

  PacketClaim({
    required this.completed,
    required this.timeStart,
    required this.remainingTime,
  });

  factory PacketClaim.fromJson(Map<String, dynamic> json) =>
      _$PacketClaimFromJson(json);

  Map<String, dynamic> toJson() => _$PacketClaimToJson(this);
}
