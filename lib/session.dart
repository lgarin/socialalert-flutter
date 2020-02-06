import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/authentication.dart';
import 'package:social_alert_app/credential.dart';
import 'package:social_alert_app/geolocation.dart';
import 'package:social_alert_app/upload.dart';

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
  final _uploadTaskStore = UploadTaskStore();
  final _uploadService = UploadService();
  List<UploadTask> _uploads;

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

  Future<String> beginUpload(UploadTask task) async {
    if (_uploads == null) {
      _uploads = await _uploadTaskStore.load();
    }
    // TODO listen to stream
    _uploads.removeWhere((other) => other.file == task.file);
    _uploads.add(task);
    final taskId = await _uploadService.uploadImage(title: task.title, file: task.file, accessToken: await accessToken);
    task.markUploading(taskId);
    await _uploadTaskStore.store(_uploads);
    return taskId;
  }

  Future<UploadTask> _mapUploadResult(UploadTaskResult result) async {
    if (_uploads == null) {
      _uploads = await _uploadTaskStore.load();
    }
    final upload = _uploads.firstWhere((item) => item.taskId == result.taskId);
    if (result.status == UploadStatus.UPLOADED) {
      upload.markUploaded(result.mediaUri);
    } else if (result.status == UploadStatus.UPLOAD_ERROR) {
      upload.markUploadError();
    }
    await _uploadTaskStore.store(_uploads);
    return upload;
  }

  Stream<UploadTask> get uploadResultStream {
    return _uploadService.resultStream.asyncMap(_mapUploadResult);
  }

  Future<List<UploadTask>> get currentUploads async {
    return await _uploadTaskStore.load();
  }
}
