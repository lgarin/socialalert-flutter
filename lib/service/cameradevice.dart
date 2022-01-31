import 'package:camera/camera.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/widgets.dart';
import 'package:social_alert_app/service/serviceprodiver.dart';

class DeviceInfo {
  final String maker;
  final String model;

  DeviceInfo({@required this.maker, @required this.model});
}

class CameraDevice extends Service {
  final deviceInfo = DeviceInfoPlugin();

  static CameraDevice of(BuildContext context) => ServiceProvider.of(context);

  CameraDevice(BuildContext context) : super(context);

  Future<DeviceInfo> get info async {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    if (androidInfo != null) {
      return DeviceInfo(maker: androidInfo.manufacturer ?? androidInfo.brand, model: androidInfo.model ?? androidInfo.product);
    }
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    if (iosInfo != null) {
      return DeviceInfo(maker: iosInfo.name, model:  iosInfo.model);
    }
    return null;
  }

  Future<CameraDescription> _findCamera(CameraLensDirection lensDirection) async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return null;
      }

      return cameras.firstWhere((element) => element.lensDirection == lensDirection, orElse: () => null);
    } catch (e) {
      print(e.toString());
      throw e;
    }
  }

  Future<CameraController> findCamera(CameraLensDirection lensDirection, ResolutionPreset resolutionPreset) async {
    WidgetsFlutterBinding.ensureInitialized();

    final camera = await _findCamera(lensDirection);
    if (camera == null) {
      return null;
    }

    try {
      final controller = CameraController(camera, resolutionPreset);
      await controller.initialize();
      return controller;
    } catch (e) {
      print(e.toString());
      throw e;
    }
  }

  @override
  void dispose() {

  }
}
