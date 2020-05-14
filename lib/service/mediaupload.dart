import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/cameradevice.dart';
import 'package:social_alert_app/service/configuration.dart';
import 'package:social_alert_app/service/geolocation.dart';
import 'package:social_alert_app/service/httpservice.dart';
import 'package:social_alert_app/service/serviceprodiver.dart';

enum MediaUploadStatus {
  CREATED,
  ANNOTATED,
  LOCATING,
  LOCATE_ERROR,
  LOCATED,
  UPLOADING,
  UPLOAD_ERROR,
  UPLOADED,
  CLAIMING,
  CLAIM_ERROR,
  CLAIMED,
}

enum MediaUploadType {
  PICTURE,
  VIDEO
}

class MediaUploadTask with ChangeNotifier {
  static const maximumFileSize = 45000000;

  final DateTime timestamp;
  final MediaUploadType type;
  final String cameraMaker;
  final String cameraModel;
  final File file;
  final double _latitude;
  final double _longitude;
  String _country;
  String _locality;
  String _address;
  String _title;
  String _description;
  String _category;
  List<String> _tags;
  MediaUploadStatus _status;
  String _mediaUri;
  String _uploadTaskId;
  DateTime _lastUpdate;
  int _uploadProgress;

  MediaUploadTask({@required this.file, @required this.type, GeoPosition position, DeviceInfo device}) :
        timestamp = DateTime.now(), cameraMaker = device?.maker, cameraModel = device?.model, _latitude = position?.latitude, _longitude = position?.longitude {
    _changeStatus(MediaUploadStatus.CREATED);
  }

  bool get isVideo => type == MediaUploadType.VIDEO;

  bool get isNew => status == MediaUploadStatus.CREATED;

  bool get canBeDeleted => _status == MediaUploadStatus.CREATED || _status == MediaUploadStatus.ANNOTATED || _status == MediaUploadStatus.CLAIMED || hasError;

  Future<bool> isFileValid() => file.exists();

  String get id => file.path;

  String get backgroundTaskId => _uploadTaskId;

  String get title => _title;

  String get category => _category;

  String get mediaUri => _mediaUri;

  MediaUploadStatus get status => _status;

  DateTime get lastUpdate => _lastUpdate;

  List<String> get tags => _tags == null ? [] : List.from(_tags);

  double get latitude => _latitude;

  double get longitude => _longitude;

  bool get hasPosition => _latitude != null && _longitude != null;

  GeoPosition get position => GeoPosition(latitude: _latitude, longitude: _longitude);

  String get camera {
    if (cameraMaker != null && cameraModel != null) {
      return '$cameraMaker $cameraModel';
    }
    return null;
  }

  GeoLocation get location =>
      GeoLocation(longitude: _longitude,
          latitude: _latitude,
          locality: _locality,
          country: _country,
          address: _address);

  double get uploadProgress => _uploadProgress != null ? _uploadProgress * 0.95 / 100.0 : 0.0;

  bool get isCompleted => _status == MediaUploadStatus.CLAIMED;

  bool get hasError => _status == MediaUploadStatus.LOCATE_ERROR || _status == MediaUploadStatus.UPLOAD_ERROR || _status == MediaUploadStatus.CLAIM_ERROR;

  void _changeStatus(MediaUploadStatus newStatus) {
    _status = newStatus;
    _lastUpdate = DateTime.now();
    notifyListeners();
  }

