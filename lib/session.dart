import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/authentication.dart';
import 'package:social_alert_app/credential.dart';
import 'package:social_alert_app/geolocation.dart';

class UserIdentity {
  final String userId;
  final String username;

  UserIdentity(LoginResponse login)
      : userId = login.userId,
        username = login.username;
}

class AuthToken {
  static const refreshTokenDelta = 10000;

  final accessToken;
  final refreshToken;
  final _expiration;

  AuthToken(LoginResponse login)
      : accessToken = login.accessToken,
        refreshToken = login.refreshToken,
        _expiration = login.expiration;

  bool get expired {
    return _expiration - refreshTokenDelta <
        DateTime.now().millisecondsSinceEpoch;
  }
}

class UserSession {
  final _credentialStore = CredentialStore();
  final _authService = AuthService();
  final _geolocationService = GeolocationService();

  UserIdentity _identity;
  AuthToken _token;

  static UserSession current(BuildContext context) =>
      Provider.of<UserSession>(context, listen: false);

  Future<Credential> get initialCredential {
    return _credentialStore.load();
  }

  Future<Placemark> get currentPlace async {
    try {
      return await _geolocationService.currentPlace;
    } catch (e) {
      return null;
    }
  }

  Future<LoginResponse> authenticate(Credential credential) async {
    await _credentialStore.store(credential);
    var login = await _authService.loginUser(credential);

    _identity = UserIdentity(login);
    _token = AuthToken(login);

    return login;
  }

  String get userId => _identity?.userId;
  String get username => _identity?.username;

  Future<String> get accessToken async {
    if (_token == null) {
      return null;
    }
    if (_token.expired) {
      var login = await _authService.renewLogin(_token.refreshToken);
      _token = AuthToken(login);
    }
    return _token.accessToken;
  }
}
