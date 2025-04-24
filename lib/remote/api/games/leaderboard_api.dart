import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:toefl/models/leader_board.dart';

import 'package:toefl/remote/dio_toefl.dart';
import 'package:toefl/remote/env.dart';

class LeaderBoardApi {
Future<List<LeaderBoard>> getLeaderBoardEntries() async {
  try {
    final response = await DioToefl.instance.get('${Env.gameUrl}/games/leaderboard');

    final Map<String, dynamic> decodedData = response.data is String
        ? jsonDecode(response.data)
        : response.data;

    final payload = decodedData['payload'];

    if (decodedData['success'] == true && payload != null) {
      List<dynamic> data = payload;

      // Sort data by highest_score descending
      data.sort((a, b) =>
          (double.tryParse(b['highest_score'].toString()) ?? 0)
              .compareTo(double.tryParse(a['highest_score'].toString()) ?? 0));

      return data.map((e) => LeaderBoard.fromJson(e)).toList();
    }

    return [];
  } catch (e, stack) {
    debugPrint("Error fetching leaderboard: $e\n$stack");
    return [];
  }
}
}