import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/configuration.dart';
import 'package:social_alert_app/service/mediamodel.dart';

class _MediaUpdateApi {

  static const jsonMediaType = 'application/json; charset=utf-8';
  static const textMediaType = 'text/plain; charset=utf-8';

  final _httpClient = Client();

  Future<Response> _postJson(String uri, String accessToken, String body) {
    final headers = {
      'Accept': jsonMediaType,
      'Authorization': accessToken,
    };
    if (body != null) {
      headers['Content-type'] = textMediaType;
    }
    return _httpClient.post(baseServerUrl + uri, headers: headers, body: body);
  }

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
    final url = '/media/approval/${_toApprovalUri(modifier)}/$mediaUri';
    final response = await _postJson(url, accessToken, null);
    if (response.statusCode == 200) {
      return MediaDetail.fromJson(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }

  Future<MediaCommentInfo> postComment({String mediaUri, String comment, String accessToken}) async {
    final url = '/media/comment/$mediaUri';
    final response = await _postJson(url, accessToken, comment);
    if (response.statusCode == 200) {
      return MediaCommentInfo.fromJson(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }

  Future<MediaCommentInfo> changeCommentApproval({String commentId, ApprovalModifier modifier, String accessToken}) async {
    final url = '/media/comment/approval/${_toApprovalUri(modifier)}/$commentId';
    final response = await _postJson(url, accessToken, null);
    if (response.statusCode == 200) {
      return MediaCommentInfo.fromJson(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }
}

class MediaUpdateService {
  final _api = _MediaUpdateApi();
  final AuthService _authService;

  static MediaUpdateService current(BuildContext context) =>
      Provider.of<MediaUpdateService>(context, listen: false);

  MediaUpdateService(this._authService);

  Future<MediaDetail> changeMediaApproval(String mediaUri, ApprovalModifier modifier) async {
    final accessToken = await _authService.accessToken;
    try {
      return await _api.changeMediaApproval(mediaUri: mediaUri, modifier: modifier, accessToken: accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<MediaCommentInfo> postComment(String mediaUri, String comment) async {
    final accessToken = await _authService.accessToken;
    try {
      return await _api.postComment(mediaUri: mediaUri, comment: comment, accessToken: accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<MediaCommentInfo> changeCommentApproval(String commentId, ApprovalModifier modifier) async {
    final accessToken = await _authService.accessToken;
    try {
      return await _api.changeCommentApproval(commentId: commentId, modifier: modifier, accessToken: accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }
}
