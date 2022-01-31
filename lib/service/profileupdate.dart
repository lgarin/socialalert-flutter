import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:intl/intl.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/dataobject.dart';
import 'package:social_alert_app/service/datasource.dart';
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

  final String firstname;
  final String lastname;
  final String biography;
  final DateTime birthdate;
  final Country country;
  final Gender gender;
  final String language;

  ProfileUpdateRequest({this.firstname, this.lastname, this.biography, this.birthdate, this.country, this.gender, this.language});

  Map<String, dynamic> toJson() => {
    'firstname': firstname,
    'lastname': lastname,
    'biography': biography,
    'birthdate': birthdate != null ? dateFormat.format(birthdate) : null,
    'country': country?.code,
    'gender': toGenderName(gender),
    'language': language,
  };
}

class _ProfileUpdateApi {
  final DataSource dataSource;

  _ProfileUpdateApi(this.dataSource);

  Future<String> enqueueAvatar({@required String title, @required File file, @required String accessToken}) {
    return dataSource.queueImageUpload(uri: '/file/upload/avatar',
        file: file,
        showNotification: false,
        title: title,
        accessToken: accessToken
    );
  }

  Stream<UploadTaskResponse> get avatarUploadStream {
    return dataSource.uploadResultStream;
  }

  AvatarUploadProgress _mapProgress(UploadTaskProgress event) {
    return AvatarUploadProgress(taskId: event.taskId, progress: event.progress, status: event.status);
  }

  Stream<AvatarUploadProgress> get avatarUploadProgressStream => dataSource.uploadProgressStream.map(_mapProgress);

  Future<Iterable<Country>> loadValidCountries() async {
    final uri = '/user/countries';
    final response = await dataSource.getJson(uri: uri);
    if (response.statusCode == 200) {
      return Map<String,String>.from(jsonDecode(response.body)).entries.map((entry) => Country(entry.key, entry.value));
    }
    throw response.reasonPhrase;
  }

  Future<UserProfile> updateProfile(ProfileUpdateRequest request, String accessToken) async {
    final uri = '/user/profile';
    final response = await dataSource.postJson(uri: uri, body: request, accessToken: accessToken);
    if (response.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }

  Future<UserProfile> updatePrivacy(UserPrivacy settings, String accessToken) async {
    final uri = '/user/privacy';
    final response = await dataSource.postJson(uri: uri, body: settings, accessToken: accessToken);
    if (response.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }

  Future<UserProfile> followUser(String userId, String accessToken) async {
    final uri = '/user/follow/$userId';
    final response = await dataSource.post(uri: uri,accessToken: accessToken);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }

  Future<UserProfile> unfollowUser(String userId, String accessToken) async {
    final uri = '/user/unfollow/$userId';
    final response = await dataSource.post(uri: uri,accessToken: accessToken);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }
}

class ProfileUpdateService extends Service {

  final _uploadProgressStreamController = StreamController<AvatarUploadProgress>.broadcast();
  final _profileStreamController = StreamController<UserProfile>.broadcast();
  StreamSubscription<AvatarUploadProgress> _uploadProgressSubscription;
  StreamSubscription<UserProfile> _avatarUploadSubscription;
  StreamSubscription<UserProfile> _userLoginSubscription;
  List<Country> _validCountries;

  ProfileUpdateService(BuildContext context) : super(context) {
    _uploadProgressSubscription = _updateApi.avatarUploadProgressStream.listen(_uploadProgressStreamController.add, onError: _uploadProgressStreamController.addError, onDone: _uploadProgressStreamController.close);
    _userLoginSubscription = _authService.profileStream.listen(_profileStreamController.add, onError: _profileStreamController.addError, onDone: _profileStreamController.close);
    _userLoginSubscription = _updateApi.avatarUploadStream.map(_mapResponse).skipWhile((element) => element == null).listen(_profileStreamController.add, onError: _profileStreamController.addError, onDone: _profileStreamController.close);
  }

  static ProfileUpdateService of(BuildContext context) => ServiceProvider.of(context);

  _ProfileUpdateApi get _updateApi => _ProfileUpdateApi(lookup());
  Authentication get _authService => lookup();

  @override
  void dispose() {
    _uploadProgressSubscription.cancel();
    _avatarUploadSubscription.cancel();
    _userLoginSubscription.cancel();
    _uploadProgressStreamController.close();
    _profileStreamController.close();
  }

  Future<String> beginAvatarUpload(String title, File file) async {
    final accessToken = await _authService.obtainAccessToken();
    try {
      return await _updateApi.enqueueAvatar(title: title, file: file, accessToken: accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  UserProfile _mapResponse(UploadTaskResponse response) {
    if (response.status == UploadTaskStatus.complete && response.response != null) {
      _uploadProgressStreamController.add(
          AvatarUploadProgress(taskId: response.taskId, progress: 100, status: UploadTaskStatus.complete));
      return UserProfile.fromJson(json.decode(response.response));
    } else if (response.status == UploadTaskStatus.failed) {
      _uploadProgressStreamController.add(AvatarUploadProgress(
          taskId: response.taskId, progress: 0, status: UploadTaskStatus.failed, error: response.response));
      return null;
    } else {
      return null;
    }
  }

  Stream<UserProfile> get profileStream => _profileStreamController.stream;

  Stream<AvatarUploadProgress> get uploadProgressStream => _uploadProgressStreamController.stream;

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
    final accessToken = await _authService.obtainAccessToken();
    try {
      final profile = await _updateApi.updateProfile(request, accessToken);
      _profileStreamController.add(profile);
      return profile;
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<UserProfile> followUser(String userId) async {
    final accessToken = await _authService.obtainAccessToken();
    try {
      return await _updateApi.followUser(userId, accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<UserProfile> unfollowUser(String userId) async {
    final accessToken = await _authService.obtainAccessToken();
    try {
      return await _updateApi.unfollowUser(userId, accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<UserProfile> updatePrivacy(UserPrivacy settings) async {
    final accessToken = await _authService.obtainAccessToken();
    try {
      final profile = await _updateApi.updatePrivacy(settings, accessToken);
      _profileStreamController.add(profile);
      return profile;
    } catch (e) {
      print(e);
      throw e;
    }
  }
}