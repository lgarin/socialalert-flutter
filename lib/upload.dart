import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'configuration.dart';

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

class UploadTask {
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

  String get taskId => _uploadTaskId;

  String get title => _title;

  String get mediaUri => _mediaUri;

  UploadStatus get status => _status;

  DateTime get lastUpdate => _lastUpdate;

  void _changeStatus(UploadStatus newStatus) {
    _status = newStatus;
    _lastUpdate = DateTime.now();
  }

  UploadTask.fromJson(Map<String, dynamic> json) :
        timestamp = DateTime.parse(json['timestamp']),
        type = json['type'],
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
        _status = json['status'],
        _mediaUri = json['mediaUri'],
        _uploadTaskId = json["uploadTaskId"],
        _lastUpdate = DateTime.parse(json['lastUpdate']);

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp,
    'type': type,
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
    'status': _status,
    'mediaUri': _mediaUri,
    'uploadTaskId': _uploadTaskId,
    'lastUpdate': _lastUpdate,
  };

  void annotate({@required String title, String description, String category, List<String> tags,
    double latitude, double longitude, String country, String locality, String address}) {
    _title = title;
    _description = description;
    _category = category;
    _tags = tags;
    _latitude = latitude;
    _longitude = longitude;
    _country = country;
    _locality = locality;
    _address = address;
    _changeStatus(UploadStatus.ANNOTATED);
  }

  void markUploading(String uploadTaskId) {
    _uploadTaskId = uploadTaskId;
    _changeStatus(UploadStatus.UPLOADING);
  }

  void markUploaded(String mediaUri) {
    _mediaUri = mediaUri;
    _changeStatus(UploadStatus.UPLOADED);
  }

  void markUploadError() {
    _changeStatus(UploadStatus.UPLOAD_ERROR);
  }

  void markClaimed() async {
    _changeStatus(UploadStatus.CLAIMED);
    await file.delete();
  }
}

class UploadTaskStore {
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

  Future<void> store(List<UploadTask> tasks) async {
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

class UploadService {

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
    if (response.status == UploadTaskStatus.complete && response.statusCode == 201) {
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
}