  MediaUploadTask.fromJson(Map<String, dynamic> json) :
        timestamp = DateTime.parse(json['timestamp']),
        type = MediaUploadType.values[json['type']],
        cameraModel = json['cameraModel'],
        cameraMaker = json['cameraMaker'],
        file = File(json['path']),
        _latitude = json['latitude'],
        _longitude = json['longitude'],
        _country = json['country'],
        _locality = json['locality'],
        _address = json['address'],
        _title = json['title'],
        _description = json['description'],
        _category = json['category'],
        _tags = List<String>.from(json['tags'] ?? []),
        _status = MediaUploadStatus.values[json['status']],
        _mediaUri = json['mediaUri'],
        _uploadTaskId = json["uploadTaskId"],
        _lastUpdate = DateTime.parse(json['lastUpdate']);

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'type': type.index,
    'cameraMaker': cameraMaker,
    'cameraModel': cameraModel,
    'path': file.path,
    'latitude': _latitude,
    'longitude': _longitude,
    'country': _country,
    'locality': _locality,
    'address': _address,
    'title': _title,
    'description': _description,
    'category': _category,
    'tags': _tags,
    'status': _status.index,
    'mediaUri': _mediaUri,
    'uploadTaskId': _uploadTaskId,
    'lastUpdate': _lastUpdate.toIso8601String(),
  };

  void save({@required String title, String description, String category, List<String> tags}) {
    assert(status == MediaUploadStatus.CREATED);
    _title = title;
    _description = description;
    _category = category;
    _tags = tags;

    _changeStatus(MediaUploadStatus.CREATED);
  }

    void annotate({@required String title, String description, String category, List<String> tags}) {
    assert(status == MediaUploadStatus.CREATED);
    _title = title;
    _description = description;
    _category = category;
    _tags = tags;

    _changeStatus(MediaUploadStatus.ANNOTATED);
  }

  void _markLocating() {
    assert(status == MediaUploadStatus.ANNOTATED || status == MediaUploadStatus.LOCATING ||
        status == MediaUploadStatus.LOCATE_ERROR);
    _changeStatus(MediaUploadStatus.LOCATING);
  }

  void _locate(GeoLocation location) {
    assert(status == MediaUploadStatus.LOCATING);
    _country = location?.country;
    _locality = location?.locality;
    _address = location?.address;

    _changeStatus(MediaUploadStatus.LOCATED);
  }

  void _markLocateError(Object error) {
    assert(status == MediaUploadStatus.LOCATING);
    print(error);
    _changeStatus(MediaUploadStatus.LOCATE_ERROR);
  }

  void _markUploading(String uploadTaskId) {
    assert(status == MediaUploadStatus.LOCATED || status == MediaUploadStatus.UPLOADING || status == MediaUploadStatus.UPLOAD_ERROR);
    _uploadTaskId = uploadTaskId;
    _uploadProgress = null;
    _changeStatus(MediaUploadStatus.UPLOADING);
  }

  void _markUploaded(String mediaUri) {
    assert(status == MediaUploadStatus.UPLOADING);
    _mediaUri = mediaUri;
    _changeStatus(MediaUploadStatus.UPLOADED);
  }

  void _markUploadError(Object error) {
    assert(status == MediaUploadStatus.UPLOADING);
    print(error);
    _changeStatus(MediaUploadStatus.UPLOAD_ERROR);
  }

  void _markClaiming() {
    assert(status == MediaUploadStatus.UPLOADED || status == MediaUploadStatus.CLAIMING || status == MediaUploadStatus.CLAIM_ERROR);
    _changeStatus(MediaUploadStatus.CLAIMING);
  }

  void _markClaimError(Object error) {
    assert(status == MediaUploadStatus.CLAIMING);
    print(error);
    _changeStatus(MediaUploadStatus.CLAIM_ERROR);
  }

  void _markClaimed() async {
    assert(status == MediaUploadStatus.CLAIMING);
    _changeStatus(MediaUploadStatus.CLAIMED);
  }

  Future<void> _deleteFile() async {
    assert(canBeDeleted);
    await file.delete();
  }

  void _setUploadProgress(int progress) {
    _uploadProgress = progress;
    notifyListeners();
  }

  void _reset() {
    _uploadProgress = null;
    _uploadTaskId = null;
    if (status == MediaUploadStatus.LOCATING) {
      _status = MediaUploadStatus.LOCATE_ERROR;
    } else if (status == MediaUploadStatus.UPLOADING) {
      _status = MediaUploadStatus.UPLOAD_ERROR;
    } else if (status == MediaUploadStatus.CLAIMING) {
      _status = MediaUploadStatus.CLAIM_ERROR;
    }
    notifyListeners();
  }

  void _abort() {
    _status = null;
  }
}

class _UploadTaskStore {
  static const key = 'uploadTasks';
  final _storage = new FlutterSecureStorage();

  Future<List<MediaUploadTask>> load() async {
    final json = await _storage.read(key: key);
    if (json == null) {
      return <MediaUploadTask>[];
    }

    final list = jsonDecode(json) as List;
    if (list.isEmpty) {
      return <MediaUploadTask>[];
    }

    return list.map((i) => MediaUploadTask.fromJson(i)).toList();
  }

  Future<void> store(Iterable<MediaUploadTask> tasks) async {
    final json = tasks.map((item) => item.toJson()).toList();
    await _storage.write(key: key, value: jsonEncode(json));
  }
}

class _UploadTaskResult {
  final String taskId;
  final String mediaUri;
  final MediaUploadStatus status;
  final Object error;

  _UploadTaskResult({@required this.taskId, this.mediaUri, this.status, this.error});
}

class _UploadTaskStep {
  final String taskId;
  final int progress;

  _UploadTaskStep({this.taskId, this.progress});
}

class _ClaimParameter {
  final String title;
  final String category;
  final String description;
  final GeoLocation location;
  final List<String> tags;
  final String cameraMaker;
  final String cameraModel;

  _ClaimParameter({@required this.title, this.category, this.description, this.location, @required this.tags, this.cameraMaker, this.cameraModel});

