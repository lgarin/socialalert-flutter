import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/configuration.dart';
import 'package:social_alert_app/service/geolocation.dart';

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
  PICTURE
}

class MediaUploadTask with ChangeNotifier {
  final DateTime timestamp;
  final MediaUploadType type;
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

  MediaUploadTask({@required this.file, @required this.type, GeoPosition position}) :
        timestamp = DateTime.now(), _latitude = position?.latitude, _longitude = position?.longitude {
    _changeStatus(MediaUploadStatus.CREATED);
  }

  bool isNew() {
    return status == MediaUploadStatus.CREATED;
  }

  bool canBeDeleted() {
    return status == MediaUploadStatus.CREATED || status == MediaUploadStatus.ANNOTATED || status == MediaUploadStatus.CLAIM_ERROR || status == MediaUploadStatus.CLAIM_ERROR || status == MediaUploadStatus.CLAIMED;
  }

  bool isFileValid() {
    return file.existsSync();
  }

  bool isObsolete(DateTime now) {
    return status == MediaUploadStatus.CLAIMED && now.difference(timestamp).inDays > 30;
  }

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

  GeoLocation get location =>
      GeoLocation(longitude: _longitude,
          latitude: _latitude,
          locality: _locality,
          country: _country,
          address: _address);

  double get uploadProgress => _uploadProgress != null ? _uploadProgress * 0.95 / 100.0 : 0.0;

  void _changeStatus(MediaUploadStatus newStatus) {
    _status = newStatus;
    _lastUpdate = DateTime.now();
    notifyListeners();
  }

  MediaUploadTask.fromJson(Map<String, dynamic> json) :
        timestamp = DateTime.parse(json['timestamp']),
        type = MediaUploadType.values[json['type']],
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

  Future<void> _delete() async {
    assert(canBeDeleted());
    await file.delete();
    _changeStatus(null);
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

  _ClaimParameter(this.title, this.category, this.description, this.location, this.tags);

  Map<String, dynamic> toJson() => {
    'title': title,
    'category': category,
    'description': description,
    'location': location?.toJson(),
    'tags': tags
  };
}

class _UploadApi {

  static const jsonMediaType = 'application/json';

  final _httpClient = Client();
  final uploader = FlutterUploader();

  Future<String> enqueueImage({@required String title, @required File file, @required String accessToken}) {
    final item = FileItem(savedDir: dirname(file.path),
        filename: basename(file.path));
    return uploader.enqueueBinary(url: baseServerUrl + '/file/upload/picture',
        method: UploadMethod.POST,
        file: item,
        headers: {'Authorization': accessToken, 'Content-type': 'image/jpeg'},
        showNotification: true,
        tag: title
    );
  }

  Future<Response> _postJson(String uri, String body, String accessToken) {
    final headers = {
      'Content-type': jsonMediaType,
      'Accept': jsonMediaType,
      'Authorization': accessToken
    };
    return _httpClient.post(baseServerUrl + uri, headers: headers, body: body);
  }

  Future<void> claimMedia({@required String mediaUri, @required _ClaimParameter param, @required String accessToken}) async {
    final response = await _postJson('/media/claim/$mediaUri', json.encode(param.toJson()), accessToken);
    if (response.statusCode != 200) {
      throw response.reasonPhrase;
    }
  }

  _UploadTaskResult _mapResponse(UploadTaskResponse response) {
    if (response.status == UploadTaskStatus.complete && response.statusCode == 200) { // FIXME why 200? server should return 201
      final baseLocationUrl = baseServerUrl + '/file/download/';
      final mediaUri = response.headers['Location'].substring(baseLocationUrl.length);
      return _UploadTaskResult(taskId: response.taskId, mediaUri: mediaUri, status: MediaUploadStatus.UPLOADED);
    } else if (response.status == UploadTaskStatus.failed || response.status == UploadTaskStatus.complete) {
      return _UploadTaskResult(taskId: response.taskId, status: MediaUploadStatus.UPLOAD_ERROR, error: response.response);
    } else {
      return _UploadTaskResult(taskId: response.taskId);
    }

  }

