import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:social_alert_app/service/serviceprodiver.dart';

class FileService extends Service {

  static FileService current(BuildContext context) => ServiceProvider.of(context);

  FileService(BuildContext context) : super(context);

  Future<File> defineOutputFile(String extension) async {
    final outputDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return File(join(outputDir.path, '$timestamp.$extension'));
  }

  File replaceExtension(File file, String newExtension) {
    final filename =  basenameWithoutExtension(file.path);
    return File(join(file.parent.path, '$filename.$newExtension'));
  }

  Timer createFileSizeMonitor(File file, int maxSize, VoidCallback callback) {
    return Timer.periodic(Duration(seconds: 1), (timer) async {
        if (await file.length() > maxSize) {
          timer.cancel();
          callback();
        }
    });
  }

  @override
  void dispose() {
  }
}
