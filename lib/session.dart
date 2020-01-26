import 'package:social_alert_app/authentication.dart';
import 'package:social_alert_app/credential.dart';

class UserSession {
  static const refreshTokenDelta = 1000;
  final _credentialStore = CredentialStore();
  final _authService = AuthService();

  String _userId;
  String _username;
  String _accessToken;
  String _refreshToken;
  int _tokenExpiration;

  Future<Credential> loadInitialCredential() {
    return _credentialStore.load();
  }

  Future<void> open(Credential credential) async {
    await _credentialStore.store(credential);
    var response = await _authService.loginUser(credential);

    _setUser(response);
    _setTokens(response);
  }

  void _setUser(LoginResponse response) {
    this._userId = response.userId;
    this._username = response.username;
  }

  void _setTokens(LoginResponse response) {
    this._accessToken = response.accessToken;
    this._refreshToken = response.refreshToken;
    this._tokenExpiration = response.expiration;
  }

  String get userId => _userId;
  String get username => _username;

  Future<String> get accessToken async {
    if (_refreshToken == null) {
      return null;
    }
    if (_tokenExpiration + refreshTokenDelta > DateTime.now().millisecondsSinceEpoch) {
      var response = await _authService.renewLogin(_refreshToken);
      _setTokens(response);
    }
    return _accessToken;
  }
}