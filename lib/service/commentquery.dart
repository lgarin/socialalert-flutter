import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/dataobjet.dart';
import 'package:social_alert_app/service/datasource.dart';
import 'package:social_alert_app/service/serviceprodiver.dart';

class _CommentQueryApi {

  final DataSource dataSource;

  _CommentQueryApi(this.dataSource);

  Future<MediaCommentPage> listComments({@required String type, @required String id, @required PagingParameter paging, @required String accessToken}) async {
    final timestampParameter = paging.timestamp != null ? '&pagingTimestamp=${paging.timestamp}' : '';
    final uri = '/$type/comments/$id?pageNumber=${paging.pageNumber}&pageSize=${paging.pageSize}$timestampParameter';
    final response = await dataSource.getJson(uri: uri, accessToken: accessToken);
    if (response.statusCode == 200) {
      return MediaCommentPage.fromJson(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }

  Future<MediaCommentPage> listMediaComments({@required String mediaUri, @required PagingParameter paging, @required String accessToken}) async {
    return listComments(type: 'media', id: mediaUri, paging: paging, accessToken: accessToken);
  }

  Future<MediaCommentPage> listUserComments({@required String userId, @required PagingParameter paging, @required String accessToken}) async {
    return listComments(type: 'user', id: userId, paging: paging, accessToken: accessToken);
  }
}

class CommentQueryService extends Service {

  static CommentQueryService of(BuildContext context) => ServiceProvider.of(context);

  CommentQueryService(BuildContext context) : super(context);

  Authentication get _authService => lookup();
  _CommentQueryApi get _queryApi => _CommentQueryApi(lookup());


  Future<MediaCommentPage> listMediaComments(String mediaUri, PagingParameter paging) async {
    final accessToken = await _authService.accessToken;
    try {
      return await _queryApi.listMediaComments(mediaUri: mediaUri, paging: paging, accessToken: accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<MediaCommentPage> listUserComments(String userId, PagingParameter paging) async {
    final accessToken = await _authService.accessToken;
    try {
      return await _queryApi.listUserComments(userId: userId, paging: paging, accessToken: accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  @override
  void dispose() {
  }
}