import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/configuration.dart';
import 'package:social_alert_app/service/geolocation.dart';

enum UploadStatus {
  CREATED,
  ANNOTATED,
  UPLOADING,
  UPLOAD_ERROR,
  UPLOADED,
  CLAIMING,
  CLAIM_ERROR,
  CLAIMED,
}

enum UploadType {
  PICTURE
}

class UploadTask with ChangeNotifier {
  final DateTime timestamp;
  final UploadType type;
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
  UploadStatus _status;
  String _mediaUri;
  String _uploadTaskId;
  DateTime _lastUpdate;
  int _uploadProgress;

  UploadTask({@required this.file, @required this.type, GeoPosition position}) :
        timestamp = DateTime.now(), _latitude = position?.latitude, _longitude = position?.longitude {
    _changeStatus(UploadStatus.CREATED);
  }

  bool canBeDeleted() {
    return status == UploadStatus.CREATED || status == UploadStatus.ANNOTATED || status == UploadStatus.CLAIM_ERROR || status == UploadStatus.CLAIM_ERROR || status == UploadStatus.CLAIMED;
  }

  String get id => file.path;

  String get backgroundTaskId => _uploadTaskId;

  String get title => _title;

  String get mediaUri => _mediaUri;

  UploadStatus get status => _status;

  DateTime get lastUpdate => _lastUpdate;

  GeoPosition get position => GeoPosition(latitude: _latitude, longitude: _longitude);

  GeoLocation get location =>
      GeoLocation(longitude: _longitude,
          latitude: _latitude,
          locality: _locality,
          country: _country,
          address: _address);

  double get uploadProgress => _uploadProgress != null ? _uploadProgress / 100.0 : 0.0;

  void _changeStatus(UploadStatus newStatus) {
    _status = newStatus;
    _lastUpdate = DateTime.now();
    notifyListeners();
  }

  UploadTask.fromJson(Map<String, dynamic> json) :
        timestamp = DateTime.parse(json['timestamp']),
        type = UploadType.values[json['type']],
        file = File(json['path']),
        _latitude = json['latitude'],
        _longitude = json['longitude'],
        _country = json['country'],
        _locality = json['locality'],
        _address = json['address'],
        _title = json['title'],
        _description = json['description'],
        _category = json['category'],
        _tags = json['tags'],
        _status = UploadStatus.values[json['status']],
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

  void annotate({@required String title, String description, String category, List<String> tags, GeoLocation location}) {
    assert(status == UploadStatus.CREATED);
    _title = title;
    _description = description;
    _category = category;
    _tags = tags;
    _country = location?.country;
    _locality = location?.locality;
    _address = location?.address;
    _changeStatus(UploadStatus.ANNOTATED);
  }

  void _markUploading(String uploadTaskId) {
    assert(status == UploadStatus.ANNOTATED || status == UploadStatus.UPLOADING || status == UploadStatus.UPLOAD_ERROR);
    _uploadTaskId = uploadTaskId;
    _uploadProgress = null;
    _changeStatus(UploadStatus.UPLOADING);
  }

  void _markUploaded(String mediaUri) {
    assert(status == UploadStatus.UPLOADING);
    _mediaUri = mediaUri;
    _changeStatus(UploadStatus.UPLOADED);
  }

  void _markUploadError() {
    assert(status == UploadStatus.UPLOADING);
    _changeStatus(UploadStatus.UPLOAD_ERROR);
  }

  void _markClaiming() {
    assert(status == UploadStatus.UPLOADED || status == UploadStatus.CLAIMING || status == UploadStatus.CLAIM_ERROR);
    _changeStatus(UploadStatus.CLAIMING);
  }

  void _markClaimError() {
    assert(status == UploadStatus.CLAIMING);
    _changeStatus(UploadStatus.CLAIM_ERROR);
  }

  void _markClaimed() async {
    assert(status == UploadStatus.UPLOADED);
    _changeStatus(UploadStatus.CLAIMED);
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
    if (status == UploadStatus.UPLOADING) {
      _status = UploadStatus.UPLOAD_ERROR;
    } else if (status == UploadStatus.CLAIMING) {
      _status = UploadStatus.CLAIM_ERROR;
    }
    notifyListeners();
  }
}

class _UploadTaskStore {
  static const key = 'uploadTasks';
  final _storage = new FlutterSecureStorage();

  Future<List<UploadTask>> load() async {
    final json = await _storage.read(key: key);
    if (json == null) {
      return <UploadTask>[];
    }

    final list = jsonDecode(json) as List;
    if (list.isEmpty) {
      return <UploadTask>[];
    }

    return list.map((i) => UploadTask.fromJson(i)).toList();
  }

  Future<void> store(Iterable<UploadTask> tasks) async {
    final json = tasks.map((item) => item.toJson()).toList();
    await _storage.write(key: key, value: jsonEncode(json));
  }
}

class UploadTaskResult {
  final String taskId;
  final String mediaUri;
  final UploadStatus status;

  UploadTaskResult({this.taskId, this.mediaUri, this.status});
}

class UploadTaskStep {
  final String taskId;
  final int progress;

  UploadTaskStep({this.taskId, this.progress});
}

class _UploadApi {

  final uploader = FlutterUploader();

  Future<String> uploadImage({String title, File file, String accessToken}) {
    final item = FileItem(savedDir: dirname(file.path),
        filename: basename(file.path));
    return uploader.enqueueBinary(url: baseServerUrl + '/file/upload/picture',
        method: UploadMethod.POST,
        file: item,
        headers: {'Authorization': accessToken, 'Content-Type': 'image/jpeg'},
        showNotification: true,
        tag: title
    );
  }

