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
  double _latitude;
  double _longitude;
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

  UploadTask({@required this.file, @required this.type}) : timestamp = DateTime.now() {
    _changeStatus(UploadStatus.CREATED);
  }

  String get id => file.path;

  String get backgroundTaskId => _uploadTaskId;

  String get title => _title;

  String get mediaUri => _mediaUri;

  UploadStatus get status => _status;

  DateTime get lastUpdate => _lastUpdate;

  GeoLocation get location =>
      GeoLocation(longitude: _longitude,
          latitude: _latitude,
          locality: _locality,
          country: _country,
          address: _address);

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
    _title = title;
    _description = description;
    _category = category;
    _tags = tags;
    _latitude = location?.latitude;
    _longitude = location?.longitude;
    _country = location?.country;
    _locality = location?.locality;
    _address = location?.address;
    _changeStatus(UploadStatus.ANNOTATED);
  }

  void _markUploading(String uploadTaskId) {
    _uploadTaskId = uploadTaskId;
    _changeStatus(UploadStatus.UPLOADING);
  }

  void _markUploaded(String mediaUri) {
    _mediaUri = mediaUri;
    _changeStatus(UploadStatus.UPLOADED);
  }

  void _markUploadError() {
    _changeStatus(UploadStatus.UPLOAD_ERROR);
  }

  void _markClaimed() async {
    await file.delete();
    _changeStatus(UploadStatus.CLAIMED);
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

  UploadTaskResult _map(UploadTaskResponse response) {
    if (response.status == UploadTaskStatus.complete && response.statusCode == 200) {
      return UploadTaskResult(taskId: response.taskId, mediaUri: response.headers['Location'], status: UploadStatus.UPLOADED);
    } else if (response.status == UploadTaskStatus.failed) {
      return UploadTaskResult(taskId: response.taskId, status: UploadStatus.UPLOAD_ERROR);
    } else {
      return UploadTaskResult(taskId: response.taskId);
    }

  }

  Stream<UploadTaskResult> get resultStream {
    return uploader.result.map(_map);
  }

  void dispose() {
    uploader.dispose();
  }
}

class UploadList with IterableMixin<UploadTask>, ChangeNotifier {

  final _list = List<UploadTask>();

  UploadList(Iterable<UploadTask> source) {
    _list.addAll(source);
  }

  UploadTask findById(String id) {
    return _list.firstWhere((other) => other.id == id);
  }

  void add(UploadTask task) {
    _list.removeWhere((other) => other.id == task.id);
    _list.add(task);
    notifyListeners();
  }
  
  void remove(UploadTask task) {
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
  final _uploadService = _UploadApi();
  final AuthService _authService;
  StreamSubscription<UploadTask> _uploadSubscription;
  UploadList _uploads;

  UploadService(this._authService) {
    _uploadSubscription = uploadResultStream.listen((task) { });
  }

  void dispose() {
    _uploadSubscription.cancel();
    _uploadService.dispose();
  }

  Future<UploadList> currentUploads() async {
    if (_uploads != null) {
      return _uploads;
    }
    _uploads = UploadList(await _uploadTaskStore.load());
    final restartUploadStates = {UploadStatus.UPLOAD_ERROR, UploadStatus.UPLOADING, UploadStatus.ANNOTATED};
    for (final upload in _uploads) {
      if (restartUploadStates.contains(upload.status)) {
        await _startUpload(upload);
      }
    }
    return _uploads;
  }

  Future<void> manageTask(UploadTask task) async {
    if (_uploads == null) {
      _uploads = await currentUploads();
    }
    _uploads.add(task);
    await _uploadTaskStore.store(_uploads);
    if (task.status == UploadStatus.ANNOTATED || task.status == UploadStatus.UPLOAD_ERROR) {
      await _startUpload(task);
    } else if (task.status == UploadStatus.UPLOADED || task.status == UploadStatus.CLAIM_ERROR) {
      // TODO start claiming
    }
  }

  Future<void> _startUpload(UploadTask task) async {
    final accessToken = await _authService.accessToken;
    final taskId = await _uploadService.uploadImage(title: task.title, file: task.file, accessToken: accessToken);
    task._markUploading(taskId);
  }

  Future<UploadTask> _mapUploadResult(UploadTaskResult result) async {
    if (_uploads == null) {
      _uploads = await currentUploads();
    }
    final upload = _uploads.firstWhere((item) => item.backgroundTaskId == result.taskId);
    if (result.status == UploadStatus.UPLOADED) {
      upload._markUploaded(result.mediaUri);
    } else if (result.status == UploadStatus.UPLOAD_ERROR) {
      upload._markUploadError();
    }
    await _uploadTaskStore.store(_uploads);
    return upload;
  }

  Stream<UploadTask> get uploadResultStream {
    return _uploadService.resultStream.asyncMap(_mapUploadResult);
  }
}