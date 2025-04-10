import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:toefl/models/games/speak_game.dart';
import 'package:toefl/remote/dio_toefl.dart';
import 'package:toefl/remote/env.dart';
import '../../base_response.dart';

class SpeakGameApi {
  final Dio? dio;
  SpeakGameApi({this.dio});
  Future<List<SpeakGame>> getWord() async {
    try {
      final response = await DioToefl.instance
          .get("${Env.apiUrl}/minigames/speakingGames/get-speaking-word");

      if (response.statusCode == 200) {
        final List<dynamic> sentenceList = response.data['payload']['sentence'];
        return sentenceList
            .map((s) => SpeakGame.fromJson({'sentence': s}))
            .toList();
      } else {
        throw Exception("Failed to load words");
      }
    } catch (e) {
      throw Exception("Error fetching words: $e");
    }
  }
}
