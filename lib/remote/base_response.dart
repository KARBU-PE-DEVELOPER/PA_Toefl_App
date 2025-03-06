import 'dart:convert';

class BaseResponse<T> {
  int? code;
  String? message;
  T? payload;

  BaseResponse({
    this.code,
    this.message,
    this.payload,
  });

  factory BaseResponse.fromRawJson(String str) =>
      BaseResponse.fromJson(json.decode(str));

  @override
  String toString() => toRawJson();

  String toRawJson() => json.encode(toJson());

  factory BaseResponse.fromJson(Map<String, dynamic> json) => BaseResponse(
        code: json['code'],
        message: json['message'],
        payload: json['payload'],
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
        'payload': payload,
      };
}
