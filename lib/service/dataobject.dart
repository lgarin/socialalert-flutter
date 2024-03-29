import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:social_alert_app/service/geolocation.dart';
import 'package:social_alert_app/service/serviceprodiver.dart';

class PagingParameter {
  final int pageNumber;
  final int pageSize;
  final int timestamp;

  PagingParameter({@required this.pageNumber, @required this.pageSize}) : timestamp = null;

  PagingParameter.fromJson(Map<String, dynamic> json) :
        pageNumber = json['pageNumber'],
        pageSize = json['pageSize'],
        timestamp = json['timestamp'];
}

typedef PageContentBuilder<T> = List<T> Function(List<dynamic> json);

abstract class ResultPage<T> {
  final List<T> content;
  final PagingParameter nextPage;
  final int pageCount;
  final int pageNumber;

  ResultPage.fromJson(Map<String, dynamic> json, PageContentBuilder<T> contentBuilder) :
        content = contentBuilder(json['content']),
        nextPage = json['nextPage'] != null ? PagingParameter.fromJson(json['nextPage']) : null,
        pageCount = json['pageCount'],
        pageNumber = json['pageNumber'];
}

enum ApprovalModifier {
  LIKE,
  DISLIKE,
}

const Map<String, ApprovalModifier> _approvalModifierMap = {
  'LIKE': ApprovalModifier.LIKE,
  'DISLIKE': ApprovalModifier.DISLIKE,
};

enum MediaFormat {
  MEDIA_JPG, MEDIA_MOV, MEDIA_MP4, PREVIEW_JPG, PREVIEW_MP4, THUMBNAIL_JPG
}

const Map<String, MediaFormat> _mediaFormatMap = {
  'MEDIA_JPG': MediaFormat.MEDIA_JPG,
  'MEDIA_MOV': MediaFormat.MEDIA_MOV,
  'MEDIA_MP4': MediaFormat.MEDIA_MP4,
  'PREVIEW_JPG': MediaFormat.PREVIEW_JPG,
  'PREVIEW_MP4': MediaFormat.PREVIEW_MP4,
  'THUMBNAIL_JPG': MediaFormat.THUMBNAIL_JPG
};

class MediaInfo {
  final String title;
  final String mediaUri;
  final int hitCount;
  final int likeCount;
  final int dislikeCount;
  final int commentCount;
  final double latitude;
  final double longitude;
  final MediaFormat previewFormat;
  final MediaFormat fileFormat;
  final int feeling;

  MediaInfo.fromJson(Map<String, dynamic> json) :
        title = json['title'],
        mediaUri = json['mediaUri'],
        hitCount = json['hitCount'],
        likeCount = json['likeCount'],
        dislikeCount = json['dislikeCount'],
        commentCount = json['commentCount'],
        latitude = json['latitude'],
        longitude = json['longitude'],
        previewFormat = _mediaFormatMap[json['previewFormat']],
        fileFormat = _mediaFormatMap[json['fileFormat']],
        feeling = json['feeling'];

  bool get hasVideoPreview => previewFormat == MediaFormat.PREVIEW_MP4;
  bool get isVideo => fileFormat == MediaFormat.MEDIA_MOV || fileFormat == MediaFormat.MEDIA_MP4;

  static List<MediaInfo> fromJsonList(List<dynamic> json) {
    return json.map((e) => MediaInfo.fromJson(e)).toList();
  }
}

class UserInfo {
  final String userId;
  final String username;
  final bool online;
  final String email;
  final DateTime createdTimestamp;
  final String firstname;
  final String lastname;
  final String country;
  final String imageUri;
  final String birthdate;
  final String biography;
  final String gender;
  final UserStatistic statistic;

