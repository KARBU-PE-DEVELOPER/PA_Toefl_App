import 'package:json_annotation/json_annotation.dart';

part 'cloze_game.g.dart';

@JsonSerializable()
class ClozeQuestion {
  @JsonKey(defaultValue: '', name: 'question')
  final String question;

  @JsonKey(defaultValue: '', name: 'key_answer')
  final String keyAnswer;

  @JsonKey(defaultValue: [], name: 'answers')
  final List<String> answers;

  ClozeQuestion({
    required this.question,
    required this.keyAnswer,
    required this.answers,
  });

  factory ClozeQuestion.fromJson(Map<String, dynamic> json) =>
      _$ClozeQuestionFromJson(json);

  Map<String, dynamic> toJson() => _$ClozeQuestionToJson(this);
}

List<ClozeQuestion> parseClozeQuestions(Map<String, dynamic> json) {
  try {
    if (json.containsKey('payload') && json['payload'] is List) {
      final rawList = json['payload'] as List;

      return rawList.map((item) {
        if (item is Map<String, dynamic>) {
          return ClozeQuestion.fromJson(item);
        }
        return ClozeQuestion(question: '', keyAnswer: '', answers: []);
      }).toList();
    }
  } catch (e) {
    print("Error parsing Cloze Questions: ${e.toString()}");
  }

  return [];
}
