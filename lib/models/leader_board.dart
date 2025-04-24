import 'package:json_annotation/json_annotation.dart';

part 'leader_board.g.dart';

@JsonSerializable()
class LeaderBoard {
  @JsonKey(name: 'user_id')
  final int userId;

  @JsonKey(name: 'user_name')
  final String userName;

  @JsonKey(name: 'highest_score')
  final String highestScore;

  LeaderBoard({
    required this.userId,
    required this.userName,
    required this.highestScore,
  });

  factory LeaderBoard.fromJson(Map<String, dynamic> json) =>
      _$LeaderBoardFromJson(json);

  Map<String, dynamic> toJson() => _$LeaderBoardToJson(this);
}
