import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/configuration.dart';
import 'package:social_alert_app/service/httpservice.dart';
import 'package:social_alert_app/service/dataobjet.dart';
import 'package:social_alert_app/service/serviceprodiver.dart';

class _MediaQueryApi {

  final JsonHttpService httpService;

  _MediaQueryApi(this.httpService);

  Future<MediaInfoPage> listMedia({String creator, String category, String keywords, LatLngBounds bounds, @required PagingParameter paging, @required String accessToken}) async {
    final creatorParameter = creator != null ? '&creator=$creator' : '';
    final categoryParameter = category != null ? '&category=$category' : '';
    final keywordsParameter = keywords != null ? '&keywords=$keywords' : '';
    final boundsParameter = bounds != null ? '&minLongitude=${bounds.southwest.longitude}&maxLongitude=${bounds.northeast.longitude}&minLatitude=${bounds.southwest.latitude}&maxLatitude=${bounds.northeast.latitude}' : '';
    final timestampParameter = paging.timestamp != null ? '&pagingTimestamp=${paging.timestamp}' : '';
    final uri = '/media/search?pageNumber=${paging.pageNumber}&pageSize=${paging.pageSize}$timestampParameter$creatorParameter$categoryParameter$keywordsParameter$boundsParameter';
    final response = await httpService.getJson(uri: uri, accessToken: accessToken);
    if (response.statusCode == 200) {
      return MediaInfoPage.fromJson(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }

  Future<List<GeoStatistic>> mapMediaCount({String category, String keywords, @required LatLngBounds bounds, @required String accessToken}) async {
    final categoryParameter = category != null ? '&category=$category' : '';
    final keywordsParameter = keywords != null ? '&keywords=$keywords' : '';
    final boundsParameter = 'minLongitude=${bounds.southwest.longitude}&maxLongitude=${bounds.northeast.longitude}&minLatitude=${bounds.southwest.latitude}&maxLatitude=${bounds.northeast.latitude}';
    final uri = '/media/mapCount?$boundsParameter$categoryParameter$keywordsParameter';
    final response = await httpService.getJson(uri: uri, accessToken: accessToken);
    if (response.statusCode == 200) {
      return GeoStatistic.fromJsonList(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }

  Future<List<String>> suggestTags({@required String term, @required int maxHitCount, @required String accessToken}) async {
    final uri = '/media/suggestTags?term=$term&maxHitCount=$maxHitCount';
    final response = await httpService.getJson(uri: uri, accessToken: accessToken);
    if (response.statusCode == 200) {
      return List<String>.from(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }

  Future<MediaDetail> viewDetail({@required String mediaUri, @required String accessToken}) async {
    final uri = '/media/view/$mediaUri';
    final response = await httpService.getJson(uri: uri, accessToken: accessToken);
    if (response.statusCode == 200) {
      return MediaDetail.fromJson(jsonDecode(response.body));
    }
    throw response.reasonPhrase;
  }
}

class MediaQueryService extends Service {

  static String toThumbnailUrl(String mediaUri) => baseServerUrl + '/file/thumbnail/' + mediaUri;

  static String toPreviewUrl(String mediaUri) => baseServerUrl + '/file/preview/' + mediaUri;

  static String toFullUrl(String mediaUri) => baseServerUrl + '/file/download/' + mediaUri;

  static String toSmallAvatarUrl(String imageUri) => baseServerUrl + '/file/avatar/small/' + imageUri;

  static String toLargeAvatarUrl(String imageUri) => baseServerUrl + '/file/avatar/large/' + imageUri;

  static String toAvatarUrl(String imageUri, bool small) => small ? toSmallAvatarUrl(imageUri) : toLargeAvatarUrl(imageUri);

  static MediaQueryService current(BuildContext context) => ServiceProvider.of(context);

  MediaQueryService(BuildContext context) : super(context);

  AuthService get _authService => lookup();
  _MediaQueryApi get _queryApi => _MediaQueryApi(lookup());

  Future<MediaInfoPage> listMedia(String category, String keywords, PagingParameter paging, {LatLngBounds bounds}) async {
    if (keywords.isEmpty) {
      keywords = null;
    }
    final accessToken = await _authService.accessToken;
    try {
      return await _queryApi.listMedia(category: category, keywords: keywords, bounds: bounds,
          paging: paging, accessToken: accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<MediaInfoPage> listUserMedia(String userId, PagingParameter paging) async {
    final accessToken = await _authService.accessToken;
    try {
      return await _queryApi.listMedia(creator: userId,
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
      return await _queryApi.mapMediaCount(category: category, keywords: keywords, bounds: bounds, accessToken: accessToken);
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
      return await _queryApi.suggestTags(term: term, maxHitCount: maxHitCount, accessToken: accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<MediaDetail> viewDetail(String mediaUri) async {
    final accessToken = await _authService.accessToken;
    try {
      return await _queryApi.viewDetail(mediaUri: mediaUri, accessToken: accessToken);
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

  @override
  void dispose() {
  }
}