  UploadTaskResult _mapResponse(UploadTaskResponse response) {
    if (response.status == UploadTaskStatus.complete && response.statusCode == 200) {
      return UploadTaskResult(taskId: response.taskId, mediaUri: response.headers['Location'], status: UploadStatus.UPLOADED);
    } else if (response.status == UploadTaskStatus.failed) {
      return UploadTaskResult(taskId: response.taskId, status: UploadStatus.UPLOAD_ERROR);
    } else {
      return UploadTaskResult(taskId: response.taskId);
    }

  }

  Stream<UploadTaskResult> get resultStream {
    return uploader.result.map(_mapResponse);
  }

  UploadTaskStep _mapProgress(UploadTaskProgress event) {
    return UploadTaskStep(taskId: event.taskId, progress: event.progress);
  }

  Stream<UploadTaskStep> get progressStream {
    return uploader.progress.where((event) => event.status == UploadTaskStatus.running).map(_mapProgress);
  }

  void dispose() {
    uploader.dispose();
  }
}

class UploadList with IterableMixin<UploadTask>, ChangeNotifier {

  final _list = List<UploadTask>();

  UploadTask findById(String id) {
    return _list.firstWhere((other) => other.id == id);
  }

  void _add(UploadTask task) {
    _list.removeWhere((other) => other.id == task.id);
    _list.add(task);
    notifyListeners();
  }
  
  void _remove(UploadTask task) {
    _list.removeWhere((other) => other.id == task.id);
    notifyListeners();
  }

  @override
  Iterator<UploadTask> get iterator => _list.iterator;

  UploadTask elementAt(int index) {
    return _list.elementAt(index);
  }
}

class UploadService {
  static UploadService current(BuildContext context) =>
      Provider.of<UploadService>(context, listen: false);

  final _uploadTaskStore = _UploadTaskStore();
  final _uploadApi = _UploadApi();
  final AuthService _authService;
  StreamSubscription<UploadTask> _uploadSubscription;
  StreamSubscription<UploadTask> _progressSubscription;
  StreamController<UploadTask> _uploadStreamController = StreamController.broadcast();
  StreamController<UploadTask> _progressStreamController = StreamController.broadcast();
  UploadList _uploads;

  UploadService(this._authService) {
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

  Future<UploadList> currentUploads() async {
    if (_uploads != null) {
      return _uploads;
    }
    _uploads = await _initUploads();
    return _uploads;
  }

  Future<UploadList> _initUploads() async {
    final uploads = UploadList();
    for (final upload in await _uploadTaskStore.load()) {
      if (upload.file.existsSync()) {
        upload._reset();
        uploads._add(upload);
      }
    }

    for (final upload in uploads) {
      await _restartTask(upload);
    }
    return uploads;
  }

  Future<void> manageTask(UploadTask task) async {
    final uploads = await currentUploads();

    if (task.status == UploadStatus.CREATED) {
      uploads._add(task);
    }

    await _uploadTaskStore.store(uploads);

    await _restartTask(task);
  }

  Future<void> _restartTask(UploadTask task) async {
    if (task.status == UploadStatus.ANNOTATED || task.status == UploadStatus.UPLOAD_ERROR) {
      await _startUploading(task);
    } else if (task.status == UploadStatus.UPLOADED || task.status == UploadStatus.CLAIM_ERROR) {
      await _startClaiming(task);
    }
  }

  Future<void> deleteTask(UploadTask task) async {
    if (!task.canBeDeleted()) {
      throw 'Invalid task state';
    }
    final uploads = await currentUploads();
    uploads._remove(task);
    await _uploadTaskStore.store(uploads);
    await task._delete();
  }

  Future<void> _startUploading(UploadTask task) async {
    final accessToken = await _authService.accessToken;
    final taskId = await _uploadApi.uploadImage(title: task.title, file: task.file, accessToken: accessToken);
    task._markUploading(taskId);
  }

  Future<void> _startClaiming(UploadTask task) async {
    task._markClaiming();
    await Future.delayed(Duration(seconds: 5));
    task._markClaimError();
    _uploadStreamController.add(task);
  }

  Future<UploadTask> _mapUploadResult(UploadTaskResult result) async {
    final uploads = await currentUploads();
    final upload = uploads.firstWhere((item) => item.backgroundTaskId == result.taskId);
    if (result.status == UploadStatus.UPLOADED) {
      upload._markUploaded(result.mediaUri);
      _startClaiming(upload);
    } else if (result.status == UploadStatus.UPLOAD_ERROR) {
      upload._markUploadError();
    }
    await _uploadTaskStore.store(uploads);
    return upload;
  }

  Stream<UploadTask> get _uploadResultStream {
    return _uploadApi.resultStream.asyncMap(_mapUploadResult);
  }

  Stream<UploadTask> get uploadResultStream => _uploadStreamController.stream;

  Future<UploadTask> _mapUploadProgress(UploadTaskStep step) async {
    final uploads = await currentUploads();
    final upload = uploads.firstWhere((item) => item.backgroundTaskId == step.taskId);
    upload._setUploadProgress(step.progress);
    return upload;
  }

  Stream<UploadTask> get _uploadProgressStream {
    return _uploadApi.progressStream.asyncMap(_mapUploadProgress);
  }

  Stream<UploadTask> get uploadProgressStream => _progressStreamController.stream;
}