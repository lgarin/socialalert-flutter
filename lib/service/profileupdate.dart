import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:intl/intl.dart';
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

enum Gender {
  MALE,
  FEMALE,
  OTHER,
}

List<String> _genderNames = ['MALE', 'FEMALE', 'OTHER'];
Map<String, Gender> _genderMap = {
  'MALE': Gender.MALE,
  'FEMALE': Gender.FEMALE,
  'OTHER': Gender.OTHER,
};

String toGenderName(Gender gender) => gender != null ? _genderNames[gender.index] : null;
Gender fromGenderName(String name) => name != null ? _genderMap[name] : null;

class Country {
  final String code;
  final String name;

  Country(this.code, this.name);

  @override
  bool operator ==(other) {
    if (other is Country) {
      return other.code == code;
    }
    return false;
  }

  @override
  int get hashCode {
    return code.hashCode;
  }
}

class ProfileUpdateRequest {
  static final dateFormat = DateFormat('yyyy-MM-dd');

  final String biography;
  final DateTime birthdate;
  final Country country;
  final Gender gender;
  final String language;

  ProfileUpdateRequest({this.biography, this.birthdate, this.country, this.gender, this.language});

  Map<String, dynamic> toJson() => {
    'biography': biography,
    'birthdate': birthdate != null ? dateFormat.format(birthdate) : null,
    'country': country?.code,
    'gender': toGenderName(gender),
    'language': language,
  };
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

  Future<UserProfile> updateProfile(ProfileUpdateRequest request, String accessToken) async {
    final uri = '/user/profile';
    final response = await httpService.postJson(uri: uri, body: request, accessToken: accessToken);
    if (response.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }

  Future<void> followUser(String userId, String accessToken) async {
    final uri = '/user/follow/$userId';
    final response = await httpService.post(uri: uri,accessToken: accessToken);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return;
    }
    throw response.reasonPhrase;
  }

  Future<void> unfollowUser(String userId, String accessToken) async {
    final uri = '/user/unfollow/$userId';
    final response = await httpService.post(uri: uri,accessToken: accessToken);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return;
    }
    throw response.reasonPhrase;
  }
}

class ProfileUpdateService extends Service {

  final _progressStreamController = StreamController<AvatarUploadProgress>.broadcast();
  final _profileController = StreamController<UserProfile>();
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
    _profileController.close();
  }

  Future<String> beginAvatarUpload(String title, File file) async {
    final accessToken = await _authService.accessToken;
    try {
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
    _authService.profileStream,
    _profileController.stream
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

  Future<Country> findCountry(String countryCode) async {
    final countries = await readValidCountries();
    return countries.firstWhere((country) => country.code == countryCode, orElse: () => null);
  }

  Future<UserProfile> updateProfile(ProfileUpdateRequest request) async {
    final accessToken = await _authService.accessToken;
    try {
      final profile = await _updateApi.updateProfile(request, accessToken);
      _profileController.add(profile);
      return profile;
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<void> followUser(String userId) async {
    final accessToken = await _authService.accessToken;
    try {
      return await _updateApi.followUser(userId, accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<void> unfollowUser(String userId) async {
    final accessToken = await _authService.accessToken;
    try {
      return await _updateApi.unfollowUser(userId, accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }
}