
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/dataobjet.dart';
import 'package:social_alert_app/service/datasource.dart';
import 'package:social_alert_app/service/serviceprodiver.dart';
import 'dart:async';

class _UserNotificationApi {
  static const URI = "/user/notificationStream";

  final DataSource dataSource;

  _UserNotificationApi(this.dataSource);

  Stream<UserNotification> openNotificationStream(String accessToken) {
    return dataSource.getEventStream(uri: URI, accessToken: accessToken).map((event) => UserNotification.fromJson(jsonDecode(event.data)));
  }
}

class ServerNotification extends Service {

  ServerNotification(BuildContext context) : super(context);

  static ServerNotification of(BuildContext context) => ServiceProvider.of(context);

  _UserNotificationApi get _userNotificationApi => _UserNotificationApi(lookup());
  Authentication get _authService => lookup();

  Stream<UserNotification> get userNotificationStream {
    return _authService.obtainAccessToken().asStream().asyncExpand((accessToken) => _userNotificationApi.openNotificationStream(accessToken));
  }

  @override
  void dispose() {
  }

}