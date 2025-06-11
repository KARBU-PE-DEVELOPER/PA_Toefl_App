import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:toefl/models/test/answer.dart';
import 'package:toefl/models/test/on_going.dart';
import 'package:toefl/models/test/packet_detail.dart';
import 'package:toefl/models/test/result.dart';
import 'package:toefl/remote/dio_toefl.dart';

import '../../models/test/packet.dart';
import '../base_response.dart';
import '../env.dart';

class FullTestApi {
  Future<PacketDetail> getPacketDetail(String id) async {
    try {
      final Response rawResponse =
          await DioToefl.instance.get('${Env.simulationUrl}/get-pakets/$id');

      final response = BaseResponse.fromJson(json.decode(rawResponse.data));

      return PacketDetail.fromJson(response.payload);
    } catch (e, trace) {
      debugPrint("ERROR getPacketDetail : $e $trace");
      return PacketDetail(id: "", name: "", questions: []);
    }
  }

  Future<PacketDetail> claimPaketUjian(String id) async {
    try {
      final Response rawResponse =
          await DioToefl.instance.post('${Env.simulationUrl}/get-pakets/$id');

      final response = BaseResponse.fromJson(json.decode(rawResponse.data));

      return PacketDetail.fromJson(response.payload);
    } catch (e, trace) {
      debugPrint("ERROR getPacketDetail : $e $trace");
      return PacketDetail(id: "", name: "", questions: []);
    }
  }

  Future<List<Packet>> getAllPacket() async {
    try {
      final Response rawResponse =
          await DioToefl.instance.get('${Env.simulationUrl}/get-all-paket');

      final response = BaseResponse.fromJson(json.decode(rawResponse.data));
      return (response.payload as List<dynamic>)
          .map((e) => Packet.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('error get all packet: $e');
      return [];
    }
  }

  Future<bool> submitAnswer(
      List<Map<String, dynamic>> request, String packetId) async {
    try {
      final Response rawResponse = await DioToefl.instance.post(
        '${Env.simulationUrl}/submit-answer/$packetId',
        data: {"answers": request},
      );

      if ((rawResponse.statusCode ?? 0) >= 200 &&
          (rawResponse.statusCode ?? 0) < 300) {
        // Jalankan URL tambahan untuk menghitung setelah submit berhasil
        final Response calcResponse = await DioToefl.instance.post(
          'http://103.106.72.182:8040/api/submit-answers/$packetId',
        );

        if ((calcResponse.statusCode ?? 0) >= 200 &&
            (calcResponse.statusCode ?? 0) < 300) {
          return true;
        } else {
          debugPrint('Gagal hitung setelah submit: ${calcResponse.statusCode}');
          return false;
        }
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('error submit answer: $e');
      return false;
    }
  }

  Future<bool> saveAsnwerNextPage(
      List<Map<String, dynamic>> request, String packetId) async {
    try {
      final Response rawResponse = await DioToefl.instance.post(
        '${Env.simulationUrl}/submit-answer/$packetId',
        data: {"answers": request},
      );

      if ((rawResponse.statusCode ?? 0) >= 200 &&
          (rawResponse.statusCode ?? 0) < 300) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('error submit answer: $e');
      return false;
    }
  }

  Future<List<Answer>> getAnswers(String packetId) async {
    try {
      final Response rawResponse =
          await DioToefl.instance.get('${Env.apiUrl}/answer/users/$packetId');

      final response = BaseResponse.fromJson(json.decode(rawResponse.data));
      return (response.payload as List<dynamic>)
          .map((e) => Answer.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('error get all answers: $e');
      return [];
    }
  }

  Future<Result> getTestResult(String packetId) async {
    try {
      final Response rawResponse = await DioToefl.instance
          .get('${Env.simulationUrl}/get-score/$packetId');

      final response = BaseResponse.fromJson(json.decode(rawResponse.data));
      return Result.fromJson(response.payload);
    } catch (e) {
      debugPrint('error get test result: $e');
      return Result(
        id: '',
        toeflScore: 0,
        correctQuestionAll: 0,
        totalQuestionAll: 0,
        correctListeningAll: 0,
        totalListeningAll: 0,
        listeningPartACorrect: 0,
        totalListeningPartA: 0,
        accuracyListeningPartA: 0,
        correctListeningPartB: 0,
        totalListeningPartB: 0,
        accuracyListeningPartB: 0,
        correctListeningPartC: 0,
        totalListeningPartC: 0,
        accuracyListeningPartC: 0,
        correctStructureAll: 0,
        totalStructureAll: 0,
        correctStructurePartA: 0,
        totalStructurePartA: 0,
        accuracyStructurePartA: 0,
        correctStructurePartB: 0,
        totalStructurePartB: 0,
        accuracyStructurePartB: 0,
        correctReading: 0,
        totalReading: 0,
        accuracyReading: 0,
        targetUser: 0,
        answeredQuestion: 0,
        scoreListening: 0,
        scoreReading: 0,
        scoreStructure: 0,
      );
    }
  }

  Future<OngoingTestData?> getOngoingTestData(String packetId) async {
    try {
      debugPrint("🔍 Getting ongoing test data for packet: $packetId");

      // Validasi packetId tidak kosong
      if (packetId.isEmpty) {
        debugPrint("❌ Packet ID is empty!");
        return null;
      }

      final response = await DioToefl.instance.get(
        '${Env.simulationUrl}/get-pakets/$packetId',
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      debugPrint("📡 API Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = response.data is String
            ? json.decode(response.data)
            : response.data;

        debugPrint("📦 Response structure: ${data.keys}");

        if (data['success'] == true && data['payload'] != null) {
          final payload = data['payload'] as Map<String, dynamic>;

          debugPrint("📋 Payload keys: ${payload.keys}");

          // Check if there are user_answer and packet_claim data
          if (payload.containsKey('user_answer') &&
              payload.containsKey('packet_claim')) {
            debugPrint("✅ Found user_answer and packet_claim data");
            return OngoingTestData.fromJson(payload);
          } else {
            debugPrint(
                "ℹ️ No user_answer or packet_claim found - this is a new test");
            return null;
          }
        }
      } else if (response.statusCode == 404) {
        debugPrint("⚠️ Packet not found or not accessible");
        return null;
      }

      debugPrint(
          "⚠️ Failed to get ongoing test data - Status: ${response.statusCode}");
      return null;
    } catch (e) {
      debugPrint("❌ Error getting ongoing test data: $e");
      return null;
    }
  }
}
