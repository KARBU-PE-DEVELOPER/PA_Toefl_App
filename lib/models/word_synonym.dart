import 'package:json_annotation/json_annotation.dart';

part 'word_synonym.g.dart';

@JsonSerializable()
class WordSynonym {
  @JsonKey(name: "_id")
  Id? id; // Made nullable for AI-generated words
  @JsonKey(name: "Word")
  String word;
  @JsonKey(name: "Synonyms")
  List<String> synonyms;

  WordSynonym({
    this.id, // Allow null for dynamically generated IDs
    required this.word,
    required this.synonyms,
  });

  factory WordSynonym.fromJson(Map<String, dynamic> json) => _$WordSynonymFromJson(json);

  Map<String, dynamic> toJson() => _$WordSynonymToJson(this);
}

@JsonSerializable()
class Id {
  @JsonKey(name: "\$oid")
  String oid;

  Id({
    required this.oid,
  });

  factory Id.fromJson(Map<String, dynamic> json) => _$IdFromJson(json);

  Map<String, dynamic> toJson() => _$IdToJson(this);
}