  Map<String, dynamic> toJson() => {
    'title': title,
    'category': category,
    'description': description,
    'location': location?.toJson(),
    'tags': tags
  };
}

class _MediaUploadApi {

  final JsonHttpService httpService;

  _MediaUploadApi(this.httpService);

  Future<void> claimMedia({@required String mediaUri, @required _ClaimParameter param, @required String accessToken}) async {
    final response = await httpService.postJson(uri: '/media/claim/$mediaUri', body: param, accessToken: accessToken);
    if (response.statusCode != 200) {
      throw response.reasonPhrase;
    }
  }

  Future<String> enqueueImage({@required String title, @required File file, @required String accessToken}) {
    return httpService.queueImageUpload(uri: '/file/upload/picture', file: file, title: title, accessToken: accessToken, showNotification: true);
  }

  Future<String> enqueueVideo({@required String title, @required File file, @required String accessToken}) {
    return httpService.queueImageUpload(uri: '/file/upload/video', file: file, title: title, accessToken: accessToken, showNotification: true);
  }

  _UploadTaskResult _mapResponse(UploadTaskResponse response) {
    if (response.status == UploadTaskStatus.complete) {
      final baseLocationUrl = baseServerUrl + '/file/download/';
      if (response.headers['Location'] == null) {
        return _UploadTaskResult(taskId: response.taskId);
      }
      final mediaUri = response.headers['Location'].substring(baseLocationUrl.length);
      return _UploadTaskResult(taskId: response.taskId, mediaUri: mediaUri, status: MediaUploadStatus.UPLOADED);
    } else if (response.status == UploadTaskStatus.failed) {
      return _UploadTaskResult(taskId: response.taskId, status: MediaUploadStatus.UPLOAD_ERROR, error: response.response);
    } else {
      return _UploadTaskResult(taskId: response.taskId);
    }

  }

  Stream<_UploadTaskResult> get resultStream {
    return httpService.uploadResultStream.map(_mapResponse);
  }

  _UploadTaskStep _mapProgress(UploadTaskProgress event) {
    return _UploadTaskStep(taskId: event.taskId, progress: event.progress);
  }

  Stream<_UploadTaskStep> get progressStream {
    return httpService.uploadProgressStream.where((event) => event.status == UploadTaskStatus.running).map(_mapProgress);
  }
}

class MediaUploadList with IterableMixin<MediaUploadTask>, ChangeNotifier {

  final _list = List<MediaUploadTask>();

  MediaUploadTask findById(String id) {
    return _list.firstWhere((other) => other.id == id);
  }

  void _add(MediaUploadTask task) {
    _list.removeWhere((other) => other.id == task.id);
    _list.add(task);
    notifyListeners();
  }
  
  void _remove(MediaUploadTask task) {
    _list.removeWhere((other) => other.id == task.id);
    notifyListeners();
  }

  @override
  Iterator<MediaUploadTask> get iterator => _list.iterator;

  MediaUploadTask elementAt(int index) {
    return _list.elementAt(index);
  }
}

class MediaUploadService extends Service {

  final _uploadTaskStore = _UploadTaskStore();

  final _uploadStreamController = StreamController<MediaUploadTask>.broadcast();
  final _progressStreamController = StreamController<MediaUploadTask>.broadcast();

  StreamSubscription<MediaUploadTask> _uploadSubscription;
  StreamSubscription<MediaUploadTask> _progressSubscription;

  MediaUploadList _uploads;

  static MediaUploadService current(BuildContext context) =>
      Provider.of<MediaUploadService>(context, listen: false);

  MediaUploadService(BuildContext context) : super(context) {
    _uploadSubscription = _uploadResultStream.listen(_uploadStreamController.add, onError: _uploadStreamController.addError, onDone: _uploadStreamController.close);
    _progressSubscription = _uploadProgressStream.listen(_progressStreamController.add, onError: _progressStreamController.addError, onDone: _progressStreamController.close);
  }

  AuthService get _authService => lookup();
  GeoLocationService get _locationService => lookup();
  _MediaUploadApi get _uploadApi => _MediaUploadApi(lookup());

  void dispose() {
    _progressSubscription.cancel();
    _uploadSubscription.cancel();
    _uploadStreamController.close();
    _progressStreamController.close();
  }

  Future<MediaUploadList> currentUploads() async {
    if (_uploads != null) {
      return _uploads;
    }
    _uploads = await _initUploads();
    return _uploads;
  }

  Future<MediaUploadList> _initUploads() async {
    final uploads = MediaUploadList();
    for (final upload in await _uploadTaskStore.load()) {
      await _initUpload(upload);
      if (upload.status != null) {
        uploads._add(upload);
      }
    }

    for (final upload in uploads) {
      restartTask(upload);
    }
    return uploads;
  }

