import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'test_status.g.dart';

@JsonSerializable()
class TestStatus {
  @JsonKey(defaultValue: '')
  final String id;
  @JsonKey(name: 'start_time', defaultValue: '')
  final String startTime;
  @JsonKey(name: 'reset_table', defaultValue: false)
  final bool resetTable;
  @JsonKey(name: 'name', defaultValue: '')
  final String name;
  @JsonKey(name: "is_retake", defaultValue: false)
  final bool isRetake;

  TestStatus({
    required this.id,
    required this.startTime,
    required this.resetTable,
    required this.name,
    required this.isRetake,
  });

  factory TestStatus.fromJson(Map<String, dynamic> json) =>
      _$TestStatusFromJson(json);

  factory TestStatus.fromJsonString(String jsonString) =>
      _$TestStatusFromJson(jsonDecode(jsonString));

  Map<String, dynamic> toJson() => _$TestStatusToJson(this);

  String toStringJson() => jsonEncode(toJson());
}
