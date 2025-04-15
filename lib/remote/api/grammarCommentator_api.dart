import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:toefl/models/grammar-commentator/grammarCommentator_detail.dart';
import 'package:flutter/cupertino.dart';
import 'package:toefl/models/grammar-commentator/question-grammarCommentator_detail.dart';
import 'package:toefl/remote/dio_toefl.dart';
import 'package:toefl/remote/env.dart';

import '../base_response.dart';

class GrammarCommentatorAPI {
  final Dio? dio;

  GrammarCommentatorAPI({this.dio});
  Future<GrammarCommentator?> storeMessage(Map<String, dynamic> request) async {
    try {
      final Response rawResponse = await DioToefl.instance.post(
        '${Env.apiUrl}/grammar-commentator/ask-ai',
        data: request,
      );

      final BaseResponse response = BaseResponse.fromRawJson(rawResponse.data);

      if (response.payload == null ||
          response.payload is! Map<String, dynamic>) {
        throw Exception("API returned an invalid payload");
      }

      final Map<String, dynamic> dataMessage = response.payload;

      return GrammarCommentator.fromJson(dataMessage);
    } catch (e) {
      print("Error in storeMessage API: $e");
      return null;
    }
  }

  Future<QuestionGrammarCommentator?> getQuestion() async {
    try {
      final Response rawResponse = await DioToefl.instance
          .get('${Env.apiUrl}/grammar-commentator/get-question');

      final BaseResponse response = BaseResponse.fromRawJson(rawResponse.data);

      final Map<String, dynamic> dataMessage = response.payload;

      return QuestionGrammarCommentator.fromJson(dataMessage);
    } catch (e) {
      print("Error in storeMessage API: $e");
      return null;
    }
  }

  Future<List<GrammarCommentator>> getAllGrammarCommentator() async {
    try {
      final Response rawResponse = await DioToefl.instance
          .get('${Env.apiUrl}/grammar-commentator/get-history');

      final response = BaseResponse.fromJson(json.decode(rawResponse.data));
      return (response.payload as List)
          .map((e) => GrammarCommentator.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
