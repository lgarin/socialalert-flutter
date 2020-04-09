
import 'dart:async';

import 'package:flutter_uploader/flutter_uploader.dart';

void _handleUploadException(Object error, StackTrace stackTrace, EventSink<UploadTaskResponse> sink) {
  if (error is UploadException) {
    sink.add(UploadTaskResponse(taskId: error.taskId, statusCode: error.statusCode, status: error.status, response: error.message, tag: error.tag));
  }
}

StreamTransformer<UploadTaskResponse, UploadTaskResponse> buildUploadExceptionTransformer() {
  return StreamTransformer.fromHandlers(
      handleData: (input, sink) => sink.add(input),
      handleError: _handleUploadException);
}
