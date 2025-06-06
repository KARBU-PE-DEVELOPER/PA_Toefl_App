import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:toefl/exceptions/exceptions.dart';
import 'package:toefl/models/auth_status.dart';
import 'package:toefl/models/test/test_target.dart';
import 'package:toefl/models/user.dart';
import 'package:toefl/remote/base_response.dart';
import 'package:toefl/remote/dio_toefl.dart';
import 'package:toefl/remote/env.dart';
import 'package:toefl/remote/local/shared_pref/auth_shared_preferences.dart';

import '../../models/login.dart';
import '../../models/regist.dart';

class UserApi {
  final Dio? dio;

  UserApi({this.dio});

  AuthSharedPreference authSharedPreference = AuthSharedPreference();

  Future<AuthStatus> postLogin(Login request) async {
    try {
      final Response rawResponse = await (dio ?? DioToefl.instance).post(
        '${Env.userUrl}/login',
        data: request.toJson(),
      );
      final isSuccess = json.decode(rawResponse.data)['success'];
      if (!isSuccess) {
        return AuthStatus(isVerified: false, isSuccess: false);
      }
      final token = json.decode(rawResponse.data)['token'];
      final response = BaseResponse.fromJson(json.decode(rawResponse.data));
      final AuthStatus authStatus = AuthStatus.fromJson(response.payload);
      await authSharedPreference.saveBearerToken(token);
      await authSharedPreference.saveVerifiedAccount(authStatus.isVerified);
      return authStatus.copyWith(isSuccess: true);
    } on DioException catch (e) {
      if (e.response != null && e.response!.statusCode == 422) {
        final data = e.response!.data;
        String message;

        // Jika response berbentuk JSON string
        if (data is String) {
          final jsonData = json.decode(data);
          message = jsonData['message'] ?? "Validation error";
        }
        // Jika response sudah berupa map
        else if (data is Map<String, dynamic>) {
          message = data['message'] ?? "Validation error";
        } else {
          message = "Validation error";
        }

        throw ApiException(message);
      } else if (e.response != null && e.response!.statusCode == 404) {
        final data = e.response!.data;
        String message;

        // Jika response berbentuk JSON string
        if (data is String) {
          final jsonData = json.decode(data);
          message = jsonData['message'] ?? "User not found";
        }
        // Jika response sudah berupa map
        else if (data is Map<String, dynamic>) {
          message = data['message'] ?? "User not found";
        } else {
          message = "User not found";
        }

        throw ApiException(message);
      } else if (e.response != null && e.response!.statusCode == 401) {
        throw ApiException("User not found");
      }

      throw ApiException("Login failed");
    } catch (e) {
      throw ApiException("Unexpected error");
    }
  }

  // Future<AuthStatus> postLogin(Login request) async {
  //   try {
  //     final Response rawResponse = await (dio ?? DioToefl.instance).post(
  //       '${Env.userUrl}/login',
  //       data: request.toJson(),
  //     );
  //     final isSuccess = json.decode(rawResponse.data)['success'];
  //     if (!isSuccess) {
  //       return AuthStatus(isVerified: false, isSuccess: false);
  //     }
  //     final token = json.decode(rawResponse.data)['token'];
  //     final response = BaseResponse.fromJson(json.decode(rawResponse.data));
  //     final AuthStatus authStatus = AuthStatus.fromJson(response.payload);
  //     await authSharedPreference.saveBearerToken(token);
  //     await authSharedPreference.saveVerifiedAccount(authStatus.isVerified);
  //     return authStatus.copyWith(isSuccess: true);
  //   } catch (e) {
  //     return AuthStatus(isVerified: false, isSuccess: false);
  //   }
  // }

  Future<AuthStatus> postRegist(Regist request) async {
    try {
      final Response rawResponse = await DioToefl.instance.post(
        '${Env.userUrl}/register',
        data: request.toJson(),
      );
      final isSuccess = json.decode(rawResponse.data)['success'];
      if (!isSuccess) {
        return AuthStatus(isVerified: false, isSuccess: false);
      }
      final token = json.decode(rawResponse.data)['token'];
      final response = BaseResponse.fromJson(json.decode(rawResponse.data));
      final AuthStatus authStatus = AuthStatus.fromJson(response.payload);
      await authSharedPreference.saveBearerToken(token);
      await authSharedPreference.saveVerifiedAccount(false);
      return authStatus.copyWith(isSuccess: true);
    } on DioException catch (e) {
      if (e.response != null && e.response!.statusCode == 422) {
        final data = e.response!.data;
        String message;

        // Jika response berbentuk JSON string
        if (data is String) {
          final jsonData = json.decode(data);
          message = jsonData['message'] ?? "Validation error";
        }
        // Jika response sudah berupa map
        else if (data is Map<String, dynamic>) {
          message = data['message'] ?? "Validation error";
        } else {
          message = "Validation error";
        }

        throw ApiException(message);
      } else if (e.response != null && e.response!.statusCode == 409) {
        throw ApiException("Email already registered");
      } else if (e.response != null && e.response!.statusCode == 400) {
        throw ApiException("Email already registered");
      }

      throw ApiException("Register failed");
    } catch (e) {
      return AuthStatus(isVerified: false, isSuccess: false);
    }
  }

