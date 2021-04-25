import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
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
  final _sseController = StreamController<SseEvent>.broadcast();
  StreamSubscription<SseEvent> _sseSubscription;

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

  Stream<SseEvent> getEventStream({@required String uri, String accessToken}) {
    final request = Request('GET', Uri.parse(baseServerUrl + uri));
    request.headers['Accept'] = 'text/event-stream; charset=utf-8';
    if (accessToken != null) {
      request.headers['Authorization'] = accessToken;
    }
    _sseSubscription?.cancel();
    _client.send(request).then(_handleEventStream, onError: _sseController.addError);
    return _sseController.stream;
  }

  void _handleEventStream(StreamedResponse response) {
    if (response.statusCode == 200) {
      _sseSubscription = response.stream
          .transform(Utf8Decoder())
          .transform(LineSplitter())
          .transform(_SseEventParser().transformer)
          .listen(_sseController.add, onError: _sseController.addError);
    } else {
      _sseController.addError(ClientException(response.reasonPhrase, response.request.url));
    }
  }

  @override
  void dispose() {
    _sseSubscription?.cancel();
    _uploader.dispose();
    _client.close();
    _sseController.close();
  }
}

class _SseEventParser {

  static final lineRegex = RegExp(r'^([^:]*)(?::)?(?: )?(.*)?$');

  String _currentData;
  String _id;
  String _event;

  void _clearCurrentData() {
    _currentData = null;
    _id = null;
    _event = null;
  }

  void _publishEvent(EventSink<SseEvent> sink) {
    // strip ending newline from data
    if (_currentData != null && _currentData.endsWith('\n')) {
      _currentData = _currentData.substring(0, _currentData.length - 1);
    }
    if (_currentData != null) {
      print(_currentData);
      sink.add(SseEvent(id: _id, event: _event, data: _currentData));
    }
    _clearCurrentData();
  }

  void _parseLine(String line, EventSink<SseEvent> sink) {
    // This stream will receive chunks of data that is not necessarily a
    // single event. So we build events on the fly and broadcast the event as
    // soon as we encounter a double newline, then we start a new one.
    if (line.isEmpty) {
      // event is done
      _publishEvent(sink);
      return;
    }

    // match the line prefix and the value using the regex
    Match match = lineRegex.firstMatch(line);
    var field = match.group(1);
    var value = match.group(2) ?? '';
    if (field.isEmpty) {
      // lines starting with a colon are to be ignored
      return;
    }
    _assignField(field, value);
  }

  void _assignField(String field, String value) {
    switch (field) {
      case 'event':
        _event = value;
        break;
      case 'data':
        _currentData = (_currentData ?? '') + value + '\n';
        break;
      case 'id':
        _id = value;
        break;
      case 'retry':
        break;
    }
  }

  StreamTransformer<String, SseEvent> get transformer => StreamTransformer.fromHandlers(handleData: _parseLine);
}

class SseEvent {
  final String id;
  final String event;
  final String data;

  SseEvent({this.id, this.event, this.data});
}