  UserInfo.fromJson(Map<String, dynamic> json) :
        userId = json['id'],
        username = json['username'],
        online = json['online'],
        email = json['email'],
        createdTimestamp = json['createdTimestamp'] != null ? DateTime.fromMillisecondsSinceEpoch(json['createdTimestamp']) : null,
        firstname = json['firstname'],
        lastname = json['lastname'],
        country = json['country'],
        biography = json['biography'],
        birthdate = json['birthdate'],
        gender = json['gender'],
        imageUri = json['imageUri'],
        statistic = UserStatistic.fromJson(json['statistic']);
}

class UserStatistic {
  final int hitCount;
  final int likeCount;
  final int dislikeCount;
  final int followerCount;
  final int pictureCount;
  final int videoCount;
  final int commentCount;

  UserStatistic.fromJson(Map<String, dynamic> json) :
        hitCount = json['hitCount'],
        likeCount = json['likeCount'],
        dislikeCount = json['dislikeCount'],
        followerCount = json['followerCount'],
        pictureCount = json['pictureCount'],
        videoCount = json['videoCount'],
        commentCount = json['commentCount'];

  int get mediaCount => pictureCount + videoCount;
}

enum LocationPrivacy {
  BLUR,
  MASK
}

const List<String> _locationPrivacyNames = ['BLUR', 'MASK'];
const Map<String, LocationPrivacy> _locationPrivacyMap = {
  'BLUR': LocationPrivacy.BLUR,
  'MASK': LocationPrivacy.MASK,
};

class UserPrivacy {
  final bool birthdateMasked;
  final bool genderMasked;
  final bool nameMasked;
  final LocationPrivacy location;
  final bool feelingMasked;

  UserPrivacy({this.birthdateMasked, this.genderMasked, this.nameMasked, this.location, this.feelingMasked});

  UserPrivacy.fromJson(Map<String, dynamic> json) :
        birthdateMasked = json['birthdateMasked'] ?? false,
        genderMasked = json['genderMasked'] ?? false,
        nameMasked = json['nameMasked'] ?? false,
        location = json['location'] != null ? _locationPrivacyMap[json['location']] : null,
        feelingMasked = json['feelingMasked'] ?? false;

  Map<String, dynamic> toJson() => {
    'nameMasked': nameMasked,
    'genderMasked': genderMasked,
    'birthdateMasked': birthdateMasked,
    'location': location != null ? _locationPrivacyNames[location.index] : null,
    'feelingMasked': feelingMasked,
  };
}

class MediaDetail extends MediaInfo {
  static final oneMega = 1000 * 1000;
  static final numberFormat = new NumberFormat('0.0');

  final DateTime timestamp;
  final int commentCount;
  final String locality;
  final String country;
  final String category;
  final List<String> tags;
  final ApprovalModifier userApprovalModifier;
  final int userFeeling;
  final UserInfo creator;
  final String cameraMaker;
  final String cameraModel;
  final int width;
  final int height;

  MediaDetail.fromJson(Map<String, dynamic> json) :
        timestamp = DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
        commentCount = json['commentCount'],
        locality = json['locality'],
        country = json['country'],
        category = json['category'],
        tags = List<String>.from(json['tags']),
        userApprovalModifier = json['userApprovalModifier'] != null ? _approvalModifierMap[json['userApprovalModifier']] : null,
        userFeeling = json['userFeeling'],
        creator = UserInfo.fromJson(json['creator']),
        cameraMaker = json['cameraMaker'],
        cameraModel = json['cameraModel'],
        width = json['width'],
        height = json['height'],
        super.fromJson(json);

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

  String get format {
    if (height != null && width != null) {
      return numberFormat.format(height * width / oneMega) + 'MP - $height x $width';
    } else {
      return null;
    }
  }

  String get camera {
    if (cameraModel != null && cameraMaker != null) {
      return cameraMaker + " " + cameraModel;
    } else {
      return null;
    }
  }
}

class MediaInfoPage extends ResultPage<MediaInfo> {
  MediaInfoPage.fromJson(Map<String, dynamic> json) : super.fromJson(json, MediaInfo.fromJsonList);
}

