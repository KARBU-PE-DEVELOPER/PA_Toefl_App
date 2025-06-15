import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:toefl/models/courses/course.dart';
import 'package:toefl/models/courses/course_detail_response.dart';
import 'package:toefl/remote/dio_toefl.dart';
import 'package:toefl/remote/env.dart';

class CourseApi {
  final Dio _dio = DioToefl.instance;

  Future<Course?> fetchCourseDetail(int courseId) async {
    try {
      final Response rawResponse = await _dio.get(
        '${Env.courseUrl}/$courseId',
      );

      final Map<String, dynamic> decodedData = rawResponse.data is String
          ? jsonDecode(rawResponse.data)
          : rawResponse.data;

      final CourseDetailResponse response =
          CourseDetailResponse.fromJson(decodedData);

      return response.payload;
    } catch (e) {
      debugPrint("Error in fetchCourseDetail API: $e");
      return null;
    }
  }

  Future<Map<String, List<Course>>> fetchAllCourses() async {
    try {
      final Response rawResponse =
          await _dio.get('${Env.courseUrl}/get-all-course');

      final Map<String, dynamic> decodedData = rawResponse.data is String
          ? jsonDecode(rawResponse.data)
          : rawResponse.data;

      final Map<String, dynamic> payload = decodedData['payload'];

      return {
        'reading': (payload['reading'] as List<dynamic>)
            .map((e) => Course.fromJson(e))
            .toList(),
        'listening': (payload['listening'] as List<dynamic>)
            .map((e) => Course.fromJson(e))
            .toList(),
        'structure': (payload['structure'] as List<dynamic>)
            .map((e) => Course.fromJson(e))
            .toList(),
      };
    } catch (e) {
      debugPrint("Error fetching all courses: $e");
      return {
        'reading': [],
        'listening': [],
        'structure': [],
      };
    }
  }
}
