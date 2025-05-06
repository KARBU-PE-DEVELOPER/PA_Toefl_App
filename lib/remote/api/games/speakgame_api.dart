import 'package:dio/dio.dart';
import 'package:toefl/models/games/speak_game.dart';
import 'package:toefl/remote/dio_toefl.dart';
import 'package:toefl/remote/env.dart';
import 'dart:convert';
import '../../base_response.dart';

import 'package:toefl/remote/local/shared_pref/auth_shared_preferences.dart';

class SpeakGameApi {
  final Dio? dio;

  SpeakGameApi({this.dio}); // Update constructor

  Future<SpeakGame> getWord() async {
    try {
      final response = await DioToefl.instance.get(
        "${Env.gameUrl}/minigames/speakingGames/get-speaking-word",
      );

      final contentType = response.headers['content-type']?.toString();
      if (contentType?.contains('application/json') == false) {
        throw Exception("Server mengembalikan non-JSON: $contentType");
      }

      if (response.statusCode != 200) {
        throw Exception("Gagal memuat data: Status ${response.statusCode}");
      }

      // 1. Tangkap data sebagai dynamic
      final rawData = response.data;

      // 2. Handle jika respons adalah String JSON
      Map<String, dynamic> responseData;
      if (rawData is String) {
        responseData = jsonDecode(rawData) as Map<String, dynamic>;
      } else if (rawData is Map<String, dynamic>) {
        responseData = rawData;
      } else {
        throw Exception("Format respons tidak valid");
      }

      // 3. Lanjutkan parsing seperti sebelumnya
      if (!responseData.containsKey('payload') ||
          !(responseData['payload'] is Map<String, dynamic>)) {
        throw Exception("Format response tidak valid");
      }

      final payload = responseData['payload'] as Map<String, dynamic>;
      final sentenceList = _parseSentenceList(payload);

      return SpeakGame(sentence: sentenceList);
    } on DioException catch (e) {
      throw Exception("Error jaringan: ${e.message}");
    } catch (e) {
      throw Exception("Error memproses data: $e");
    }
  }

  List<String> _parseSentenceList(Map<String, dynamic> payload) {
    if (!payload.containsKey('sentence') ||
        !(payload['sentence'] is List<dynamic>)) {
      throw Exception("Format kalimat tidak valid");
    }

    final rawList = payload['sentence'] as List<dynamic>;

    // Konversi ke List<String> dengan validasi
    try {
      return rawList.map((item) => item.toString()).toList();
    } catch (e) {
      throw Exception("Gagal mengkonversi kalimat: $e");
    }
  }

  Future<bool> store(double score) async {
    try {
      final Response rawResponse = await DioToefl.instance.post(
        '${Env.gameUrl}/minigames/speakingGames/submit-answers',
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
