import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:toefl/models/test/history.dart';
import 'package:toefl/remote/dio_toefl.dart';
import 'package:toefl/remote/env.dart';

class HistoryApi {
  final Dio? dio;

  HistoryApi({this.dio});

  /// Get all history from API endpoint
  Future<List<HistoryItem>> getAllHistory() async {
    try {
      final Response rawResponse = await (dio ?? DioToefl.instance)
          .get('${Env.simulationUrl}/get-history-score');

      debugPrint("Raw response getAllHistory: ${rawResponse.data}");

      final responseData = json.decode(rawResponse.data);
      final historyResponse = HistoryResponse.fromJson(responseData);

      if (!historyResponse.success) {
        debugPrint("API returned success=false: ${historyResponse.message}");
        return [];
      }

      debugPrint(
          "success getAllHistory: ${historyResponse.payload.length} items");

      // Sort by time_start descending (newest first)
      final sortedHistory = historyResponse.payload.toList();
      sortedHistory.sort((a, b) => b.timeStart.compareTo(a.timeStart));

      return sortedHistory;
    } catch (e, stackTrace) {
      debugPrint("error getAllHistory: $e $stackTrace");
      return [];
    }
  }

  /// Get history filtered by type ("test" or "simulation")
  Future<List<HistoryItem>> getHistoryByType(String type) async {
    try {
      final allHistory = await getAllHistory();

      final filteredHistory = allHistory
          .where((item) => item.type.toLowerCase() == type.toLowerCase())
          .toList();

      debugPrint(
          "Filtered history for type $type: ${filteredHistory.length} items");
      return filteredHistory;
    } catch (e, stackTrace) {
      debugPrint("error getHistoryByType: $e $stackTrace");
      return [];
    }
  }

  /// Get history for Test type
  Future<List<HistoryItem>> getTestHistory() async {
    return await getHistoryByType('test');
  }

  /// Get history for Simulation type
  Future<List<HistoryItem>> getSimulationHistory() async {
    return await getHistoryByType('simulation');
  }

  /// Get specific history item by packet_id
  Future<HistoryItem?> getHistoryByPacketId(int packetId) async {
    try {
      final allHistory = await getAllHistory();

      final historyItem =
          allHistory.where((item) => item.packetId == packetId).firstOrNull;

      if (historyItem != null) {
        debugPrint("Found history for packet $packetId");
      } else {
        debugPrint("No history found for packet $packetId");
      }

      return historyItem;
    } catch (e, stackTrace) {
      debugPrint("error getHistoryByPacketId: $e $stackTrace");
      return null;
    }
  }

  /// Get statistics from history
  Future<Map<String, dynamic>> getHistoryStats() async {
    try {
      final allHistory = await getAllHistory();

      final testHistory = allHistory
          .where((item) => item.type.toLowerCase() == 'test')
          .toList();
      final simulationHistory = allHistory
          .where((item) => item.type.toLowerCase() == 'simulation')
          .toList();

      // Calculate average scores for completed tests
      final completedTests =
          testHistory.where((item) => item.isCompleted).toList();
      final completedSimulations =
          simulationHistory.where((item) => item.isCompleted).toList();

      double avgTestScore = 0.0;
      double avgSimulationScore = 0.0;

      if (completedTests.isNotEmpty) {
        avgTestScore = completedTests
                .map((item) => item.score.totalScore)
                .reduce((a, b) => a + b) /
            completedTests.length;
      }

      if (completedSimulations.isNotEmpty) {
        avgSimulationScore = completedSimulations
                .map((item) => item.score.totalScore)
                .reduce((a, b) => a + b) /
            completedSimulations.length;
      }

      final stats = {
        'total_history': allHistory.length,
        'total_tests': testHistory.length,
        'total_simulations': simulationHistory.length,
        'completed_tests': completedTests.length,
        'completed_simulations': completedSimulations.length,
        'avg_test_score': avgTestScore,
        'avg_simulation_score': avgSimulationScore,
      };

      debugPrint("History stats: $stats");
      return stats;
    } catch (e, stackTrace) {
      debugPrint("error getHistoryStats: $e $stackTrace");
      return {};
    }
  }
}

// Extension untuk backward compatibility dengan kode lama
extension HistoryItemCompatibility on HistoryItem {
  // Untuk compatibility dengan kode lama yang menggunakan answeredQuestion
  int get answeredQuestion => 1; // History data sudah pasti selesai ujian

  // Getter untuk id (menggunakan packetId)
  int get id => packetId;

  // Getter untuk success (selalu true untuk data dari history API)
  bool get success => true;

  // Getter untuk message
  String get message => 'History data loaded successfully';

  // Getter untuk createdAt (menggunakan score.createdAt)
  String get createdAt => score.createdAt;

  // Compatibility getters
  double get listeningScore => score.listeningScore;
  double get structureScore => score.structureScore;
  double get readingScore => score.readingScore;
  double get totalScore => score.totalScore;
}