  Future<void> _initUpload(MediaUploadTask upload) async {
    if (await upload.isFileValid()) {
      if (upload.isCompleted) {
        await upload._deleteFile();
      } else {
        upload._reset();
      }
    } else {
      upload._abort();
    }
  }

  Future<void> saveTask(MediaUploadTask task) async {
    final uploads = await currentUploads();

    if (task.status == MediaUploadStatus.CREATED) {
      uploads._add(task);
    }

    await _uploadTaskStore.store(uploads);
  }

  void restartTask(MediaUploadTask task) {
    if (task.status == MediaUploadStatus.ANNOTATED || task.status == MediaUploadStatus.LOCATE_ERROR) {
      _startLocating(task);
    } else if (task.status == MediaUploadStatus.LOCATED || task.status == MediaUploadStatus.UPLOAD_ERROR) {
      _startUploading(task);
    } else if (task.status == MediaUploadStatus.UPLOADED || task.status == MediaUploadStatus.CLAIM_ERROR) {
      _startClaiming(task);
    }
  }

  Future<void> deleteTask(MediaUploadTask task) async {
    if (!task.canBeDeleted) {
      throw 'Invalid task state';
    }
    final uploads = await currentUploads();
    uploads._remove(task);
    await _uploadTaskStore.store(uploads);
    await task._deleteFile();
  }

  void _startLocating(MediaUploadTask task) {
    _locationService.readLocation(latitude: task.latitude, longitude: task.longitude)
        .then((location) => task._locate(location), onError: (e) => task._markLocateError(e))
        .whenComplete(() => _completeLocate(task));
    task._markLocating();
  }

  Future<void> _completeLocate(MediaUploadTask task) async {
    final uploads = await currentUploads();
    await _uploadTaskStore.store(uploads);
    _uploadStreamController.add(task);
    _startUploading(task);
  }

  Future<void> _startUploading(MediaUploadTask task) async {
    try {
      final accessToken = await _authService.accessToken;
      final taskId = task.isVideo
          ? await _uploadApi.enqueueVideo(title: task.title, file: task.file, accessToken: accessToken)
          : await _uploadApi.enqueueImage(title: task.title, file: task.file, accessToken: accessToken);
      task._markUploading(taskId);
    } catch (e) {
      task._markUploadError(e);
    }
  }

  Future<void> _startClaiming(MediaUploadTask task) async {
    try {
      final accessToken = await _authService.accessToken;
      final param = _ClaimParameter(title: task._title, category: task._category, description: task._description,
          location: task.location, tags: task.tags, cameraModel: task.cameraModel, cameraMaker: task.cameraMaker);
      _uploadApi.claimMedia(mediaUri: task.mediaUri, param: param, accessToken: accessToken)
          .then((_) => task._markClaimed(), onError: (e) => task._markClaimError(e))
          .whenComplete(() => _completeClaim(task));
      task._markClaiming();
    } catch (e) {
      task._markClaimError(e);
    }
  }

  Future<void> _completeClaim(MediaUploadTask task) async {
    final uploads = await currentUploads();
    uploads._remove(task);
    await _uploadTaskStore.store(uploads);
    _uploadStreamController.add(task);
    await task._deleteFile();
  }

  Future<MediaUploadTask> _mapUploadResult(_UploadTaskResult result) async {
    final uploads = await currentUploads();
    final upload = uploads.firstWhere((item) => item.backgroundTaskId == result.taskId, orElse: () => null);
    if (upload == null) {
      return null;
    }
    if (result.status == MediaUploadStatus.UPLOADED) {
      upload._markUploaded(result.mediaUri);
    } else if (result.status == MediaUploadStatus.UPLOAD_ERROR) {
      upload._markUploadError(result.error);
    }
    await _uploadTaskStore.store(uploads);

    if (upload.status == MediaUploadStatus.UPLOADED) {
      _startClaiming(upload);
    }

    return upload;
  }

  Stream<MediaUploadTask> get _uploadResultStream {
    return _uploadApi.resultStream.asyncMap(_mapUploadResult).skipWhile((element) => element == null);
  }

  Stream<MediaUploadTask> get uploadResultStream => _uploadStreamController.stream;

  Future<MediaUploadTask> _mapUploadProgress(_UploadTaskStep step) async {
    final uploads = await currentUploads();
    final upload = uploads.firstWhere((item) => item.backgroundTaskId == step.taskId, orElse: () => null);
    if (upload == null) {
      return null;
    }
    upload._setUploadProgress(step.progress);
    return upload;
  }

  Stream<MediaUploadTask> get _uploadProgressStream {
    return _uploadApi.progressStream.asyncMap(_mapUploadProgress).skipWhile((element) => element == null);
  }

  Stream<MediaUploadTask> get uploadProgressStream => _progressStreamController.stream;
}
