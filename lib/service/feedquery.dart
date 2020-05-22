import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/datasource.dart';
import 'package:social_alert_app/service/dataobjet.dart';
import 'package:social_alert_app/service/serviceprodiver.dart';

class _FeedQueryApi {

  final DataSource dataSource;

  _FeedQueryApi(this.dataSource);

  Future<FeedItemPage> getFeed({String category, String keywords, @required PagingParameter paging, @required String accessToken}) async {
    final categoryParameter = category != null ? '&category=$category' : '';
    final keywordsParameter = keywords != null ? '&keywords=$keywords' : '';
    final timestampParameter = paging.timestamp != null ? '&pagingTimestamp=${paging.timestamp}' : '';
    final uri = '/feed/current?pageNumber=${paging.pageNumber}&pageSize=${paging.pageSize}$timestampParameter$categoryParameter$keywordsParameter';
    final response = await dataSource.getJson(uri: uri, accessToken: accessToken);
    if (response.statusCode == 200) {
      return FeedItemPage.fromJson(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }
}

class FeedQueryService extends Service {

  static FeedQueryService of(BuildContext context) => ServiceProvider.of(context);

  FeedQueryService(BuildContext context) : super(context);

  Authentication get _authService => lookup();
  _FeedQueryApi get _queryApi => _FeedQueryApi(lookup());

  Future<FeedItemPage> getFeed(String category, String keywords, PagingParameter paging) async {
    if (keywords.isEmpty) {
      keywords = null;
    }
    final accessToken = await _authService.accessToken;
    try {
      return await _queryApi.getFeed(category: category, keywords: keywords, paging: paging, accessToken: accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  @override
  void dispose() {
  }
}