import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:toefl/models/test/history.dart';
import 'package:toefl/models/test/packet.dart';
import 'package:toefl/remote/base_response.dart';
import 'package:toefl/remote/dio_toefl.dart';
import 'package:toefl/remote/env.dart';

class HistoryApi {
  final Dio? dio;

  HistoryApi({this.dio});

  Future<List<Packet>> getAllPackets() async {
    try {
      final Response rawResponse = await (dio ?? DioToefl.instance)
          .get('${Env.simulationUrl}/get-all-paket');

      final response = BaseResponse.fromJson(json.decode(rawResponse.data));
      final packets =
          (response.payload as List).map((e) => Packet.fromJson(e)).toList();

      debugPrint("success getAllPackets: ${packets.length} packets");
      return packets;
    } catch (e, stackTrace) {
      debugPrint("error getAllPackets: $e $stackTrace");
      return [];
    }
  }

  Future<HistoryItem?> getScoreHistory(String idPacket, String type) async {
    try {
      final Response rawResponse = await (dio ?? DioToefl.instance)
          .get('${Env.simulationUrl}/get-score/$idPacket');

      debugPrint("Raw response for packet $idPacket: ${rawResponse.data}");

      final responseData = json.decode(rawResponse.data);
      final historyItem = HistoryItem.fromApiResponse(
        responseData,
        type,
        createdAt: DateTime.now().toIso8601String(),
      );

      debugPrint(
          "success getScoreHistory for packet $idPacket: isValid=${historyItem.isValid}, answeredQuestion=${historyItem.answeredQuestion}");

      // Hanya return item yang valid (sudah ada jawaban)
      return historyItem.isValid ? historyItem : null;
    } on DioException catch (dioError) {
      if (dioError.response?.statusCode == 404) {
        debugPrint(
            "Packet $idPacket: No score data (404) - belum pernah ujian");
        return null; // Return null untuk 404 (belum pernah ujian)
      }
      debugPrint("error getScoreHistory: $dioError");
      return null;
    } catch (e, stackTrace) {
      debugPrint("error getScoreHistory: $e $stackTrace");
      return null;
    }
  }

  Future<List<HistoryItem>> getHistoryByType(String type) async {
    try {
      final allPackets = await getAllPackets();
      debugPrint("getAllPackets result: ${allPackets.length} packets");

      final filteredPackets = allPackets
          .where(
              (packet) => packet.packetType.toLowerCase() == type.toLowerCase())
          .toList();

      debugPrint("Filtered packets for type $type: ${filteredPackets.length}");

      List<HistoryItem> historyList = [];
      for (final packet in filteredPackets) {
        try {
          final historyItem = await getScoreHistory(packet.id.toString(), type);
          if (historyItem != null) {
            historyList.add(historyItem);
            debugPrint("Added packet ${packet.id} to history list");
          }
        } catch (e) {
          debugPrint("Error processing packet ${packet.id}: $e");
          // Continue with next packet
        }
      }

      debugPrint("Final valid history list: ${historyList.length} items");
      return historyList;
    } catch (e, stackTrace) {
      debugPrint("error getHistoryByType: $e $stackTrace");
      return [];
    }
  }
}
