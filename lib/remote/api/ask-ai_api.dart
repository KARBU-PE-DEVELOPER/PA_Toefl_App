import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:toefl/models/ask-ai/ask-ai_detail.dart';
import 'package:flutter/cupertino.dart';
import 'package:toefl/remote/dio_toefl.dart';
import 'package:toefl/remote/env.dart';

import '../base_response.dart';

class AskAIAPI {
  // Future<AskAI> storeMessage(List<Map<String, dynamic>> r) async {
  //   try {
  //     final Response rawResponse = await DioToefl.instance.post(
  //       '${Env.apiUrl}/grammar/ask-ai',
  //       data: {'user_message': userMessage},
  //     );

  //     final response = BaseResponse.fromJson(rawResponse.data);
  //     return BaseResponse.fromJson(rawResponse.payload);
  //   } catch (e) {
  //     print("Error in storeMessage API: $e");
  //     return PacketDetail(
  //       id: "", name: "", questions: [], startTime: "", status: "");
  //     }
  //   }
  // }

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
