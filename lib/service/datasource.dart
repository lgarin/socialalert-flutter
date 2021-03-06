import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:social_alert_app/service/configuration.dart';
import 'package:social_alert_app/service/serviceprodiver.dart';

class DataSource extends Service {
  static const jsonMediaType = 'application/json; charset=UTF-8';
  static const textMediaType = 'text/plain; charset=utf-8';

  final _client = Client();
  final _uploader = FlutterUploader();

  DataSource(BuildContext context) : super(context);

  Map<String, String> _buildHeader({String contentType, String accessToken}) {
    final result = Map<String, String>();
    result['Accept'] = jsonMediaType;
    if (contentType != null) {
      result['Content-type'] = contentType;
    }
    if (accessToken != null) {
      result['Authorization'] = accessToken;
    }
    return result;
  }

  Future<Response> post({@required String uri, String accessToken}) {
    return _client.post(Uri.parse(baseServerUrl + uri), headers: _buildHeader(accessToken: accessToken));
  }

  Future<Response> postText({@required String uri, @required String body, String accessToken}) {
    return _client.post(Uri.parse(baseServerUrl + uri), headers: _buildHeader(contentType: textMediaType, accessToken: accessToken), body: body);
  }

  Future<Response> postJson({@required String uri, @required Object body, String accessToken}) {
    return _client.post(Uri.parse(baseServerUrl + uri), headers: _buildHeader(contentType: jsonMediaType, accessToken: accessToken), body: jsonEncode(body));
  }

  Future<String> queueImageUpload({@required String uri, @required File file, @required String title, bool showNotification = false, String accessToken}) {
    return _uploader.enqueueBinary(url: baseServerUrl + uri,
        method: UploadMethod.POST,
        file: FileItem(savedDir: dirname(file.path), filename: basename(file.path)),
        headers: _buildHeader(contentType: 'image/jpeg', accessToken: accessToken),
        showNotification: showNotification,
        tag: title
    );
  }

  void _handleUploadException(Object error, StackTrace stackTrace, EventSink<UploadTaskResponse> sink) {
    if (error is UploadException) {
      sink.add(UploadTaskResponse(taskId: error.taskId, statusCode: error.statusCode, status: error.status, response: error.message, tag: error.tag));
    }
  }

  StreamTransformer<UploadTaskResponse, UploadTaskResponse> _buildUploadExceptionTransformer() {
    return StreamTransformer.fromHandlers(
        handleData: (input, sink) => sink.add(input),
        handleError: _handleUploadException);
  }

  Stream<UploadTaskResponse> get uploadResultStream => _uploader.result.transform(_buildUploadExceptionTransformer());
  Stream<UploadTaskProgress> get uploadProgressStream => _uploader.progress;

  Future<Response> getJson({@required String uri, String accessToken}) {
    return _client.get(Uri.parse(baseServerUrl + uri), headers: _buildHeader(accessToken: accessToken));
  }

  @override
  void dispose() {
    _uploader.dispose();
    _client.close();
  }
}