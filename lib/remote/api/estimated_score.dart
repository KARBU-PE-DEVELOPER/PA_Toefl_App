import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:toefl/models/estimated_score.dart';
import 'package:toefl/remote/base_response.dart';
import 'package:toefl/remote/dio_toefl.dart';
import 'package:toefl/remote/env.dart';

class EstimatedScoreApi {
  Future<EstimatedScore> getEstimatedScore() async {
    try {
      final Response rawResponse =
          await DioToefl.instance.get('${Env.userUrl}/get-score-toefl');

      debugPrint("Raw Response: ${rawResponse.data}");

      // Parse response data
      Map<String, dynamic> responseData;
      if (rawResponse.data is String) {
        responseData = json.decode(rawResponse.data);
      } else {
        responseData = rawResponse.data;
      }

      debugPrint("Response Data: $responseData");

      final response = BaseResponse.fromJson(responseData);
      debugPrint("Payload: ${response.payload}");

      // Handle payload sebagai array
      if (response.payload is List && (response.payload as List).isNotEmpty) {
        // Ambil item pertama dari array
        final firstItem = (response.payload as List)[0];
        debugPrint("First item from payload: $firstItem");

        if (firstItem is Map<String, dynamic>) {
          return EstimatedScore.fromJson(firstItem);
        } else {
          throw Exception("First item in payload is not a Map");
        }
      } else if (response.payload is Map<String, dynamic>) {
        // Fallback jika payload masih berupa object (backward compatibility)
        return EstimatedScore.fromJson(response.payload);
      } else {
        throw Exception(
            "Payload is neither a List nor a Map, or List is empty");
      }
    } catch (e, stack) {
      debugPrint("Error in getEstimatedScore: $e");
      debugPrint("Stack trace: $stack");

      return EstimatedScore(
        targetUser: 0,
        userScore: "0.00",
        scoreListening: "0.00",
        scoreStructure: "0.00",
        scoreReading: "0.00",
      );
    }
  }

  Future<EstimatedScore> addAndUpdateScore(Map<String, dynamic> request) async {
    try {
      final Response rawResponse = await DioToefl.instance.post(
        '${Env.simulationUrl}/add-and-patch-target',
        data: request,
      );

      debugPrint("Raw Response: ${rawResponse.data}");

      Map<String, dynamic> responseData;
      if (rawResponse.data is String) {
        responseData = json.decode(rawResponse.data);
      } else {
        responseData = rawResponse.data;
      }

      final response = BaseResponse.fromJson(responseData);
      debugPrint("Payload: ${response.payload}");

      // Handle payload sebagai array (sama seperti di atas)
      if (response.payload is List && (response.payload as List).isNotEmpty) {
        final firstItem = (response.payload as List)[0];
        if (firstItem is Map<String, dynamic>) {
          return EstimatedScore.fromJson(firstItem);
        } else {
          throw Exception("First item in payload is not a Map");
        }
      } else if (response.payload is Map<String, dynamic>) {
        return EstimatedScore.fromJson(response.payload);
      } else {
        throw Exception(
            "Payload is neither a List nor a Map, or List is empty");
      }
    } catch (e, stack) {
      debugPrint("Error in addAndUpdateScore: $e");
      debugPrint("Stack trace: $stack");

      return EstimatedScore(
        targetUser: 0,
        userScore: "0.00",
        scoreListening: "0.00",
        scoreStructure: "0.00",
        scoreReading: "0.00",
      );
    }
  }
}
