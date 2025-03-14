import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:toefl/models/ask-ai/ask-ai_detail.dart';
import 'package:flutter/cupertino.dart';
import 'package:toefl/remote/dio_toefl.dart';
import 'package:toefl/remote/env.dart';

import '../base_response.dart';

class AskAIAPI {
  final Dio? dio;

  AskAIAPI({this.dio});
  Future<AskAI?> storeMessage(Map<String, dynamic> request) async {
    try {
      final Response rawResponse = await DioToefl.instance.post(
        '${Env.apiUrl}/grammar/ask-ai',
        data: request,
      );

      final BaseResponse response = BaseResponse.fromRawJson(rawResponse.data);

      if (response.payload == null ||
          response.payload is! Map<String, dynamic>) {
        throw Exception("API returned an invalid payload");
      }

      final Map<String, dynamic> dataMessage = response.payload;

      return AskAI.fromJson(dataMessage);
    } catch (e) {
      print("Error in storeMessage API: $e");
      return null;
    }
  }


  Future<List<AskAI>> getAllAskGrammar() async {
    try {
      final Response rawResponse =
          await DioToefl.instance.get('${Env.apiUrl}/grammar/get-history');

      final response = BaseResponse.fromJson(json.decode(rawResponse.data));
      return (response.payload as List)
          .map((e) => AskAI.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
}