import 'package:json_annotation/json_annotation.dart';
import 'package:toefl/models/courses/course.dart';

part 'course_detail_response.g.dart';

@JsonSerializable()
class CourseDetailResponse {
  final bool success;
  final String message;
  final Course? payload;

  CourseDetailResponse(
      {required this.success, required this.message, this.payload});

  factory CourseDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$CourseDetailResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CourseDetailResponseToJson(this);
}
