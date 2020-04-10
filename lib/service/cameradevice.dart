
import 'package:device_info/device_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:social_alert_app/service/serviceprodiver.dart';

class DeviceInfo {
  final String maker;
  final String model;

  DeviceInfo({@required this.maker, @required this.model});
}

class CameraDeviceService extends Service {
  final deviceInfo = DeviceInfoPlugin();

  static CameraDeviceService current(BuildContext context) => ServiceProvider.of(context);

  CameraDeviceService(BuildContext context) : super(context);

  Future<DeviceInfo> get device async {
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

  @override
  void dispose() {

  }


}