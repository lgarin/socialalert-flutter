
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/configuration.dart';

class PagingParameter {
  final int pageNumber;
  final int pageSize;
  final int timestamp;
  final int offset;

  PagingParameter.fromJson(Map<String, dynamic> json) :
        pageNumber = json['pageNumber'],
        pageSize = json['pageSize'],
        timestamp = json['timestamp'],
        offset = json['offset'];
}

class MediaInfo {

  final String title;
  final String mediaUri;
  final int hitCount;
  final int likeCount;
  final int dislikeCount;

  MediaInfo.fromJson(Map<String, dynamic> json) :
        title = json['title'],
        mediaUri = json['mediaUri'],
        hitCount = json['hitCount'],
        likeCount = json['likeCount'],
        dislikeCount = json['dislikeCount'];

  static List<MediaInfo> fromJsonList(List<dynamic> json) {
    return json.map((e) => MediaInfo.fromJson(e)).toList();
  }
}

class QueryResultMediaInfo {
  final List<MediaInfo> content;
  final PagingParameter nextPage;
  final int pageCount;
  final int pageNumber;

  QueryResultMediaInfo.fromJson(Map<String, dynamic> json) :
        content = MediaInfo.fromJsonList(json['content']),
        nextPage = json['nextPage'] != null ? PagingParameter.fromJson(json['nextPage']) : null,
        pageCount = json['pageCount'],
        pageNumber = json['pageNumber'];
}

class _MediaQueryApi {

  static const jsonMediaType = 'application/json';

  final _httpClient = Client();

  Future<Response> _getJson(String uri, String accessToken) {
    final headers = {
      'Accept': jsonMediaType,
      'Authorization': accessToken
    };
    return _httpClient.get(baseServerUrl + uri, headers: headers);
  }

  Future<QueryResultMediaInfo> listMedia({String category, DateTime timestamp, int pageSize, int pageNumber, String accessToken}) async {
    final categoryParameter = category != null ? '&category=$category' : '';
    var url = '/media/search?pageNumber=$pageNumber&pageSize=$pageSize&pagingTimestamp=${timestamp.millisecondsSinceEpoch}$categoryParameter';
    final response = await _getJson(url, accessToken);
    if (response.statusCode == 200) {
      return QueryResultMediaInfo.fromJson(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }
}

class MediaQueryService {
  final _api = _MediaQueryApi();
  final AuthService _authService;

  static MediaQueryService current(BuildContext context) =>
      Provider.of<MediaQueryService>(context, listen: false);

  static String toThumbnailUrl(MediaInfo media) => baseServerUrl + '/file/thumbnail/' + media.mediaUri;

  MediaQueryService(this._authService);

  Future<QueryResultMediaInfo> listMedia(int pageSize, String category) async {
    final accessToken = await _authService.accessToken;
    try {
      return await _api.listMedia(category: category,
          timestamp: DateTime.now(), pageSize: pageSize, pageNumber: 0, accessToken: accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }
}