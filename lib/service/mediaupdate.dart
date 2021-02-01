import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/datasource.dart';
import 'package:social_alert_app/service/dataobjet.dart';
import 'package:social_alert_app/service/serviceprodiver.dart';

class _MediaUpdateApi {

  final DataSource dataSource;

  _MediaUpdateApi(this.dataSource);

  String _toApprovalUri(ApprovalModifier modifier) {
    if (modifier == ApprovalModifier.LIKE) {
      return 'like';
    } else if (modifier == ApprovalModifier.DISLIKE) {
      return 'dislike';
    } else {
      return 'reset';
    }
  }

  Future<MediaDetail> changeMediaApproval({String mediaUri, ApprovalModifier modifier, String accessToken}) async {
    final uri = '/media/approval/${_toApprovalUri(modifier)}/$mediaUri';
    final response = await dataSource.post(uri: uri, accessToken: accessToken);
    if (response.statusCode == 200) {
      return MediaDetail.fromJson(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }

  Future<MediaDetail> setFeeling({String mediaUri, int feeling, String accessToken}) async {
    final uri = '/media/feeling/$mediaUri/$feeling';
    final response = await dataSource.post(uri: uri, accessToken: accessToken);
    if (response.statusCode == 200) {
      return MediaDetail.fromJson(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }

  Future<MediaCommentInfo> postComment({String mediaUri, String comment, String accessToken}) async {
    final uri = '/media/comment/$mediaUri';
    final response = await dataSource.postText(uri: uri, accessToken: accessToken, body: comment);
    if (response.statusCode == 200) {
      return MediaCommentInfo.fromJson(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }

  Future<MediaCommentInfo> changeCommentApproval({String commentId, ApprovalModifier modifier, String accessToken}) async {
    final uri = '/media/comment/approval/${_toApprovalUri(modifier)}/$commentId';
    final response = await dataSource.post(uri: uri, accessToken: accessToken);
    if (response.statusCode == 200) {
      return MediaCommentInfo.fromJson(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }
}

class MediaUpdateService extends Service {

  MediaUpdateService(BuildContext context) : super(context);

  static MediaUpdateService of(BuildContext context) => ServiceProvider.of(context);

  Authentication get _authService => lookup();
  _MediaUpdateApi get _updateApi => _MediaUpdateApi(lookup());

  Future<MediaDetail> changeMediaApproval(String mediaUri, ApprovalModifier modifier) async {
    final accessToken = await _authService.obtainAccessToken();
    try {
      return await _updateApi.changeMediaApproval(mediaUri: mediaUri, modifier: modifier, accessToken: accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<MediaDetail> setFeeling(String mediaUri, int feeling) async {
    final accessToken = await _authService.obtainAccessToken();
    try {
      return await _updateApi.setFeeling(mediaUri: mediaUri, feeling: feeling, accessToken: accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<MediaCommentInfo> postComment(String mediaUri, String comment) async {
    final accessToken = await _authService.obtainAccessToken();
    try {
      return await _updateApi.postComment(mediaUri: mediaUri, comment: comment, accessToken: accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<MediaCommentInfo> changeCommentApproval(String commentId, ApprovalModifier modifier) async {
    final accessToken = await _authService.obtainAccessToken();
    try {
      return await _updateApi.changeCommentApproval(commentId: commentId, modifier: modifier, accessToken: accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  @override
  void dispose() {

  }
}
