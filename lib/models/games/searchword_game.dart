import 'package:json_annotation/json_annotation.dart';

part 'searchword_game.g.dart';

@JsonSerializable()
class SearchWord {
  final List<String> words;

  SearchWord({required this.words});

  factory SearchWord.fromJson(Map<String, dynamic> json) =>
      _$SearchWordFromJson(json);

  Map<String, dynamic> toJson() => _$SearchWordToJson(this);
}

