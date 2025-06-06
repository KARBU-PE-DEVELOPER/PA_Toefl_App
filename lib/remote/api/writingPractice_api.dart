import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:toefl/models/grammar-commentator/grammarCommentator_detail.dart';
import 'package:toefl/models/grammar-commentator/question-grammarCommentator_detail.dart';
import 'package:toefl/remote/dio_toefl.dart';
import 'package:toefl/remote/env.dart';
import 'package:toefl/exceptions/exceptions.dart';

import '../base_response.dart';

class GrammarCommentatorAPI {
  final Dio? dio;

  GrammarCommentatorAPI({this.dio});
  Future<GrammarCommentator?> storeMessage(Map<String, dynamic> request) async {
    try {
      final Response rawResponse = await DioToefl.instance.post(
        '${Env.gameUrl}/writing-practice/ask-ai',
        data: request,
      );

      final BaseResponse response = BaseResponse.fromRawJson(rawResponse.data);

      final Map<String, dynamic> dataMessage = response.payload;

      return GrammarCommentator.fromJson(dataMessage);
    } on DioException catch (e) {
      if (e.response != null && e.response!.statusCode == 500) {
        final data = e.response!.data;
        String message;

        // Jika response berbentuk JSON string
        if (data is String) {
          final jsonData = json.decode(data);
          message = jsonData['message'] ?? "Validation error";
        }
        // Jika response sudah berupa map
        else if (data is Map<String, dynamic>) {
          message = data['message'] ?? "Validation error";
        } else {
          message = "Validation error";
        }

        throw ApiException(message);
      }
    } catch (e) {
      print("Error in storeMessage API: $e");
      return null;
    }
  }

  Future<QuestionGrammarCommentator?> getQuestion() async {
    try {
      final Response rawResponse = await DioToefl.instance
          .get('${Env.gameUrl}/writing-practice/get-statement');

      final BaseResponse response = BaseResponse.fromRawJson(rawResponse.data);

      final Map<String, dynamic> dataMessage = response.payload;

      return QuestionGrammarCommentator.fromJson(dataMessage);
    } on DioException catch (e) {
      if (e.response != null && e.response!.statusCode == 500) {
        final data = e.response!.data;
        String message;

        // Jika response berbentuk JSON string
        if (data is String) {
          final jsonData = json.decode(data);
          message = jsonData['message'] ?? "Validation error";
        }
        // Jika response sudah berupa map
        else if (data is Map<String, dynamic>) {
          message = data['message'] ?? "Validation error";
        } else {
          message = "Validation error";
        }

        throw ApiException(message);
      }
    } catch (e) {
      print("Error in storeMessage API: $e");
      return null;
    }
  }

  Future<List<GrammarCommentator>> getAllGrammarCommentator() async {
    try {
      final Response rawResponse = await DioToefl.instance
          .get('${Env.gameUrl}/writing-practice/get-history');

      final response = BaseResponse.fromJson(json.decode(rawResponse.data));
      return (response.payload as List)
          .map((e) => GrammarCommentator.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
