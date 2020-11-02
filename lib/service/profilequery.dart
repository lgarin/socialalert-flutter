import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/dataobjet.dart';
import 'package:social_alert_app/service/datasource.dart';
import 'package:social_alert_app/service/serviceprodiver.dart';

class _ProfileQueryApi {

  final DataSource dataSource;

  _ProfileQueryApi(this.dataSource);

  Future<UserProfile> get({@required String userId, @required String accessToken}) async {
    final uri = '/user/info/$userId';
    final response = await dataSource.getJson(uri: uri, accessToken: accessToken);
    if (response.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }

  Future<List<UserProfile>> getFollowedUsers({@required String accessToken}) async {
    final uri = '/user/followed';
    final response = await dataSource.getJson(uri: uri, accessToken: accessToken);
    if (response.statusCode == 200) {
      return  UserProfile.fromJsonList(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }

  Future<UserProfilePage> getFollowers({@required PagingParameter paging, @required String accessToken}) async {
    final timestampParameter = paging.timestamp != null ? '&pagingTimestamp=${paging.timestamp}' : '';
    final uri = '/user/followers?pageNumber=${paging.pageNumber}&pageSize=${paging.pageSize}$timestampParameter';
    final response = await dataSource.getJson(uri: uri, accessToken: accessToken);
    if (response.statusCode == 200) {
      return  UserProfilePage.fromJson(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }
}

class ProfileQueryService extends Service {

  static ProfileQueryService of(BuildContext context) => ServiceProvider.of(context);

  ProfileQueryService(BuildContext context) : super(context);

  Authentication get _authService => lookup();
  _ProfileQueryApi get _queryApi => _ProfileQueryApi(lookup());

  Future<UserProfile> get(String userId) async {
    final accessToken = await _authService.obtainAccessToken();
    try {
      return await _queryApi.get(userId: userId, accessToken: accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<List<UserProfile>> getFollowedUsers() async {
    final accessToken = await _authService.obtainAccessToken();
    try {
      return await _queryApi.getFollowedUsers(accessToken: accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<UserProfilePage> getFollowers(PagingParameter paging) async {
    final accessToken = await _authService.obtainAccessToken();
    try {
      return await _queryApi.getFollowers(paging: paging, accessToken: accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  @override
  void dispose() {
  }
}
