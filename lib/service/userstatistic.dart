import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/dataobject.dart';
import 'package:social_alert_app/service/datasource.dart';
import 'package:social_alert_app/service/serviceprodiver.dart';

class _UserStatisticApi {

  final DataSource dataSource;

  _UserStatisticApi(this.dataSource);

  Future<List<CountByPeriod>> likesHistogram(String userId, Period period, bool cumulation, String accessToken) async {
    final uri = '/feed/userHistogram/$userId?activity=LIKE_MEDIA&interval=${describeEnum(period)}&cumulation=$cumulation';
    final response = await dataSource.getJson(uri: uri, accessToken: accessToken);
    if (response.statusCode == 200) {
      return CountByPeriod.fromJsonList(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }

  Future<List<CountByPeriod>> viewsHistogram(String userId, Period period, bool cumulation, String accessToken) async {
    final uri = '/feed/userHistogram/$userId?activity=WATCH_MEDIA&interval=${describeEnum(period)}&cumulation=$cumulation';
    final response = await dataSource.getJson(uri: uri, accessToken: accessToken);
    if (response.statusCode == 200) {
      return CountByPeriod.fromJsonList(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }

  Future<List<CountByPeriod>> followersHistogram(String userId, Period period, bool cumulation, String accessToken) async {
    final uri = '/user/followerHistogram/$userId?interval=${describeEnum(period)}&cumulation=$cumulation';
    final response = await dataSource.getJson(uri: uri, accessToken: accessToken);
    if (response.statusCode == 200) {
      return CountByPeriod.fromJsonList(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }
}

enum UserStatisticSource {
  LIKES,
  VIEWS,
  FOLLOWERS
}

class UserStatisticService extends StatisticService<UserStatisticSource> {

  UserStatisticService(BuildContext context) : super(context);

  static UserStatisticService of(BuildContext context) => ServiceProvider.of(context);

  Authentication get _authService => lookup();

  _UserStatisticApi get _statisticApi => _UserStatisticApi(lookup());

  Future<List<CountByPeriod>> histogram(UserStatisticSource source, String userId, StatisticParameter parameter) async {
    final accessToken = await _authService.obtainAccessToken();
    try {
      switch (source) {
        case UserStatisticSource.LIKES:
          return await _statisticApi.likesHistogram(userId, parameter.period, parameter.cumulation, accessToken);
        case UserStatisticSource.VIEWS:
          return await _statisticApi.viewsHistogram(userId, parameter.period, parameter.cumulation, accessToken);
        case UserStatisticSource.FOLLOWERS:
          return await _statisticApi.followersHistogram(userId, parameter.period, parameter.cumulation, accessToken);
        default:
          throw 'source not supported';
      }
    } catch (e) {
      print(e);
      throw e;
    }
  }

  @override
  void dispose() {
  }
}