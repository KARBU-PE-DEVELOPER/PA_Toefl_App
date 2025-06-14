import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'profile.g.dart';

@JsonSerializable()
class Profile {
  final dynamic id;
  final String level;
  @JsonKey(name: 'current_score', fromJson: _toDouble, defaultValue: 0.0)
  double currentScore;
  @JsonKey(name: 'target_score', fromJson: _toDouble, defaultValue: 0.0)
  double targetScore;
  @JsonKey(name: 'name_user', defaultValue: '')
  final String nameUser;
  // @JsonKey(defaultValue: 0)
  // int rank;
  @JsonKey(name: 'profile_image', defaultValue: '')
  final String profileImage;
  // @JsonKey(name: 'is_friend', defaultValue: false)
  // final bool isFriend;

  Profile({
    required this.id,
    required this.level,
    required this.currentScore,
    required this.targetScore,
    required this.nameUser,
    // required this.rank,
    required this.profileImage,
    // required this.isFriend,
  });
  static double _toDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    if (value is double) return value;
    return 0.0;
  }

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
      nameUser: nameUser,
      // rank: rank,
      profileImage: profileImage,
      // isFriend: isFriend ?? this.isFriend,
    );
  }
}