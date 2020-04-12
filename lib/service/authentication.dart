import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:social_alert_app/service/credential.dart';
import 'package:social_alert_app/service/httpservice.dart';
import 'package:social_alert_app/service/serviceprodiver.dart';

class UserStatistic {
  final int hitCount;
  final int likeCount;
  final int dislikeCount;
  final int followerCount;
  final int pictureCount;
  final int videoCount;
  final int commentCount;

  UserStatistic.fromJson(Map<String, dynamic> json) :
        hitCount = json['hitCount'],
        likeCount = json['likeCount'],
        dislikeCount = json['dislikeCount'],
        followerCount = json['followerCount'],
        pictureCount = json['pictureCount'],
        videoCount = json['videoCount'],
        commentCount = json['commentCount'];

  int get mediaCount => pictureCount + videoCount;
}

class LoginTokenResponse {
  final String accessToken;
  final String refreshToken;
  final int expiration;

  LoginTokenResponse.fromJson(Map<String, dynamic> json) :
        accessToken = json['accessToken'],
        refreshToken =  json['refreshToken'],
        expiration = json['expiration'];
}

class LoginResponse extends LoginTokenResponse {
  final String userId;
  final String username;

  final String email;
  final String country;
  final String biography;
  final String birthdate;
  final String imageUri;
  final UserStatistic statistic;

  LoginResponse.fromJson(Map<String, dynamic> json) :
    userId = json['id'],
    username = json['username'],
    email = json['email'],
    country = json['country'],
    biography = json['biography'],
    birthdate = json['birthdate'],
    imageUri = json['imageUri'],
    statistic = json['statistic'] != null ? UserStatistic.fromJson(json['statistic']) : null,
    super.fromJson(json);
}

class _AuthenticationApi {

  final JsonHttpService httpService;

  _AuthenticationApi(this.httpService);

  Future<LoginResponse> loginUser(Credential credential) async {
    final response = await httpService.postJson(uri: '/user/login', body: credential);
    if (response.statusCode == 200) {
      return LoginResponse.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      throw 'Bad credential';
    }
    throw response.reasonPhrase;
  }

  Future<LoginTokenResponse> renewLogin(String refreshToken) async {
    final response = await httpService.postText(uri: '/user/renewLogin', body: refreshToken);
    if (response.statusCode == 200) {
      return LoginTokenResponse.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      throw 'Session timeout';
    }
    throw response.reasonPhrase;
  }

  Future<UserProfile> currentUser(String accessToken) async {
    final response = await httpService.getJson(uri: '/user/current', accessToken: accessToken ?? '');
    if (response.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      return null;
    }
    throw response.reasonPhrase;
  }

  Future<void> logout(String accessToken) async {
    final response = await httpService.post(uri: '/user/logout', accessToken: accessToken);
    if (response.statusCode == 204) {
      return;
    }
    throw response.reasonPhrase;
  }
}


class _AuthToken {
  static const refreshTokenDelta = 10000;

  final accessToken;
  final refreshToken;
  final _expiration;

  _AuthToken(LoginTokenResponse login)
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
  final UserStatistic statistic;

  UserProfile(LoginResponse login) :
      userId = login.userId,
      username = login.username,
      email = login.email,
      imageUri = login.imageUri,
      country = login.country,
      birthdate = login.birthdate != null ? DateTime.parse(login.birthdate) : null,
      biography = login.biography,
      statistic = login.statistic;

  UserProfile.offline() : userId = null, username = null, email = null, country = null, imageUri = null, birthdate = null, biography = null, statistic = null;

  UserProfile.fromJson(Map<String, dynamic> json) :
        userId = json['id'],
        username = json['username'],
        email = json['email'],
        country = json['country'],
        biography = json['biography'],
        birthdate = json['birthdate'] != null ? DateTime.parse(json['birthdate']) : null,
        imageUri = json['imageUri'],
        statistic = UserStatistic.fromJson(json['statistic']);

  bool get offline => userId == null;
}

class AuthService extends Service {

  final _credentialStore = CredentialStore();
  final _profileController = StreamController<UserProfile>();
  _AuthToken _token;

  AuthService(BuildContext context) : super(context);

  static AuthService current(BuildContext context) => ServiceProvider.of(context);

  Stream<UserProfile> get profileStream => _profileController.stream;

  void dispose() {
    _profileController.close();
  }

  _AuthenticationApi get _authApi => _AuthenticationApi(lookup());

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
      profile = UserProfile.offline();
    }
    if (profile != null) {
      _profileController.add(profile);
    }
    return profile;
  }

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

  Future<void> logout() async {
    try {
      await _authApi.logout(await accessToken);
    } catch (e) {
      // ignore
      print(e.toString());
    }
    _token = null;
    _profileController.add(null);
  }

  Future<void> signOut() async {
    await logout();
    await _credentialStore.clear();
  }
}