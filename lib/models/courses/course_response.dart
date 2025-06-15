import 'package:json_annotation/json_annotation.dart';
import 'package:toefl/models/courses/course.dart';

part 'course_response.g.dart';

@JsonSerializable()
class CourseResponse {
  final bool success;
  final String message;
  final CoursePayload payload;

  CourseResponse(
      {required this.success, required this.message, required this.payload});

  factory CourseResponse.fromJson(Map<String, dynamic> json) =>
      _$CourseResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CourseResponseToJson(this);
}

@JsonSerializable()
class CoursePayload {
  final List<Course> reading;
  final List<Course> listening;
  final List<Course> structure;

  CoursePayload({
    required this.reading,
    required this.listening,
    required this.structure,
  });

  factory CoursePayload.fromJson(Map<String, dynamic> json) =>
      _$CoursePayloadFromJson(json);

  Map<String, dynamic> toJson() => _$CoursePayloadToJson(this);
}
