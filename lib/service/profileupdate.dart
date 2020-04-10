
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/configuration.dart';
import 'package:social_alert_app/service/httphelper.dart';

class AvatarUploadProgress {
  final String taskId;
  final int progress;
  final UploadTaskStatus status;
  final String error;

  AvatarUploadProgress({@required this.taskId, @required this.progress, @required this.status, this.error});

  double get value => progress != null ? progress / 100.0 : 0.0;

  bool get terminal => status == UploadTaskStatus.complete || status == UploadTaskStatus.failed;
}

class _ProfileUpdateApi {
  //final _httpClient = Client();
  final _uploader = FlutterUploader();
  final _progressStreamController = StreamController<AvatarUploadProgress>.broadcast();

  _ProfileUpdateApi() {
    _uploader.progress.map(_mapProgress).listen(_progressStreamController.add, onError: _progressStreamController.addError, onDone: _progressStreamController.close);
  }

  Future<String> enqueueAvatar({@required String title, @required File file, @required String accessToken}) {
    final item = FileItem(savedDir: dirname(file.path),
        filename: basename(file.path));
    return _uploader.enqueueBinary(url: baseServerUrl + '/file/upload/avatar',
        method: UploadMethod.POST,
        file: item,
        headers: {'Authorization': accessToken, 'Content-type': 'image/jpeg'},
        showNotification: false,
        tag: title
    );
  }

  UserProfile _mapResponse(UploadTaskResponse response) {
    if (response.status == UploadTaskStatus.complete && response.statusCode == 200) {
      _progressStreamController.add(AvatarUploadProgress(taskId: response.taskId, progress: 100, status: UploadTaskStatus.complete));
      return UserProfile.fromJson(json.decode(response.response));
    } else if (response.status == UploadTaskStatus.failed || response.status == UploadTaskStatus.complete) {
      _progressStreamController.add(AvatarUploadProgress(taskId: response.taskId, progress: 0, status: UploadTaskStatus.failed, error: response.response));
      return null;
    } else {
      return null;
    }
  }

  Stream<UserProfile> get resultStream {
    return _uploader.result.transform(buildUploadExceptionTransformer()).map(_mapResponse).skipWhile((element) => element == null);
  }

  AvatarUploadProgress _mapProgress(UploadTaskProgress event) {
    return AvatarUploadProgress(taskId: event.taskId, progress: event.progress, status: event.status);
  }

  Stream<AvatarUploadProgress> get progressStream => _progressStreamController.stream;

  void dispose() {
    _uploader.dispose();
    _progressStreamController.close();
  }
}

class ProfileUpdateService {
  final AuthService _authService;
  final _updateApi = _ProfileUpdateApi();

  ProfileUpdateService(this._authService);

  static ProfileUpdateService current(BuildContext context) =>
      Provider.of<ProfileUpdateService>(context, listen: false);

  void dispose() {
    _updateApi.dispose();
  }

  Future<String> beginAvatarUpload(String title, File file) async {
    try {
      final accessToken = await _authService.accessToken;
      return await _updateApi.enqueueAvatar(title: title, file: file, accessToken: accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Stream<UserProfile> get profileStream => StreamGroup.merge([
    _updateApi.resultStream.skipWhile((element) => element == null),
    _authService.profileStream
  ]);

  Stream<AvatarUploadProgress> get uploadProgressStream => _updateApi.progressStream;
}