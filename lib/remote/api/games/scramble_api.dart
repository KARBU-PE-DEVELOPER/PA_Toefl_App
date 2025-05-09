import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:toefl/models/games/scramble_game.dart';
import 'package:toefl/remote/dio_toefl.dart';
import 'package:toefl/remote/env.dart';
import '../../base_response.dart';

class ScrambleGameApi {
  final Dio _dio = DioToefl.instance;

  Future<ScrambleData?> fetchScrambleWord() async {
    try {
      final Response rawResponse = await _dio.get(
        '${Env.gameUrl}/minigames/scrabbleWordGame/get-scrabble-word',
      );

      print("API Response (Scramble): ${rawResponse.data}");

      final Map<String, dynamic> decodedData = rawResponse.data is String
          ? jsonDecode(rawResponse.data)
          : rawResponse.data;

      return parseScrambleData(decodedData);
    } catch (e) {
      print("Error fetching Scramble word: $e");
      return null;
    }
  }

  Future<bool> submitScrambleResult(double score) async {
    try {
      final Response rawResponse = await _dio.post(
        '${Env.gameUrl}/minigames/scrabbleeGame/submit-answers',
        data: {
          'score': score,
        },
      );

      print("Submit Response (Scramble): ${rawResponse.data}");

      final Map<String, dynamic> decodedData = rawResponse.data is String
          ? jsonDecode(rawResponse.data)
          : rawResponse.data;

      final response = BaseResponse.fromJson(decodedData);
      return response.payload;
    } catch (e) {
      print("Error submitting Scramble result: $e");
      return false;
    }
  }
}
