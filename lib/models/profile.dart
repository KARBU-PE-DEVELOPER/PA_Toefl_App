import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'profile.g.dart';

@JsonSerializable()
class Profile {
  final int id;
  
  @JsonKey(name: 'level', defaultValue: "")
  String level;
  @JsonKey(name: 'current_score', defaultValue: "")
  int currentScore;
  @JsonKey(name: 'target_score', defaultValue: 0)
  int targetScore;
  // @JsonKey(defaultValue: 0)
  // int rank;
  @JsonKey(name: 'profile_image', defaultValue: '')
  final String profileImage;
  @JsonKey(name: 'name_user', defaultValue: '')
  final String nameUser;
  @JsonKey(name: 'email_user', defaultValue: '')
  final String emailUser;
  // @JsonKey(name: 'is_friend', defaultValue: false)
  // final bool isFriend;

  Profile({
    required this.id,
    required this.level,
    required this.currentScore,
    required this.targetScore,
    // required this.rank,
    required this.profileImage,
    required this.nameUser,
    required this.emailUser,
    // required this.isFriend,
  });

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);

  factory Profile.fromJsonString(String jsonString) =>
      _$ProfileFromJson(jsonDecode(jsonString));

  Map<String, dynamic> _toJson() => _$ProfileToJson(this);

  String toStringJson() => _toJson().toString();

  Profile copyWith({
    bool? isFriend,
  }) {
    return Profile(
      id: id,
      level: level,
      currentScore: currentScore,
      targetScore: targetScore,
      profileImage: profileImage,
      nameUser: nameUser,
      emailUser: emailUser,
      // isFriend: isFriend ?? this.isFriend,
    );
  }
}
