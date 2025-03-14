// import 'dart:convert';
// import 'dart:io';
// import 'package:dio/dio.dart';
// import 'package:toefl/models/ask-ai/ask-ai_detail.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:toefl/remote/dio_toefl.dart';
// import 'package:toefl/remote/env.dart';

// import '../base_response.dart';

// class AskAIAPI {
//   final Dio? dio;

//   AskAIAPI({this.dio});
//   Future<List<AskAI>> storeMessage(List<Map<String, dynamic>> request) async {
//     try {
//       final Response rawResponse = await DioToefl.instance.post(
//         '${Env.apiUrl}/grammar/ask-ai',
//         data: {'user_message': request},
//       );

//       final response = BaseResponse.fromJson(rawResponse.data);

//       if (response.payload == null) {
//         throw Exception("API returned null payload");
//       }

//       if (response.payload is! Map<String, dynamic>) {
//         throw Exception("Invalid API response format: Expected Map<String, dynamic>");
//       }

//       final Map<String, dynamic> dataMessage = response.payload as Map<String, dynamic>;

//       if (!dataMessage.containsKey('data')) {
//         throw Exception("Response payload does not contain 'data'");
//       }

//       List<dynamic> rawData = dataMessage['data'];

//       return rawData.map((e) => AskAI.fromJson(e as Map<String, dynamic>)).toList();
//     } catch (e) {
//       print("Error in storeMessage API: $e");
//       return [];
//     }
//   }


//   Future<List<AskAI>> getAllAskGrammar() async {
//     try {
//       final Response rawResponse =
//           await DioToefl.instance.get('${Env.apiUrl}/grammar/get-history');

//       final response = BaseResponse.fromJson(json.decode(rawResponse.data));
//       return (response.payload as List)
//           .map((e) => AskAI.fromJson(e as Map<String, dynamic>))
//           .toList();
//     } catch (e) {
//       return [];
//     }
//   }
// }
