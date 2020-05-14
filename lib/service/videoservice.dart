import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:social_alert_app/service/fileservice.dart';
import 'package:social_alert_app/service/serviceprodiver.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoService extends Service {

  static VideoService current(BuildContext context) => ServiceProvider.of(context);

  VideoService(BuildContext context) : super(context);

  FileService get _fileService => lookup();

  Future<File> createThumbnail(File videoFile) async {
    final thumbnailFile = _fileService.replaceExtension(videoFile, 'jpg');
    print(thumbnailFile);
    if (await thumbnailFile.exists()) {
      return thumbnailFile;
    }
    await VideoThumbnail.thumbnailFile(
      video: videoFile.path,
      thumbnailPath: thumbnailFile.path,
      imageFormat: ImageFormat.JPEG,
      timeMs: 1000,
      maxHeight: 160,
      maxWidth: 90,
      quality: 100,
    );
    return thumbnailFile;
  }

  @override
  void dispose() {
  }
}
