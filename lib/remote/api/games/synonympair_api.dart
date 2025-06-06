import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:toefl/models/games/pairing_game.dart';
import 'package:toefl/remote/dio_toefl.dart';
import 'package:toefl/remote/env.dart';
import '../../base_response.dart';

class PairingGameApi {
  final Dio _dio = DioToefl.instance;

  Future<List<SynonymPair>> fetchSynonyms() async {
    try {
      final Response rawResponse = await _dio.get(
        '${Env.gameUrl}/minigames/pairingGames/get-pairing-word',
      );

      print("API Response: ${rawResponse.data}");

      // Decode JSON jika masih berupa String
      final Map<String, dynamic> decodedData = rawResponse.data is String
          ? jsonDecode(rawResponse.data)
          : rawResponse.data;

      if (decodedData.containsKey('payload') &&
          decodedData['payload'].containsKey('wordPairs')) {
        final List<dynamic> wordPairs = decodedData['payload']['wordPairs'];

        return wordPairs
            .whereType<
                Map<String, dynamic>>() // Pastikan hanya map yang diproses
            .map((e) => SynonymPair.fromJson(e))
            .toList();
      } else {
        throw Exception("Format response tidak sesuai");
      }
    } catch (e) {
      print("Error in fetchSynonyms API: $e");
      return [];
    }
  }

  Future<bool> submitPairingGameResult(double score) async {
    try {
      final Response rawResponse = await _dio.post(
        '${Env.gameUrl}/minigames/pairingGames/submit-answers',
        data: {
          'score': score,
        },
      );
      print("Submit Response: ${rawResponse.data}");

      final Map<String, dynamic> decodedData = rawResponse.data is String
          ? jsonDecode(rawResponse.data)
          : rawResponse.data;

      final response = BaseResponse.fromJson(decodedData);
      return response.payload;
    } catch (e) {
      print("Error submitting result: $e");
      return false;
    }
  }
}
