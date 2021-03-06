
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:social_alert_app/service/serviceprodiver.dart';

class PermissionManager extends Service {

  static PermissionManager of(BuildContext context) => ServiceProvider.of(context);

  final _permissionHandler = PermissionHandler();

  PermissionManager(BuildContext context) : super(context);

  Future<bool> allows(List<PermissionGroup> requestedPermissions) async {
    final permissionMap = await _permissionHandler.requestPermissions(requestedPermissions);
    if (permissionMap.values.every((status) => status == PermissionStatus.granted)) {
      return true;
    } else if (permissionMap.values.any((status) => status == PermissionStatus.neverAskAgain)) {
      _permissionHandler.openAppSettings();
      return false;
    } else {
      return false;
    }
  }

  @override
  void dispose() {
  }
}