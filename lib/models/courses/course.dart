import 'package:json_annotation/json_annotation.dart';
import 'media_resource.dart';

part 'course.g.dart';

@JsonSerializable()
class Course {
  final int id;

  @JsonKey(name: 'course_name')
  final String courseName;

  @JsonKey(name: 'course_type')
  final String courseType;

  final String? description;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  final List<MediaResource> audio;
  final List<MediaResource> video;
  final List<MediaResource> ebook;

  Course({
    required this.id,
    required this.courseName,
    required this.courseType,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.audio = const [],
    this.video = const [],
    this.ebook = const [],
  });

  factory Course.fromJson(Map<String, dynamic> json) => _$CourseFromJson(json);

  Map<String, dynamic> toJson() => _$CourseToJson(this);
}
