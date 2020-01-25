import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

class LoginParameter {
  final String username;
  final String password;

  LoginParameter(this.username, this.password);

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
  };
}

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

  LoginResponse _loginResponse;

  Future<LoginResponse> loginUser(LoginParameter parameter) async {
    final headers = {
      'Content-type': jsonMediaType,
      'Accept': jsonMediaType,
    };
    final body = jsonEncode(parameter);
    final response = await _httpClient.post(baseUrl + '/user/login', headers: headers, body: body);
    if (response.statusCode == 200) {
      return LoginResponse(response.body);
    } else if (response.statusCode == 401) {
      throw 'Bad credentials';
    }
    throw response.reasonPhrase;
  }
}