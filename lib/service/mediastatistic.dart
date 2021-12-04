import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/dataobject.dart';
import 'package:social_alert_app/service/datasource.dart';
import 'package:social_alert_app/service/serviceprodiver.dart';

class _MediaStatisticApi {

  final DataSource dataSource;

  _MediaStatisticApi(this.dataSource);

  Future<List<CountByPeriod>> likesHistogram(String mediaUri, Period period, bool cumulation, String accessToken) async {
    final uri = '/feed/mediaHistogram/$mediaUri?activity=LIKE_MEDIA&interval=${describeEnum(period)}&cumulation=$cumulation';
    final response = await dataSource.getJson(uri: uri, accessToken: accessToken);
    if (response.statusCode == 200) {
      return CountByPeriod.fromJsonList(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }

  Future<List<CountByPeriod>> viewsHistogram(String mediaUri, Period period, bool cumulation, String accessToken) async {
    final uri = '/feed/mediaHistogram/$mediaUri?activity=WATCH_MEDIA&interval=${describeEnum(period)}&cumulation=$cumulation';
    final response = await dataSource.getJson(uri: uri, accessToken: accessToken);
    if (response.statusCode == 200) {
      return CountByPeriod.fromJsonList(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }
}

enum MediaStatisticSource {
  LIKES,
  VIEWS
}

class MediaStatisticService extends StatisticService<MediaStatisticSource> {

  MediaStatisticService(BuildContext context) : super(context);

  static MediaStatisticService of(BuildContext context) => ServiceProvider.of(context);

  Authentication get _authService => lookup();

  _MediaStatisticApi get _statisticApi => _MediaStatisticApi(lookup());

  Future<List<CountByPeriod>> histogram(MediaStatisticSource source, String userId, StatisticParameter parameter) async {
    final accessToken = await _authService.obtainAccessToken();
    try {
      switch (source) {
        case MediaStatisticSource.LIKES:
          return await _statisticApi.likesHistogram(userId, parameter.period, parameter.cumulation, accessToken);
        case MediaStatisticSource.VIEWS:
          return await _statisticApi.viewsHistogram(userId, parameter.period, parameter.cumulation, accessToken);
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