import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:toefl/models/friend.dart';
import 'package:toefl/models/games/user_leaderboard.dart';
import 'package:toefl/models/profile.dart';
import 'package:toefl/remote/api/leader_board_api.dart';
import 'package:toefl/remote/base_response.dart';
import 'package:toefl/remote/dio_toefl.dart';
import 'package:toefl/remote/env.dart';

class ProfileApi {
  final Dio? dio;

  ProfileApi({this.dio});

  Future<Profile> getProfile() async {
    try {
      final Response rawResponse =
          await DioToefl.instance.get('${Env.userUrl}/users/profile');

      final response = BaseResponse.fromJson(json.decode(rawResponse.data));
      return Profile.fromJson(response.payload);
    } catch (e, stackTrace) {
      debugPrint(e.toString() + stackTrace.toString());
      return Profile(
          id: "",
          level: "",
          currentScore: 0,
          targetScore: 0,
          nameUser: "",
          // emailUser: "",
          rank: -1,
          profileImage: "",
          isFriend: false);
    }
  }

  Future<Profile> getUserProfile(String id) async {
    try {
      final Response rawResponse = await (dio ?? DioToefl.instance)
          .get('${Env.userUrl}/spesify-user/$id');

      final response = BaseResponse.fromJson(json.decode(rawResponse.data));
      debugPrint("success : ${Profile.fromJson(response.payload)}");
      return Profile.fromJson(response.payload);
    } catch (e, stackTrace) {
      debugPrint("error getUserProfile : $e $stackTrace");
      return Profile(
          id: "",
          level: "",
          currentScore: 0,
          targetScore: 0,
          nameUser: "",
          // emailUser: "",
          rank: 0,
          profileImage: "",
          isFriend: false);
    }
  }

  Future<List<Profile>> getAllFriend() async {
    try {
      final Response rawResponse = await (dio ?? DioToefl.instance)
          .get('${Env.userUrl}/get-all/friends');

      final response = BaseResponse.fromJson(json.decode(rawResponse.data));
      final friends = (response.payload as List)
          .map(
            (e) => Profile.fromJson(e),
          )
          .toList();
      debugPrint("success : $friends");
      return friends;
    } catch (e, stackTrace) {
      debugPrint("error getUserProfile : $e $stackTrace");
      return [];
    }
  }

  Future<List<Friend>> searchSpecificUser(String name) async {
    try {
      final Response rawResponse = await (dio ?? DioToefl.instance)
          .post('${Env.userUrl}/search/friend', data: {
        'name': name,
      });

      final response = BaseResponse.fromJson(json.decode(rawResponse.data));
      final friends = (response.payload as List)
          .map(
            (e) => Friend.fromJson(e),
          )
          .toList();
      debugPrint("success : $friends");
      return friends;
    } catch (e, stackTrace) {
      debugPrint("error getUserProfile : $e $stackTrace");
      return [];
    }
  }

  Future<bool> changeFriendStatus(String friendId) async {
    try {
      final Response rawResponse = await (dio ?? DioToefl.instance)
          .post('${Env.userUrl}/friend/process/add-patch/$friendId');

      final response = json.decode(rawResponse.data);
      debugPrint("is success : ${response['success']}");
      return response['success'];
    } catch (e, stackTrace) {
      debugPrint(e.toString() + stackTrace.toString());
      return false;
    }
  }

  Future<bool> updateProfile(File? image, String name) async {
    try {
      String fileName = image?.path.split('/').last ?? "";
      final Response rawResponse = await (dio ?? DioToefl.instance).post(
        '${Env.userUrl}/edit/profile',
        data: FormData.fromMap({
          'name': name,
          "file": image != null
              ? await MultipartFile.fromFile(image.path, filename: fileName)
              : null,
        }),
        options: Options(headers: {
          HttpHeaders.contentTypeHeader: "multipart/form-data",
        }),
      );

      final response = json.decode(rawResponse.data);
      debugPrint("is success : ${response['success']}");
      return response['success'];
    } catch (e, stackTrace) {
      debugPrint(e.toString() + stackTrace.toString());
      return false;
    }
  }
}
