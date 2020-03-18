import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/configuration.dart';
import 'package:social_alert_app/service/mediaquery.dart';

class _MediaQueryApi {

  static const jsonMediaType = 'application/json';

  final _httpClient = Client();

  Future<Response> _postJson(String uri, String accessToken) {
    final headers = {
      'Accept': jsonMediaType,
      'Authorization': accessToken
    };
    return _httpClient.post(baseServerUrl + uri, headers: headers);
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

  Future<MediaDetail> changeApproval({String mediaUri, ApprovalModifier modifier, String accessToken}) async {
    final url = '/media/approval/${_toApprovalUri(modifier)}/$mediaUri';
    final response = await _postJson(url, accessToken);
    if (response.statusCode == 200) {
      return MediaDetail.fromJson(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }
}

class MediaUpdateService {
  final _api = _MediaQueryApi();
  final AuthService _authService;

  static MediaUpdateService current(BuildContext context) =>
      Provider.of<MediaUpdateService>(context, listen: false);

  MediaUpdateService(this._authService);

  Future<MediaDetail> changeApproval(String mediaUri, ApprovalModifier modifier) async {
    final accessToken = await _authService.accessToken;
    try {
      return await _api.changeApproval(mediaUri: mediaUri, modifier: modifier, accessToken: accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }
}
