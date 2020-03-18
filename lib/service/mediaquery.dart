import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/configuration.dart';
import 'package:social_alert_app/service/geolocation.dart';

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

enum ApprovalModifier {
  LIKE,
  DISLIKE,
}

const Map<String, ApprovalModifier> _approvalModifierMap = {
  'LIKE': ApprovalModifier.LIKE,
  'DISLIKE': ApprovalModifier.DISLIKE,
};

class MediaUserInfo {
  final String id;
  final String username;
  final bool online;
  final String imageUri;

  MediaUserInfo.fromJson(Map<String, dynamic> json) :
        id = json['id'],
        username = json['username'],
        online = json['online'],
        imageUri = json['imageUri'];
}

class MediaDetail {
  static final oneMega = 1000 * 1000;
  static final numberFormat = new NumberFormat('0.0');

  final String title;
  final String description;
  final DateTime timestamp;
  final String mediaUri;
  final int hitCount;
  final int likeCount;
  final int dislikeCount;
  final int commentCount;
  final double latitude;
  final double longitude;
  final String locality;
  final String country;
  final String category;
  final List<String> tags;
  final ApprovalModifier userApprovalModifier;
  final MediaUserInfo creator;
  final String cameraMaker;
  final String cameraModel;

  MediaDetail.fromJson(Map<String, dynamic> json) :
        title = json['title'],
        description = json['description'],
        timestamp = DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
        mediaUri = json['mediaUri'],
        hitCount = json['hitCount'],
        likeCount = json['likeCount'],
        dislikeCount = json['dislikeCount'],
        commentCount = json['commentCount'],
        latitude = json['latitude'],
        longitude = json['longitude'],
        locality = json['locality'],
        country = json['country'],
        category = json['category'],
        tags = List<String>.from(json['tags']),
        userApprovalModifier = _approvalModifierMap[json['userApprovalModifier']],
        creator = MediaUserInfo.fromJson(json['creator']),
        cameraMaker = json['cameraMaker'],
        cameraModel = json['cameraModel'];

  GeoLocation get location {
    if (latitude != null && longitude != null) {
      return GeoLocation(longitude: longitude,
          latitude: latitude,
          locality: locality,
          country: country,
          address: null);
    } else {
      return null;
    }
  }

  String get format => numberFormat.format(previewHeight * previewWidth / oneMega) + 'MP - $previewWidth x $previewHeight';

  String get camera {
    if (cameraModel != null && cameraMaker != null) {
      return cameraMaker + " " + cameraModel;
    } else {
      return null;
    }
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

  Future<MediaDetail> viewDetail({String mediaUri, String accessToken}) async {
    final url = '/media/view/$mediaUri';
    final response = await _getJson(url, accessToken);
    if (response.statusCode == 200) {
      return MediaDetail.fromJson(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }
}

class MediaQueryService {
  final _api = _MediaQueryApi();
  final AuthService _authService;

  static MediaQueryService current(BuildContext context) =>
      Provider.of<MediaQueryService>(context, listen: false);

  static String toThumbnailUrl(String mediaUri) => baseServerUrl + '/file/thumbnail/' + mediaUri;

  static String toPreviewUrl(String mediaUri) => baseServerUrl + '/file/preview/' + mediaUri;

  MediaQueryService(this._authService);

  Future<QueryResultMediaInfo> listMedia(String category, String keywords, PagingParameter paging) async {
    if (keywords.isEmpty) {
      keywords = null;
    }
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
    if (term == null || term.length < 3) {
      return List<String>();
    }
    final accessToken = await _authService.accessToken;
    try {
      return await _api.suggestTags(term: term, maxHitCount: maxHitCount, accessToken: accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<MediaDetail> viewDetail(String mediaUri) async {
    final accessToken = await _authService.accessToken;
    try {
      return await _api.viewDetail(mediaUri: mediaUri, accessToken: accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<Map<String, String>> buildImagePreviewHeader() async {
    final accessToken = await _authService.accessToken;
    return {
      'Accept': 'image/jpeg',
      'Authorization': accessToken
    };
  }
}