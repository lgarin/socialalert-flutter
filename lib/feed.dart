
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/base.dart';
import 'package:social_alert_app/local.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/remote.dart';
import 'package:social_alert_app/profile.dart';
import 'package:social_alert_app/feeling.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/configuration.dart';
import 'package:social_alert_app/service/dataobjet.dart';
import 'package:social_alert_app/service/eventbus.dart';
import 'package:social_alert_app/service/feedquery.dart';
import 'package:social_alert_app/service/mediaquery.dart';
import 'package:social_alert_app/service/profilequery.dart';
import 'package:timeago_flutter/timeago_flutter.dart';

class FeedDisplay extends StatefulWidget {

  final String categoryToken;
  final String keywords;

  FeedDisplay(this.categoryToken, this.keywords) : super(key: ValueKey('$categoryToken/$keywords'));

  @override
  _FeedDisplayState createState() => _FeedDisplayState();
}

class _FeedDisplayState extends BasePagingState<FeedDisplay, FeedItem> {
  static final spacing = 8.0;

  static final pictureActivityText = {
    FeedActivity.NEW_MEDIA: 'Posted a new picture',
    FeedActivity.NEW_COMMENT: 'Posted a new comment:',
    FeedActivity.DISLIKE_MEDIA: 'Disliked this picture',
    FeedActivity.LIKE_MEDIA: 'Liked this picture',
    FeedActivity.DISLIKE_COMMENT: 'Disliked this comment:',
    FeedActivity.LIKE_COMMENT: 'Liked this comment:',
    FeedActivity.WATCH_MEDIA: 'Watched this picture',
  };

  static final videoActivityText = {
    FeedActivity.NEW_MEDIA: 'Posted a new video',
    FeedActivity.NEW_COMMENT: 'Posted a new comment:',
    FeedActivity.DISLIKE_MEDIA: 'Disliked this video',
    FeedActivity.LIKE_MEDIA: 'Liked this video',
    FeedActivity.DISLIKE_COMMENT: 'Disliked this comment:',
    FeedActivity.LIKE_COMMENT: 'Liked this comment:',
    FeedActivity.WATCH_MEDIA: 'Watched this video',
  };

  static String getActivityText(FeedItem item) {
    if (item.media.isVideo) {
      return videoActivityText[item.activity];
    }
    return pictureActivityText[item.activity];
  }

  @override
  Future<FeedItemPage> loadNextPage(PagingParameter parameter) {
    return FeedQueryService.of(context).getFeed(widget.categoryToken, widget.keywords, parameter);
  }

  @override
  Widget buildContent(BuildContext context, List<FeedItem> data) {
    if (data.isEmpty) {
      return Center(child: _buildNoContent(context));
    }
    return ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: spacing),
        itemBuilder: (context, index) => _buildItem(context, data[index]),
        separatorBuilder: (context, index) => Divider(height: spacing, thickness: 1.5,),
        itemCount: data.length
    );
  }

  Widget _buildItem(BuildContext context, FeedItem item) {
    if (item.activity == FeedActivity.NEW_MEDIA) {
      return _buildLargeItem(context, item);
    }
    return _buildFeedBanner(context, item, _buildActivitySubtitle(context, item));
  }

  Widget _buildActivitySubtitle(BuildContext context, FeedItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: _buildActivityText(context, item)),
        _buildThumbnail(item)
      ],
    );
  }

  Widget _buildActivityText(BuildContext context, FeedItem item) {
    if (item.comment != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(getActivityText(item), overflow: TextOverflow.ellipsis),
          Text(item.comment.comment, softWrap: true, maxLines: 5, overflow: TextOverflow.fade, style: TextStyle(color: Colors.black),)
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(getActivityText(item), overflow: TextOverflow.ellipsis),
        _buildTitle(item)
      ],
    );
  }

  Widget _buildTitle(FeedItem item) {
    final text = Text(item.media.title, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.headline6);
    final feeling = Feeling.fromValue(item.media.feeling);
    if (feeling == null) {
      return text;
    }
    return Row(
      children: [
        Icon(feeling.icon, size: 24, color: feeling.color),
        SizedBox(width: 4),
        Flexible(child: text)
      ],
    );
  }

  Widget _buildThumbnail(FeedItem item) {
    return GestureDetector(
      child: Image.network(MediaQueryService.toThumbnailUrl(item.media.mediaUri),
          fit: BoxFit.cover, cacheHeight: thumbnailHeight, cacheWidth: thumbnailWidth, width: 80, height: 45
      ),
      onTap: () => _onThumbnailSelection(item.media),
    );
  }

  void _onThumbnailSelection(MediaInfo media) async {
    await Navigator.of(context).pushNamed(AppRoute.RemoteMediaDisplay, arguments: media);
  }

  Widget _buildLargeItem(BuildContext context, FeedItem item) {
    return Column(
      key: ValueKey(item.id),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildFeedBanner(context, item, _buildActivityText(context, item)),
        item.media.hasVideoPreview
            ? RemoteVideoDisplay(media: item.media, preview: true)
            : RemotePictureDisplay(media: item.media, preview: true),
        SizedBox(height: spacing)
      ],
    );
  }

  Widget _buildFeedBanner(BuildContext context, FeedItem item, Widget subtitle) {
    return ListTile(
        key: ValueKey(item.id),
        onTap: () => _showMediaDetail(item.media),
        contentPadding: EdgeInsets.zero,
        leading: ProfileAvatar(radius: 50.0,
          imageUri: item.creator.imageUri,
          online: item.creator.online,
          tapCallback: () => _showUserProfile(item.creator.userId)
        ),
        title: Row(
          children: <Widget>[
            UsernameCountry(
              username: item.creator.username,
              country: item.creator.country,
              textStyle: Theme.of(context).textTheme.subtitle1
            ),
            Spacer(),
            Timeago(date: item.creation,
              builder: (_, value) => Text(value, style: Theme.of(context).textTheme.caption.copyWith(fontStyle: FontStyle.italic)),
            )
         ],
        ),
        isThreeLine: true,
        dense: false,
        subtitle: subtitle,
    );
  }

  void _showMediaDetail(MediaInfo media) async {
    EventBus.of(context).fire(VideoAction.PAUSE);
    await Navigator.of(context).pushNamed(AppRoute.RemoteMediaDetail, arguments: media);
  }

  void _showUserProfile(String userId) async {
    final currentProfile = Provider.of<UserProfile>(context, listen: false);
    if (userId != currentProfile.userId) {
      final profile = await ProfileQueryService.of(context).get(userId);
      Navigator.of(context).pushNamed(AppRoute.ProfileViewer, arguments: profile);
    } else {
      Navigator.of(context).pushNamed(AppRoute.ProfileViewer);
    }
  }

  Column _buildNoContent(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(Icons.forum, size: 100, color: Colors.grey),
        Text('No content yet', style: Theme
            .of(context)
            .textTheme
            .headline6),
        Text('Add people to your network first.')
      ],
    );
  }
}