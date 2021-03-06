
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:social_alert_app/service/serviceprodiver.dart';

class PermissionManager extends Service {

  static PermissionManager of(BuildContext context) => ServiceProvider.of(context);

  PermissionManager(BuildContext context) : super(context);

  Future<bool> allows(List<Permission> requestedPermissions) async {
    final permissionMap = await requestedPermissions.request();
    if (permissionMap.values.every((status) => status == PermissionStatus.granted)) {
      return true;
    } else if (permissionMap.values.any((status) => status == PermissionStatus.permanentlyDenied)) {
      openAppSettings();
      return false;
    } else {
      return false;
    }
  }

  @override
  void dispose() {
  }
}