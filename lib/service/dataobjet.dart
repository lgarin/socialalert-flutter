import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:social_alert_app/service/configuration.dart';
import 'package:social_alert_app/service/geolocation.dart';

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

class MediaInfo {
  final String title;
  final String mediaUri;
  final int hitCount;
  final int likeCount;
  final int dislikeCount;
  final int commentCount;
  final double latitude;
  final double longitude;

  MediaInfo.fromJson(Map<String, dynamic> json) :
        title = json['title'],
        mediaUri = json['mediaUri'],
        hitCount = json['hitCount'],
        likeCount = json['likeCount'],
        dislikeCount = json['dislikeCount'],
        commentCount = json['commentCount'],
        latitude = json['latitude'],
        longitude = json['longitude'];

  static List<MediaInfo> fromJsonList(List<dynamic> json) {
    return json.map((e) => MediaInfo.fromJson(e)).toList();
  }
}

class CreatorStatistic {
  final int hitCount;
  final int likeCount;
  final int followerCount;
  final int pictureCount;
  final int videoCount;
  final int commentCount;

  CreatorStatistic.fromJson(Map<String, dynamic> json) :
        hitCount = json['hitCount'],
        likeCount = json['likeCount'],
        followerCount = json['followerCount'],
        pictureCount = json['pictureCount'],
        videoCount = json['videoCount'],
        commentCount = json['commentCount'];

  int get mediaCount => pictureCount + videoCount;
}

class CreatorInfo {
  final String id;
  final String username;
  final bool online;
  final String imageUri;
  final CreatorStatistic statistic;

  CreatorInfo.fromJson(Map<String, dynamic> json) :
        id = json['id'],
        username = json['username'],
        online = json['online'],
        imageUri = json['imageUri'],
        statistic = CreatorStatistic.fromJson(json['statistic']);
}

class MediaDetail extends MediaInfo {
  static final oneMega = 1000 * 1000;
  static final numberFormat = new NumberFormat('0.0');

  final String description;
  final DateTime timestamp;
  final int commentCount;
  final String locality;
  final String country;
  final String category;
  final List<String> tags;
  final ApprovalModifier userApprovalModifier;
  final CreatorInfo creator;
  final String cameraMaker;
  final String cameraModel;

  MediaDetail.fromJson(Map<String, dynamic> json) :
        description = json['description'],
        timestamp = DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
        commentCount = json['commentCount'],
        locality = json['locality'],
        country = json['country'],
        category = json['category'],
        tags = List<String>.from(json['tags']),
        userApprovalModifier = json['userApprovalModifier'] != null ? _approvalModifierMap[json['userApprovalModifier']] : null,
        creator = CreatorInfo.fromJson(json['creator']),
        cameraMaker = json['cameraMaker'],
        cameraModel = json['cameraModel'],
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

  String get format => numberFormat.format(previewHeight * previewWidth / oneMega) + 'MP - $previewWidth x $previewHeight';

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
  final CreatorInfo creator;
  final MediaInfo media;
  final int likeCount;
  final int dislikeCount;
  final ApprovalModifier userApprovalModifier;

  MediaCommentInfo.fromJson(Map<String, dynamic> json) :
        comment = json['comment'],
        creation = DateTime.fromMillisecondsSinceEpoch(json['creation']),
        id = json['id'],
        creator = json['creator'] != null ? CreatorInfo.fromJson(json['creator']) : null,
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

  GeoStatistic.fromJson(Map<String, dynamic> json) :
        count = json['count'],
        maxLat = json['maxLat'],
        maxLon = json['maxLon'],
        minLat = json['minLat'],
        minLon = json['minLon'];

  double get centerLat => (maxLat + minLat) / 2.0;
  double get centerLon => (maxLon + minLon) / 2.0;

  static List<GeoStatistic> fromJsonList(List<dynamic> json) {
    return json.map((e) => GeoStatistic.fromJson(e)).toList();
  }
}
