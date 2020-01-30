import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:social_alert_app/credential.dart';

class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String username;
  final int expiration;

  final String email;
  final String country;
  final String biography;
  final String birthdate;
  final String imageUri;

  LoginResponse._internal(Map<String, dynamic> json) :
    accessToken = json['accessToken'],
    refreshToken =  json['refreshToken'],
    userId = json['id'],
    username = json['username'],
    expiration = json['expiration'],
    email = json['email'],
    country = json['country'],
    biography = json['biography'],
    birthdate = json['birthdate'],
    imageUri = json['imageUri'];

  factory LoginResponse(String json) {
    return LoginResponse._internal(jsonDecode(json));
  }
}

class AuthService {
  static const jsonMediaType = 'application/json';
  static const jsonHeaders = {
    'Content-type': jsonMediaType,
    'Accept': jsonMediaType,
  };
  static const baseUrl = 'http://3ft8uk98qmfq79pc.myfritz.net:18774/rest';
  final _httpClient = Client();

  Future<Response> _postJson(String uri, String body) {
    return _httpClient.post(baseUrl + uri, headers: jsonHeaders, body: body);
  }

  Future<LoginResponse> loginUser(Credential crendential) async {
    final response = await _postJson('/user/login', jsonEncode(crendential));
    if (response.statusCode == 200) {
      return LoginResponse(response.body);
    } else if (response.statusCode == 401) {
      throw 'Bad credential';
    }
    throw response.reasonPhrase;
  }

  Future<LoginResponse> renewLogin(String refreshToken) async {
    final response = await _postJson('/user/renewLogin', refreshToken);
    if (response.statusCode == 200) {
      return LoginResponse(response.body);
    } else if (response.statusCode == 401) {
      throw 'Session timeout';
    }
    throw response.reasonPhrase;
  }
}