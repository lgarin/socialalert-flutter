import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/httpservice.dart';
import 'package:social_alert_app/service/serviceprodiver.dart';

class _ProfileQueryApi {

  final JsonHttpService httpService;

  _ProfileQueryApi(this.httpService);

  Future<UserProfile> get({@required String userId, @required String accessToken}) async {
    final uri = '/user/info/$userId';
    final response = await httpService.getJson(uri: uri, accessToken: accessToken);
    if (response.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }

  Future<List<UserProfile>> getFollowedUsers({@required String accessToken}) async {
    final uri = '/user/followed';
    final response = await httpService.getJson(uri: uri, accessToken: accessToken);
    if (response.statusCode == 200) {
      return  UserProfile.fromJsonList(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }
}

class ProfileQueryService extends Service {

  static ProfileQueryService current(BuildContext context) => ServiceProvider.of(context);

  ProfileQueryService(BuildContext context) : super(context);

  AuthService get _authService => lookup();
  _ProfileQueryApi get _queryApi => _ProfileQueryApi(lookup());

  Future<UserProfile> get(String userId) async {
    final accessToken = await _authService.accessToken;
    try {
      return await _queryApi.get(userId: userId, accessToken: accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<List<UserProfile>> getFollowedUsers() async {
    final accessToken = await _authService.accessToken;
    try {
      return await _queryApi.getFollowedUsers(accessToken: accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  @override
  void dispose() {
  }
}