  Stream<_UploadTaskResult> get resultStream {
    return uploader.result.map(_mapResponse);
  }

  _UploadTaskStep _mapProgress(UploadTaskProgress event) {
    return _UploadTaskStep(taskId: event.taskId, progress: event.progress);
  }

  Stream<_UploadTaskStep> get progressStream {
    return uploader.progress.where((event) => event.status == UploadTaskStatus.running).map(_mapProgress);
  }

  void dispose() {
    uploader.dispose();
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

class MediaUploadService {
  static MediaUploadService current(BuildContext context) =>
      Provider.of<MediaUploadService>(context, listen: false);

  final _uploadTaskStore = _UploadTaskStore();
  final _uploadApi = _UploadApi();
  final AuthService _authService;
  final GeoLocationService _locationService;
  StreamSubscription<MediaUploadTask> _uploadSubscription;
  StreamSubscription<MediaUploadTask> _progressSubscription;
  final _uploadStreamController = StreamController<MediaUploadTask>.broadcast();
  final _progressStreamController = StreamController<MediaUploadTask>.broadcast();
  MediaUploadList _uploads;

  MediaUploadService(this._authService, this._locationService) {
    _uploadSubscription = _uploadResultStream.listen(_uploadStreamController.add, onError: _uploadStreamController.addError, onDone: _uploadStreamController.close);
    _progressSubscription = _uploadProgressStream.listen(_progressStreamController.add, onError: _progressStreamController.addError, onDone: _progressStreamController.close);
  }

  void dispose() {
    _uploadStreamController.close();
    _progressStreamController.close();
    _progressSubscription.cancel();
    _uploadSubscription.cancel();
    _uploadApi.dispose();
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
    final now = DateTime.now();
    for (final upload in await _uploadTaskStore.load()) {
      if (upload.isFileValid() && !upload.isObsolete(now)) {
        upload._reset();
        uploads._add(upload);
      }
    }

    for (final upload in uploads) {
      restartTask(upload);
    }
    return uploads;
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
    if (!task.canBeDeleted()) {
      throw 'Invalid task state';
    }
    final uploads = await currentUploads();
    uploads._remove(task);
    await _uploadTaskStore.store(uploads);
    await task._delete();
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
      final taskId = await _uploadApi.enqueueImage(title: task.title, file: task.file, accessToken: accessToken);
      task._markUploading(taskId);
    } catch (e) {
      task._markUploadError(e);
    }
  }

  Future<void> _startClaiming(MediaUploadTask task) async {
    try {
      final accessToken = await _authService.accessToken;
      final param = _ClaimParameter(task._title, task._category, task._description, task.location, task.tags);
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
    await _uploadTaskStore.store(uploads);
    _uploadStreamController.add(task);
  }

  Future<MediaUploadTask> _mapUploadResult(_UploadTaskResult result) async {
    final uploads = await currentUploads();
    final upload = uploads.firstWhere((item) => item.backgroundTaskId == result.taskId);
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
    return _uploadApi.resultStream.asyncMap(_mapUploadResult);
  }

  Stream<MediaUploadTask> get uploadResultStream => _uploadStreamController.stream;

  Future<MediaUploadTask> _mapUploadProgress(_UploadTaskStep step) async {
    final uploads = await currentUploads();
    final upload = uploads.firstWhere((item) => item.backgroundTaskId == step.taskId);
    upload._setUploadProgress(step.progress);
    return upload;
  }

  Stream<MediaUploadTask> get _uploadProgressStream {
    return _uploadApi.progressStream.asyncMap(_mapUploadProgress);
  }

  Stream<MediaUploadTask> get uploadProgressStream => _progressStreamController.stream;
}