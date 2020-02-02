import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'configuration.dart';

enum UploadStatus {
  CREATED,
  UPLOADING,
  UPLOAD_ERROR,
  UPLOADED,
  CLAIMING,
  CLAIM_ERROR,
  CLAIMED,
}

class UploadTask {
  final DateTime timestamp;
  final String path;
  final double latitude;
  final double longitude;
  final String country;
  final String locality;
  final String address;
  final String title;
  final String description;
  final String category;
  final List<String> tags;
  UploadStatus _status;
  String _mediaUri;
  String _uploadTaskId;
  DateTime _lastUpdate;

  UploadTask({this.timestamp, this.path, this.latitude, this.longitude, this.country, this.locality, this.address,
    this.title, this.description, this.category, this.tags}) {
    _changeStatus(UploadStatus.CREATED);
  }

  String get taskId => _uploadTaskId;

  String get mediaUri => _mediaUri;

  UploadStatus get status => _status;

  DateTime get lastUpdate => _lastUpdate;

  void _changeStatus(UploadStatus newStatus) {
    _status = newStatus;
    _lastUpdate = DateTime.now();
  }

  UploadTask.fromJson(Map<String, dynamic> json) :
        timestamp = DateTime.parse(json['timestamp']),
        path = json['path'],
        latitude = json['latitude'],
        longitude = json['longitude'],
        country = json['country'],
        locality = json['locality'],
        address = json['address'],
        title = json['title'],
        description = json['description'],
        category = json['category'],
        tags = json['tags'],
        _status = json['status'],
        _mediaUri = json['mediaUri'],
        _uploadTaskId = json["uploadTaskId"],
        _lastUpdate = DateTime.parse(json['lastUpdate']);

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp,
    'path': path,
    'latitude': latitude,
    'longitude': longitude,
    'country': country,
    'locality': locality,
    'address': address,
    'title': title,
    'description': description,
    'category': category,
    'tags': tags,
    'status': _status,
    'mediaUri': _mediaUri,
    'uploadTaskId': _uploadTaskId,
    'lastUpdate': _lastUpdate,
  };

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
}

class UploadTaskStore {
  static const key = 'uploadTasks';
  final _storage = new FlutterSecureStorage();

  Future<List<UploadTask>> load() async {
    try {
      final json = await _storage.read(key: key);
      if (json == null) {
        return <UploadTask>[];
      }
      final list = jsonDecode(json) as List;
      return list.map((i) => UploadTask.fromJson(i));
    } catch (e) {
      print(e);
      return <UploadTask>[];
    }
  }

  Future<void> store(List<UploadTask> tasks) async {
    try {
      await _storage.write(key: key, value: jsonEncode(tasks));
    } catch (e) {
      print(e);
    }
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
    print(response.status);
    print(response.headers);
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