import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/configuration.dart';
import 'package:social_alert_app/service/mediamodel.dart';

class _MediaQueryApi {

  static const jsonMediaType = 'application/json; charset=UTF-8';

  final _httpClient = Client();

  Future<Response> _getJson(String uri, String accessToken) {
    final headers = {
      'Accept': jsonMediaType,
      'Authorization': accessToken
    };
    return _httpClient.get(baseServerUrl + uri, headers: headers);
  }

  Future<MediaInfoPage> listMedia({String category, String keywords, LatLngBounds bounds, @required PagingParameter paging, @required String accessToken}) async {
    final categoryParameter = category != null ? '&category=$category' : '';
    final keywordsParameter = keywords != null ? '&keywords=$keywords' : '';
    final boundsParameter = bounds != null ? '&minLongitude=${bounds.southwest.longitude}&maxLongitude=${bounds.northeast.longitude}&minLatitude=${bounds.southwest.latitude}&maxLatitude=${bounds.northeast.latitude}' : '';
    final timestampParameter = paging.timestamp != null ? '&pagingTimestamp=${paging.timestamp}' : '';
    final url = '/media/search?pageNumber=${paging.pageNumber}&pageSize=${paging.pageSize}$timestampParameter$categoryParameter$keywordsParameter$boundsParameter';
    final response = await _getJson(url, accessToken);
    if (response.statusCode == 200) {
      return MediaInfoPage.fromJson(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }

  Future<List<GeoStatistic>> mapMediaCount({String category, String keywords, @required LatLngBounds bounds, @required String accessToken}) async {
    final categoryParameter = category != null ? '&category=$category' : '';
    final keywordsParameter = keywords != null ? '&keywords=$keywords' : '';
    final boundsParameter = 'minLongitude=${bounds.southwest.longitude}&maxLongitude=${bounds.northeast.longitude}&minLatitude=${bounds.southwest.latitude}&maxLatitude=${bounds.northeast.latitude}';
    final url = '/media/mapCount?$boundsParameter$categoryParameter$keywordsParameter';
    final response = await _getJson(url, accessToken);
    if (response.statusCode == 200) {
      return GeoStatistic.fromJsonList(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }

  Future<List<String>> suggestTags({@required String term, @required int maxHitCount, @required String accessToken}) async {
    final url = '/media/suggestTags?term=$term&maxHitCount=$maxHitCount';
    final response = await _getJson(url, accessToken);
    if (response.statusCode == 200) {
      return List<String>.from(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }

  Future<MediaDetail> viewDetail({@required String mediaUri, @required String accessToken}) async {
    final url = '/media/view/$mediaUri';
    final response = await _getJson(url, accessToken);
    if (response.statusCode == 200) {
      return MediaDetail.fromJson(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }

  Future<MediaCommentPage> listComments({@required String mediaUri, @required PagingParameter paging, @required String accessToken}) async {
    final timestampParameter = paging.timestamp != null ? '&pagingTimestamp=${paging.timestamp}' : '';
    final url = '/media/comments/$mediaUri?pageNumber=${paging.pageNumber}&pageSize=${paging.pageSize}$timestampParameter';
    final response = await _getJson(url, accessToken);
    if (response.statusCode == 200) {
      print(response.body);
      return MediaCommentPage.fromJson(jsonDecode(response.body));
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

  Future<MediaInfoPage> listMedia(String category, String keywords, PagingParameter paging, {LatLngBounds bounds}) async {
    if (keywords.isEmpty) {
      keywords = null;
    }
    final accessToken = await _authService.accessToken;
    try {
      return await _api.listMedia(category: category, keywords: keywords, bounds: bounds,
          paging: paging, accessToken: accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<List<GeoStatistic>> mapMediaCount(String category, String keywords, LatLngBounds bounds) async {
    if (keywords.isEmpty) {
      keywords = null;
    }
    final accessToken = await _authService.accessToken;
    try {
      return await _api.mapMediaCount(category: category, keywords: keywords, bounds: bounds, accessToken: accessToken);
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

  Future<MediaCommentPage> listComments(String mediaUri, PagingParameter paging) async {
    final accessToken = await _authService.accessToken;
    try {
      return await _api.listComments(mediaUri: mediaUri, paging: paging, accessToken: accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }

}