class MediaCommentInfo {
  final String comment;
  final DateTime creation;
  final String id;
  final UserInfo creator;
  final MediaInfo media;
  final int likeCount;
  final int dislikeCount;
  final ApprovalModifier userApprovalModifier;

  MediaCommentInfo.fromJson(Map<String, dynamic> json) :
        comment = json['comment'],
        creation = DateTime.fromMillisecondsSinceEpoch(json['creation']),
        id = json['id'],
        creator = json['creator'] != null ? UserInfo.fromJson(json['creator']) : null,
        media = json['media'] != null ? MediaInfo.fromJson(json['media']) : null,
        likeCount = json['likeCount'],
        dislikeCount = json['dislikeCount'],
        userApprovalModifier = json['userApprovalModifier'] != null ? _approvalModifierMap[json['userApprovalModifier']] : null;

  static List<MediaCommentInfo> fromJsonList(List<dynamic> json) {
    return json.map((e) => MediaCommentInfo.fromJson(e)).toList();
  }

  String get approvalDelta {
    if (likeCount < dislikeCount) {
      return '- ${dislikeCount - likeCount}';
    }
    return '+ ${likeCount - dislikeCount}';
  }
}

class MediaCommentPage extends ResultPage<MediaCommentInfo> {
  MediaCommentPage.fromJson(Map<String, dynamic> json) : super.fromJson(json, MediaCommentInfo.fromJsonList);
}

class GeoStatistic {
  final int count;
  final double maxLat;
  final double maxLon;
  final double minLat;
  final double minLon;
  final int feelingCount;
  final int feelingSum;

  GeoStatistic.fromJson(Map<String, dynamic> json) :
        count = json['count'],
        maxLat = json['maxLat'],
        maxLon = json['maxLon'],
        minLat = json['minLat'],
        minLon = json['minLon'],
        feelingCount = json['feelingCount'],
        feelingSum = json['feelingSum'];

  double get centerLat => (maxLat + minLat) / 2.0;
  double get centerLon => (maxLon + minLon) / 2.0;

  static List<GeoStatistic> fromJsonList(List<dynamic> json) {
    return json.map((e) => GeoStatistic.fromJson(e)).toList();
  }
}

enum FeedActivity {
  NEW_MEDIA,
  NEW_COMMENT,
  LIKE_MEDIA,
  DISLIKE_MEDIA,
  LIKE_COMMENT,
  DISLIKE_COMMENT,
  WATCH_MEDIA
}

const Map<String, FeedActivity> _feedActivityMap = {
  'NEW_MEDIA': FeedActivity.NEW_MEDIA,
  'NEW_COMMENT': FeedActivity.NEW_COMMENT,
  'LIKE_MEDIA': FeedActivity.LIKE_MEDIA,
  'DISLIKE_MEDIA': FeedActivity.DISLIKE_MEDIA,
  'LIKE_COMMENT': FeedActivity.LIKE_COMMENT,
  'DISLIKE_COMMENT': FeedActivity.DISLIKE_COMMENT,
  'WATCH_MEDIA': FeedActivity.WATCH_MEDIA,
};

class FeedItem {
  final String id;
  final FeedActivity activity;
  final DateTime creation;
  final UserInfo creator;
  final MediaInfo media;
  final MediaCommentInfo comment;

  FeedItem.fromJson(Map<String, dynamic> json) :
        id = json['id'],
        activity = _feedActivityMap[json['activity']],
        creation = DateTime.fromMillisecondsSinceEpoch(json['creation']),
        creator = UserInfo.fromJson(json['creator']),
        media = MediaInfo.fromJson(json['media']),
        comment = json['comment'] != null ? MediaCommentInfo.fromJson(json['comment']) : null;

  static List<FeedItem> fromJsonList(List<dynamic> json) {
    return json.map((e) => FeedItem.fromJson(e)).toList();
  }
}

