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
  final _httpClient = Client();

  Future<Response> _postJson(String uri, String body) {
    final headers = {
      'Content-type': jsonMediaType,
      'Accept': jsonMediaType,
    };
    return _httpClient.post(baseServerUrl + uri, headers: headers, body: body);
  }

  Future<Response> _getJson(String uri, String accessToken) {
    final headers = {
      'Accept': jsonMediaType,
      'Authorization': accessToken,
    };
    return _httpClient.get(baseServerUrl + uri, headers: headers);
  }

  Future<LoginResponse> loginUser(Credential credential) async {
    final response = await _postJson('/user/login', jsonEncode(credential));
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

  Future<UserProfile> currentUser(String accessToken) async {
    final response = await _getJson('/user/current', accessToken ?? '');
    if (response.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      return null;
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
  final String userId;
  final String username;
  final String email;
  final String country;
  final String imageUri;
  final DateTime birthdate;
  final String biography;

  UserProfile(LoginResponse login) :
      userId = login.userId,
      username = login.username,
      email = login.email,
      imageUri = login.imageUri,
      country = login.country,
      birthdate = login.birthdate != null ? DateTime.parse(login.birthdate) : null,
      biography = login.biography;

  UserProfile.anonymous() : userId = null, username = null, email = null, country = null, imageUri = null, birthdate = null, biography = null;

  UserProfile.fromJson(Map<String, dynamic> json) :
        userId = json['id'],
        username = json['username'],
        email = json['email'],
        country = json['country'],
        biography = json['biography'],
        birthdate = json['birthdate'] != null ? DateTime.parse(json['birthdate']) : null,
        imageUri = json['imageUri'];

  bool get anonymous => userId == null;
}

class AuthService {
  final _credentialStore = CredentialStore();
  final _authApi = _AuthenticationApi();
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
    var login = await _authApi.loginUser(credential);

    _token = _AuthToken(login);

    final profile = UserProfile(login);
    _profileController.add(profile);
    return profile;
  }

  Future<UserProfile> currentUser() async {
    UserProfile profile;
    try {
      profile = await _authApi.currentUser(await accessToken);
    } catch (e) {
      // no server connection
      profile = UserProfile.anonymous();
    }
    if (profile != null) {
      _profileController.add(profile);
    }
    return profile;
  }

  bool get offline => _token == null;

  Future<String> get accessToken async {
    if (_token == null) {
      return null;
    }
    if (_token.expired) {
      var login = await _authApi.renewLogin(_token.refreshToken);
      _token = _AuthToken(login);
    }
    return _token.accessToken;
  }

}