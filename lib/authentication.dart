import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:social_alert_app/credential.dart';

class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String username;

  LoginResponse._internal(Map<String, dynamic> json) :
    accessToken = json['accessToken'],
    refreshToken =  json['refreshToken'],
    userId = json['userId'],
    username = json['username'];

  factory LoginResponse(String json) {
    return LoginResponse._internal(jsonDecode(json));
  }
}

class AuthService {
  static const jsonMediaType = 'application/json';
  final baseUrl = 'http://3ft8uk98qmfq79pc.myfritz.net:18774/rest';
  final _httpClient = Client();

  Future<LoginResponse> loginUser(Credential crendential) async {
    final headers = {
      'Content-type': jsonMediaType,
      'Accept': jsonMediaType,
    };
    final body = jsonEncode(crendential);
    final response = await _httpClient.post(baseUrl + '/user/login', headers: headers, body: body);
    if (response.statusCode == 200) {
      return LoginResponse(response.body);
    } else if (response.statusCode == 401) {
      throw 'Bad credentials';
    }
    throw response.reasonPhrase;
  }
}