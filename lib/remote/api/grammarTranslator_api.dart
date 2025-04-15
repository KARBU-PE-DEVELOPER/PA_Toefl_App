
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:toefl/models/grammar-translator/grammarTranslator_detail.dart';
import 'package:flutter/cupertino.dart';
import 'package:toefl/models/grammar-translator/question-grammarTranslator_detail.dart';
import 'package:toefl/remote/dio_toefl.dart';
import 'package:toefl/remote/env.dart';

import '../base_response.dart';

class GrammarTranslatorAPI {
  final Dio? dio;

  GrammarTranslatorAPI({this.dio});
  Future<GrammarTranslator?> storeMessage(Map<String, dynamic> request) async {
    try {
      final Response rawResponse = await DioToefl.instance.post(
        '${Env.apiUrl}/grammar-translator/ask-ai',
        data: request,
      );

      final BaseResponse response = BaseResponse.fromRawJson(rawResponse.data);

      if (response.payload == null ||
          response.payload is! Map<String, dynamic>) {
        throw Exception("API returned an invalid payload");
      }

      final Map<String, dynamic> dataMessage = response.payload;

      return GrammarTranslator.fromJson(dataMessage);
    } catch (e) {
      print("Error in storeMessage API: $e");
      return null;
    }
  }

  Future<QuestionGrammarTranslator?> getQuestion() async {
    try {
      final Response rawResponse = await DioToefl.instance.get(
        '${Env.apiUrl}/grammar-translator/get-question');

      final BaseResponse response = BaseResponse.fromRawJson(rawResponse.data);

      final Map<String, dynamic> dataMessage = response.payload;

      return QuestionGrammarTranslator.fromJson(dataMessage);
    } catch (e) {
      print("Error in storeMessage API: $e");
      return null;
    }
  }


  Future<List<GrammarTranslator>> getAllGrammarTranslator() async {
    try {
      final Response rawResponse =
          await DioToefl.instance.get('${Env.apiUrl}/grammar-translator/get-history');

      final response = BaseResponse.fromJson(json.decode(rawResponse.data));
      return (response.payload as List)
          .map((e) => GrammarTranslator.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
}