import 'dart:io';
import 'package:path/path.dart';
import 'package:flutter_uploader/flutter_uploader.dart';

class UploadService {
  static const baseUrl = 'http://3ft8uk98qmfq79pc.myfritz.net:18774/rest';

  final uploader = FlutterUploader();

  Future<String> uploadImage({String tag, File file, String accessToken}) {
    final item = FileItem(savedDir: dirname(file.path),
        filename: basename(file.path));
    print( {'Authorization': accessToken, 'Content-Type': 'image/jpeg'});
    return uploader.enqueueBinary(url: baseUrl + '/file/upload/picture',
        method: UploadMethod.POST,
        file: item,
        headers: {'Authorization': accessToken, 'Content-Type': 'image/jpeg'},
        showNotification: true,
        tag: tag
    );
  }
}