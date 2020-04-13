import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/httpservice.dart';
import 'package:social_alert_app/service/serviceprodiver.dart';

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
  final JsonHttpService httpService;

  _ProfileUpdateApi(this.httpService);

  Future<String> enqueueAvatar({@required String title, @required File file, @required String accessToken}) {
    return httpService.queueImageUpload(uri: '/file/upload/avatar',
        file: file,
        showNotification: false,
        title: title,
        accessToken: accessToken
    );
  }

  Stream<UploadTaskResponse> get resultStream {
    return httpService.uploadResultStream;
  }

  AvatarUploadProgress _mapProgress(UploadTaskProgress event) {
    return AvatarUploadProgress(taskId: event.taskId, progress: event.progress, status: event.status);
  }

  Stream<AvatarUploadProgress> get progressStream => httpService.uploadProgressStream.map(_mapProgress);

  Future<Iterable<Country>> loadValidCountries() async {
    final uri = '/user/countries';
    final response = await httpService.getJson(uri: uri);
    if (response.statusCode == 200) {
      return Map<String,String>.from(jsonDecode(response.body)).entries.map((entry) => Country(entry.key, entry.value));
    }
    throw response.reasonPhrase;
  }
}

class Country {
  final String code;
  final String name;

  Country(this.code, this.name);
}

class ProfileUpdateService extends Service {

  final _progressStreamController = StreamController<AvatarUploadProgress>.broadcast();
  StreamSubscription _progressSubscription;

  List<Country> _validCountries;

  ProfileUpdateService(BuildContext context) : super(context) {
    _progressSubscription = _updateApi.progressStream.listen(_progressStreamController.add, onError: _progressStreamController.addError, onDone: _progressStreamController.close);
  }

  static ProfileUpdateService current(BuildContext context) => ServiceProvider.of(context);

  _ProfileUpdateApi get _updateApi => _ProfileUpdateApi(lookup());
  AuthService get _authService => lookup();

  @override
  void dispose() {
    _progressSubscription.cancel();
    _progressStreamController.close();
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

  UserProfile _mapResponse(UploadTaskResponse response) {
    if (response.status == UploadTaskStatus.complete) {
      _progressStreamController.add(
          AvatarUploadProgress(taskId: response.taskId, progress: 100, status: UploadTaskStatus.complete));
      return UserProfile.fromJson(json.decode(response.response));
    } else if (response.status == UploadTaskStatus.failed) {
      _progressStreamController.add(AvatarUploadProgress(
          taskId: response.taskId, progress: 0, status: UploadTaskStatus.failed, error: response.response));
      return null;
    } else {
      return null;
    }
  }

  Stream<UserProfile> get profileStream => StreamGroup.merge([
    _updateApi.resultStream.map(_mapResponse).skipWhile((element) => element == null),
    _authService.profileStream
  ]);

  Stream<AvatarUploadProgress> get uploadProgressStream => _progressStreamController.stream;

  Future<List<Country>> readValidCountries() async {
    if (_validCountries == null) {
      try {
        _validCountries = List<Country>.from(await _updateApi.loadValidCountries());
        _validCountries.sort((c1, c2) => c1.name.compareTo(c2.name));
      } catch (e) {
        print(e);
        throw e;
      }
    }

    return _validCountries;
  }
}