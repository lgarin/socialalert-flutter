
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

  final _notificationStreamController = StreamController<UserNotification>.broadcast();
  StreamSubscription<UserNotification> _notificationSubscription;

  ServerNotification(BuildContext context) : super(context) {
    _notificationSubscription = _authService.profileStream
        .distinct((previous, next) => previous?.username == next?.username)
        .asyncExpand((_) => _authService.getOrRenewAccessToken().asStream())
        .where((accessToken) => accessToken != null)
        .asyncExpand((accessToken) => _userNotificationApi.openNotificationStream(accessToken))
        .listen(_notificationStreamController.add, onError: _notificationStreamController.addError, onDone: _notificationStreamController.close);
  }

  static ServerNotification of(BuildContext context) => ServiceProvider.of(context);

  _UserNotificationApi get _userNotificationApi => _UserNotificationApi(lookup());
  Authentication get _authService => lookup();

  Stream<UserNotification> get userNotificationStream {
    return _notificationStreamController.stream;
  }

  @override
  void dispose() {
    _notificationSubscription.cancel();
    _notificationStreamController.close();
  }

}