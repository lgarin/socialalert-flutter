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

  PagingParameter({this.pageNumber, this.pageSize}) : timestamp = DateTime.now().millisecondsSinceEpoch;

  PagingParameter.fromJson(Map<String, dynamic> json) :
        pageNumber = json['pageNumber'],
        pageSize = json['pageSize'],
        timestamp = json['timestamp'];
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

  Future<QueryResultMediaInfo> listMedia({String category, String keywords, PagingParameter paging, String accessToken}) async {
    final categoryParameter = category != null ? '&category=$category' : '';
    final keywordsParameter = keywords != null ? '&keywords=$keywords' : '';
    final url = '/media/search?pageNumber=${paging.pageNumber}&pageSize=${paging.pageSize}&pagingTimestamp=${paging.timestamp}$categoryParameter$keywordsParameter';
    await Future.delayed(Duration(seconds: 1));
    final response = await _getJson(url, accessToken);
    if (response.statusCode == 200) {
      return QueryResultMediaInfo.fromJson(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }

  Future<List<String>> suggestTags({String term, int maxHitCount, String accessToken}) async {
    final url = '/media/suggestTags?term=$term&maxHitCount=$maxHitCount';
    final response = await _getJson(url, accessToken);
    if (response.statusCode == 200) {
      return List<String>.from(jsonDecode(response.body));
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

  Future<QueryResultMediaInfo> listMedia(String category, String keywords, PagingParameter paging) async {
    final accessToken = await _authService.accessToken;
    try {
      return await _api.listMedia(category: category, keywords: keywords,
          paging: paging, accessToken: accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<List<String>> suggestTags(String term, int maxHitCount) async {
    final accessToken = await _authService.accessToken;
    try {
      return await _api.suggestTags(term: term, maxHitCount: maxHitCount, accessToken: accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }
}