class FeedItemPage extends ResultPage<FeedItem> {
  FeedItemPage.fromJson(Map<String, dynamic> json) : super.fromJson(json, FeedItem.fromJsonList);
}

enum NotificationType {
  NEW_COMMENT,
  LIKE_MEDIA,
  DISLIKE_MEDIA,
  LIKE_COMMENT,
  DISLIKE_COMMENT,
  WATCH_MEDIA,
  JOINED_NETWORK,
  LEFT_NETWORK
}

const Map<String, NotificationType> _notificationTypeMap = {
  'NEW_COMMENT': NotificationType.NEW_COMMENT,
  'LIKE_MEDIA': NotificationType.LIKE_MEDIA,
  'DISLIKE_MEDIA': NotificationType.DISLIKE_MEDIA,
  'LIKE_COMMENT': NotificationType.LIKE_COMMENT,
  'DISLIKE_COMMENT': NotificationType.DISLIKE_COMMENT,
  'WATCH_MEDIA': NotificationType.WATCH_MEDIA,
  'JOINED_NETWORK': NotificationType.JOINED_NETWORK,
  'LEFT_NETWORK': NotificationType.LEFT_NETWORK,
};

class UserNotification {
  final String mediaUri;
  final String mediaTitle;
  final String commentId;
  final String commentText;
  final String sourceUserId;
  final String sourceUsername;
  final String targetUserId;
  final NotificationType type;

  UserNotification.fromJson(Map<String, dynamic> json) :
        mediaUri = json['mediaUri'],
        mediaTitle = json['mediaTitle'],
        commentId = json['commentId'],
        commentText = json['commentText'],
        sourceUserId = json['sourceUserId'],
        sourceUsername = json['sourceUsername'],
        targetUserId = json['targetUserId'],
        type = _notificationTypeMap[json['type']];
}

class MediaQueryParameter {
  final String label;
  final String category;
  final String keywords;
  final double latitude;
  final double longitude;
  final double radius;
  final int hitThreshold;

  MediaQueryParameter({this.label, this.category, this.keywords, this.latitude, this.longitude, this.radius, this.hitThreshold});

  Map<String, dynamic> toJson() => {
    'label': label,
    'category': category,
    'keywords': keywords,
    'latitude': latitude,
    'longitude': longitude,
    'radius': radius,
    'hitThreshold': hitThreshold,
  };
}

class GeoArea {
  final double latitude;
  final double longitude;
  final double radius;

  GeoArea.fromJson(Map<String, dynamic> json) :
        latitude = json['latitude'],
        longitude = json['longitude'],
        radius = json['radius'];
}

class MediaQueryInfo {
  final String id;
  final String label;
  final String category;
  final String keywords;
  final GeoArea location;
  final int hitThreshold;

  MediaQueryInfo.fromJson(Map<String, dynamic> json) :
        id = json['id'],
        label = json['label'],
        category = json['category'],
        keywords = json['keywords'],
        location = GeoArea.fromJson(json['location']),
        hitThreshold = json['hitThreshold'];
}

class CountByPeriod {
  final int count;
  final String key;
  final DateTime period;

  CountByPeriod.fromJson(Map<String, dynamic> json) :
        count = json['count'],
        key = json['key'],
        period = DateTime.fromMillisecondsSinceEpoch(json['period']);

  static List<CountByPeriod> fromJsonList(List<dynamic> json) {
    return json.map((e) => CountByPeriod.fromJson(e)).toList();
  }
}

enum Period {
  HOUR,
  DAY,
  WEEK,
  MONTH,
  QUARTER,
  YEAR
}

class StatisticParameter {
  final Period period;
  final bool cumulation;

  StatisticParameter(this.period, this.cumulation);
}

// TODO this class does not belong here
abstract class StatisticService<S extends Enum> extends Service {
  StatisticService(BuildContext context) : super(context);

  Future<List<CountByPeriod>> histogram(S source, String key, StatisticParameter parameter);
}