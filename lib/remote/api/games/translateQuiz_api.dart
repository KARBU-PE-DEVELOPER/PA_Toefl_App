import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:toefl/models/translate_quiz/translateQuiz_detail.dart';
import 'package:flutter/cupertino.dart';
import 'package:toefl/models/translate_quiz/questionTranslateQuiz_detail.dart';
import 'package:toefl/remote/dio_toefl.dart';
import 'package:toefl/remote/env.dart';

import '../../base_response.dart';

class TranslateQuizAPI {
  final Dio? dio;

  TranslateQuizAPI({this.dio});
  Future<TranslateQuiz?> storeMessage(Map<String, dynamic> request) async {
    try {
      final Response rawResponse = await DioToefl.instance.post(
        '${Env.gameUrl}/minigames/translateQuizGames/submit-answers',
        data: request,
      );

      final BaseResponse response = BaseResponse.fromRawJson(rawResponse.data);

      if (response.payload == null ||
          response.payload is! Map<String, dynamic>) {
        throw Exception("API returned an invalid payload");
      }

      final Map<String, dynamic> dataMessage = response.payload;

      return TranslateQuiz.fromJson(dataMessage);
    } catch (e) {
      print("Error in storeMessage API: $e");
      return null;
    }
  }

  Future<QuestionTranslateQuiz?> getQuestion() async {
    try {
      final Response rawResponse = await DioToefl.instance
          .get('${Env.gameUrl}/minigames/translateQuizGames/get-question');

      final BaseResponse response = BaseResponse.fromRawJson(rawResponse.data);

      final Map<String, dynamic> dataMessage = response.payload;

      return QuestionTranslateQuiz.fromJson(dataMessage);
    } catch (e) {
      print("Error in storeMessage API: $e");
      return null;
    }
  }

  Future<List<TranslateQuiz>> getAllTranslateQuiz() async {
    try {
      final Response rawResponse = await DioToefl.instance
          .get('${Env.gameUrl}/minigames/translateQuizGames/get-history');

      final response = BaseResponse.fromJson(json.decode(rawResponse.data));
      return (response.payload as List)
          .map((e) => TranslateQuiz.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
