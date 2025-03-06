import 'package:json_annotation/json_annotation.dart';

part 'pairing_game.g.dart';

@JsonSerializable()
class SynonymPair {
  @JsonKey(defaultValue: '', name: 'word')
  final String word;
  
  @JsonKey(defaultValue: '', name: 'synonym')
  final String synonym;

  SynonymPair({required this.word, required this.synonym});

  factory SynonymPair.fromJson(Map<String, dynamic> json) {
    return SynonymPair(
      word: json['word'] as String? ?? '',
      synonym: json['synonym'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'word': word,
        'synonym': synonym,
      };
}

List<SynonymPair> parseWordPairs(Map<String, dynamic> json) {
  try {
    print("JSON received in parseWordPairs: $json");

    if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      final wordPairs = json['data']['wordPairs'];

      print("WordPairs data: $wordPairs");

      if (wordPairs is List && wordPairs.isNotEmpty) {
        return wordPairs.map((pair) {
          if (pair is Map<String, dynamic>) {
            return SynonymPair.fromJson(pair);
          }
          return SynonymPair(word: '', synonym: '');
        }).toList();
      }
    }
  } catch (e) {
    print("Error parsing word pairs: ${e.toString()}");
  }

  return [];
}
