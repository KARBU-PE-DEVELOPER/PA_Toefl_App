import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:toefl/models/games/cloze_game.dart';
import 'package:toefl/remote/dio_toefl.dart';
import 'package:toefl/remote/env.dart';
import '../../base_response.dart';

class ClozeGameApi {
  final Dio _dio = DioToefl.instance;

  Future<List<ClozeQuestion>> fetchClozeQuestions() async {
    try {
      final Response rawResponse = await _dio.get(
        '${Env.gameUrl}/clozeGame/get-cloze-word',
      );

      print("API Response (Cloze): ${rawResponse.data}");

      final Map<String, dynamic> decodedData = rawResponse.data is String
          ? jsonDecode(rawResponse.data)
          : rawResponse.data;

      return parseClozeQuestions(decodedData);
    } catch (e) {
      print("Error in fetchClozeQuestions API: $e");
      return [];
    }
  }

  Future<bool> submitClozeResult(double score) async {
    try {
      final Response rawResponse = await _dio.post(
        '${Env.gameUrl}/clozeGame/submit-answers',
        data: {
          'score': score,
        },
      );

      print("Submit Response (Cloze): ${rawResponse.data}");

      final Map<String, dynamic> decodedData = rawResponse.data is String
          ? jsonDecode(rawResponse.data)
          : rawResponse.data;

      final response = BaseResponse.fromJson(decodedData);
      return response.payload;
    } catch (e) {
      print("Error submitting cloze result: $e");
      return false;
    }
  }
}
