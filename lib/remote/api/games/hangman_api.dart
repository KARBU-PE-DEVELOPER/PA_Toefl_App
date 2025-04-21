import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:toefl/models/games/hangman_game.dart';
import 'package:toefl/remote/dio_toefl.dart';
import 'package:toefl/remote/env.dart';
import '../../base_response.dart';

class HangmanGameApi {
  final Dio _dio = DioToefl.instance;

  Future<HangmanData?> fetchHangmanWord() async {
    try {
      final Response rawResponse = await _dio.get(
        '${Env.gameUrl}/hangmanGame/get-hangman-word',
      );

      print("API Response (Hangman): ${rawResponse.data}");

      final Map<String, dynamic> decodedData = rawResponse.data is String
          ? jsonDecode(rawResponse.data)
          : rawResponse.data;

      return parseHangmanData(decodedData);
    } catch (e) {
      print("Error fetching Hangman word: $e");
      return null;
    }
  }

  Future<bool> submitHangmanResult(double score) async {
    try {
      final Response rawResponse = await _dio.post(
        '${Env.gameUrl}/hangmanGame/submit-answers',
        data: {
          'score': score,
        },
      );

      print("Submit Response (Hangman): ${rawResponse.data}");

      final Map<String, dynamic> decodedData = rawResponse.data is String
          ? jsonDecode(rawResponse.data)
          : rawResponse.data;

      final response = BaseResponse.fromJson(decodedData);
      return response.payload;
    } catch (e) {
      print("Error submitting Hangman result: $e");
      return false;
    }
  }
}
