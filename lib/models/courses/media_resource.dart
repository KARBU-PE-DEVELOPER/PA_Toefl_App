import 'package:json_annotation/json_annotation.dart';

part 'media_resource.g.dart';

@JsonSerializable()
class MediaResource {
  final int id;
  final String title;

  @JsonKey(name: 'file_url')
  final String fileUrl;

  MediaResource({
    required this.id,
    required this.title,
    required this.fileUrl,
  });

  factory MediaResource.fromJson(Map<String, dynamic> json) =>
      _$MediaResourceFromJson(json);

  Map<String, dynamic> toJson() => _$MediaResourceToJson(this);
}
