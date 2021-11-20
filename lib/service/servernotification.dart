
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/dataobject.dart';
import 'package:social_alert_app/service/datasource.dart';
import 'package:social_alert_app/service/serviceprodiver.dart';
import 'dart:async';

class _ServerNotificationApi {

  final DataSource dataSource;

  _ServerNotificationApi(this.dataSource);

  Stream<UserNotification> openNotificationStream(String accessToken) {
    final uri = '/user/notificationStream';
    return dataSource.getEventStream(uri: uri, accessToken: accessToken).map((event) => UserNotification.fromJson(jsonDecode(event.data)));
  }

  Future<MediaQueryInfo> setCurrentLiveQuery(MediaQueryParameter parameter, String accessToken) async {
    final uri = '/media/liveQuery';
    final response = await dataSource.postJson(uri: uri, body: parameter, accessToken: accessToken);
    if (response.statusCode == 200) {
      return MediaQueryInfo.fromJson(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }

  Future<MediaQueryInfo> getCurrentLiveQuery(String accessToken) async {
    final uri = '/media/liveQuery';
    final response = await dataSource.getJson(uri: uri, accessToken: accessToken);
    if (response.statusCode == 200) {
      return MediaQueryInfo.fromJson(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
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
        .asyncExpand((accessToken) => _notificationApi.openNotificationStream(accessToken))
        .listen(_notificationStreamController.add, onError: _notificationStreamController.addError, onDone: _notificationStreamController.close);
  }

  static ServerNotification of(BuildContext context) => ServiceProvider.of(context);

  _ServerNotificationApi get _notificationApi => _ServerNotificationApi(lookup());
  Authentication get _authService => lookup();

  Stream<UserNotification> get userNotificationStream {
    return _notificationStreamController.stream;
  }

  Future<MediaQueryInfo> setCurrentLiveQuery(MediaQueryParameter parameter) async {
    final accessToken = await _authService.obtainAccessToken();
    try {
      return await _notificationApi.setCurrentLiveQuery(parameter, accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<MediaQueryInfo> getCurrentLiveQuery() async {
    final accessToken = await _authService.obtainAccessToken();
    try {
      return await _notificationApi.getCurrentLiveQuery(accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  @override
  void dispose() {
    _notificationSubscription.cancel();
    _notificationStreamController.close();
  }

}