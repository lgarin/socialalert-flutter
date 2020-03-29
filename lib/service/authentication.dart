import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/service/credential.dart';

import 'configuration.dart';

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

class _AuthenticationApi {
  static const jsonMediaType = 'application/json; charset=UTF-8';
  static const jsonHeaders = {
    'Content-type': jsonMediaType,
    'Accept': jsonMediaType,
  };
  final _httpClient = Client();

  Future<Response> _postJson(String uri, String body) {
    return _httpClient.post(baseServerUrl + uri, headers: jsonHeaders, body: body);
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


class _AuthToken {
  static const refreshTokenDelta = 10000;

  final accessToken;
  final refreshToken;
  final _expiration;

  _AuthToken(LoginResponse login)
      : accessToken = login.accessToken,
        refreshToken = login.refreshToken,
        _expiration = login.expiration;

  bool get expired {
    return _expiration - refreshTokenDelta <
        DateTime.now().millisecondsSinceEpoch;
  }
}

class UserProfile {
  final String username;
  final String email;
  final String country;
  final String imageUri;
  final DateTime birthdate;
  final String biography;

  UserProfile(LoginResponse login) :
      username = login.username,
      email = login.email,
      imageUri = login.imageUri,
      country = login.country,
      birthdate = login.birthdate != null ? DateTime.parse(login.birthdate) : null,
      biography = login.biography;
}

class AuthService {
  final _credentialStore = CredentialStore();
  final _authService = _AuthenticationApi();
  _AuthToken _token;

  static AuthService current(BuildContext context) =>
      Provider.of<AuthService>(context, listen: false);

  final _profileController = StreamController<UserProfile>();

  Stream<UserProfile> get profileStream => _profileController.stream;

  void dispose() {
    _profileController.close();
  }

  Future<Credential> get initialCredential {
    return _credentialStore.load();
  }

  Future<UserProfile> authenticate(Credential credential) async {
    await _credentialStore.store(credential);
    var login = await _authService.loginUser(credential);

    _token = _AuthToken(login);

    final profile = UserProfile(login);
    _profileController.add(profile);
    return profile;
  }

  Future<String> get accessToken async {
    if (_token == null) {
      return null;
    }
    if (_token.expired) {
      var login = await _authService.renewLogin(_token.refreshToken);
      _token = _AuthToken(login);
    }
    return _token.accessToken;
  }

}