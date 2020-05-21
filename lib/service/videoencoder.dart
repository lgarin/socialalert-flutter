import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:social_alert_app/service/configuration.dart';
import 'package:social_alert_app/service/filesystem.dart';
import 'package:social_alert_app/service/serviceprodiver.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoEncoder extends Service {

  static VideoEncoder current(BuildContext context) => ServiceProvider.of(context);

  VideoEncoder(BuildContext context) : super(context);

  FileSystem get _fileService => lookup();

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
      maxHeight: thumbnailHeight,
      maxWidth: thumbnailWidth,
      quality: 100,
    );
    return thumbnailFile;
  }

  @override
  void dispose() {
  }
}