  Future<UserTarget> getScoreToefl() async {
    try {
      final Response rawResponse =
          await DioToefl.instance.get('${Env.userUrl}/get-score-toefl');

      final response = BaseResponse.fromJson(json.decode(rawResponse.data));
      return UserTarget.fromJson(response.payload);
    } on DioException catch (e) {
      if (e.response != null && e.response!.statusCode == 422) {
        final data = e.response!.data;
        String message;

        // Jika response berbentuk JSON string
        if (data is String) {
          final jsonData = json.decode(data);
          message = jsonData['message'] ?? "Validation error";
        }
        // Jika response sudah berupa map
        else if (data is Map<String, dynamic>) {
          message = data['message'] ?? "Validation error";
        } else {
          message = "Validation error";
        }

        throw ApiException(message);
      } else if (e.response != null && e.response!.statusCode == 401) {
        throw ApiException("User not found");
      }

      throw ApiException("Get user target failed");
    } catch (e) {
      debugPrint("Error in getUserTarget: $e");
      return UserTarget(
          selectedTarget: TestTarget(id: 0, name: "", score: 0),
          allTargets: []);
    }
  }

  Future<UserTarget> getUserTarget() async {
    try {
      final Response rawResponse =
          await DioToefl.instance.get('${Env.apiUrl}/get-all/targets');

      final response = BaseResponse.fromJson(json.decode(rawResponse.data));
      return UserTarget.fromJson(response.payload);
    } catch (e) {
      debugPrint("Error in getUserTarget: $e");
      return UserTarget(
          selectedTarget: TestTarget(id: "", name: "", score: 0),
          allTargets: []);
    }
  }

  Future<bool> updateBookmark(int id) async {
    try {
      await DioToefl.instance
          .patch('${Env.userUrl}/add-and-patch-target', data: {
        'target_id': id,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> getOtp() async {
    try {
      final response =
          await (dio ?? DioToefl.instance).post('${Env.userUrl}/users/new-otp');
      debugPrint('response: ${json.decode(response.data)}');
      return true;
    } catch (e) {
      debugPrint('error get otp: $e');
      return false;
    }
  }

  Future<AuthStatus> verifyOtp(String otp) async {
    try {
      final rawResponse = await (dio ?? DioToefl.instance)
          .post('${Env.userUrl}/users/verify-otp', data: {'otp_register': otp});
      final response = json.decode(rawResponse.data);
      debugPrint('response: ${response['success']}');
      await authSharedPreference.saveVerifiedAccount(true);
      return AuthStatus(isVerified: response['success'], isSuccess: true);
    } catch (e) {
      debugPrint('error verify otp: $e');
      return AuthStatus(isVerified: false, isSuccess: false);
    }
  }

  Future<bool> forgotPassword(String email) async {
    try {
      final rawResponse =
          await (dio ?? DioToefl.instance).post('${Env.userUrl}/forgot', data: {
        'email': email,
      });
      final response = BaseResponse.fromJson(json.decode(rawResponse.data));
      debugPrint('success : ${response.payload['token']}');
      final token = response.payload['token'];
      await authSharedPreference.saveBearerToken(token);
      return json.decode(rawResponse.data)?['success'] ?? true;
    } catch (e) {
      return false;
    }
  }

  Future<AuthStatus> verifyForgot(String otp) async {
    try {
      final rawResponse = await (dio ?? DioToefl.instance)
          .post('${Env.userUrl}/users/verify-otp-forgot', data: {
        'otp_forgot': otp,
      });
      debugPrint('success : ${json.decode(rawResponse.data)['success']}');
      return AuthStatus(
          isVerified: json.decode(rawResponse.data)?['success'] ?? true,
          isSuccess: true);
    } catch (e) {
      return AuthStatus(isVerified: false, isSuccess: false);
    }
  }

  Future<bool> verifyPassword(String password) async {
    try {
      final rawResponse = await (dio ?? DioToefl.instance)
          .post('${Env.userUrl}/check/password', data: {
        'password': password,
      });
      final response = BaseResponse.fromJson(json.decode(rawResponse.data));
      debugPrint('success : ${response.payload['password']}');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updatePassword(String password, String secondPassword) async {
    try {
      final rawResponse = await (dio ?? DioToefl.instance)
          .post('${Env.userUrl}/change/password', data: {
        'password': password,
        'confirm_password': secondPassword,
      });

      debugPrint('success : ${json.decode(rawResponse.data)?['success']}');
      return json.decode(rawResponse.data)?['success'] ?? true;
    } catch (e) {
      return false;
    }
  }
}
