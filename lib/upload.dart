import 'dart:io';
import 'package:path/path.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'configuration.dart';

class UploadService {

  final uploader = FlutterUploader();

  Future<String> uploadImage({String tag, File file, String accessToken}) {
    final item = FileItem(savedDir: dirname(file.path),
        filename: basename(file.path));
    print( {'Authorization': accessToken, 'Content-Type': 'image/jpeg'});
    return uploader.enqueueBinary(url: baseServerUrl + '/file/upload/picture',
        method: UploadMethod.POST,
        file: item,
        headers: {'Authorization': accessToken, 'Content-Type': 'image/jpeg'},
        showNotification: true,
        tag: tag
    );
  }
}