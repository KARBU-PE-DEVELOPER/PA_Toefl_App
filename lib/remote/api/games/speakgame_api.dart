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

      // Decode JSON jika masih berupa String
      final Map<String, dynamic> decodedData = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      if (decodedData.containsKey('payload') &&
          decodedData['payload'].containsKey('sentence')) {
        final List<dynamic> sentence = decodedData['payload']['sentence'];

        return sentence
            .whereType<
                Map<String, dynamic>>() // Pastikan hanya map yang diproses
            .map((e) => SpeakGame.fromJson(e))
            .toList();
      } else {
        throw Exception("Format response tidak sesuai");
      }
    } catch (e) {
      throw Exception("Error fetching words: $e");
    }
  }
}
