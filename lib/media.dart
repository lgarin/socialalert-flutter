
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/base.dart';
import 'package:social_alert_app/common.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/service/configuration.dart';
import 'package:social_alert_app/service/mediaquery.dart';
import 'package:timeago_flutter/timeago_flutter.dart';

class RemotePictureDetailPage extends StatefulWidget {

  final String mediaUri;

  RemotePictureDetailPage(this.mediaUri);

  @override
  _RemotePictureDetailPageState createState() => _RemotePictureDetailPageState();
}

class _RemotePictureDetailPageState extends BasePageState<RemotePictureDetailPage> {

  _RemotePictureDetailPageState() : super(AppRoute.RemotePictureDetail);

  @override
  Widget buildBody(BuildContext context) {
    return FutureProvider(
        key: ValueKey(widget.mediaUri),
        create: _readPictureDetail,
        child: Consumer<MediaDetail>(
          builder: _buildPictureDetail,
          child: NetworkPreviewImage(imageUri: widget.mediaUri),)
    );
  }
  
  Future<MediaDetail> _readPictureDetail(BuildContext context) {
    return MediaQueryService.current(context).viewDetail(widget.mediaUri);
  }

  Widget _buildPictureDetail(BuildContext context, MediaDetail media, Widget picture) {
    if (media == null) {
      return LoadingCircle();
    }
    return ListView(
      padding: EdgeInsets.all(10.0),
      children: <Widget>[
        _buildCreatorBanner(context, media),
        Divider(),
        Text(media.title, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.headline6),
        Text(media.description ?? '', softWrap: true),
        SizedBox(height: 5.0,),
        picture,

      ],
    );
  }

  Widget _buildCreatorBanner(BuildContext context, MediaDetail media) {
    return Row(
      children: <Widget>[
        UserAvatar(imageUri: media.creator.imageUri, online: media.creator.online, radius: 50.0),
        SizedBox(width: 5.0,),
        Text(media.creator.username, style: Theme.of(context).textTheme.headline6),
        Spacer(),
        Timeago(date: media.creation, builder: (_, value) => Text(value, style: TextStyle(fontStyle: FontStyle.italic),)),
      ],
    );
  }
}

class NetworkPreviewImage extends StatelessWidget {
  final String imageUri;

  NetworkPreviewImage({this.imageUri}) : super(key: ValueKey(imageUri));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _buildRequestHeader(context),
        builder: _buildImage,
    );
  }

  Future<Map<String, String>> _buildRequestHeader(BuildContext context) {
    return MediaQueryService.current(context).buildImagePreviewHeader();
  }

  Widget _buildImage(BuildContext context, AsyncSnapshot<Map<String, String>> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return LoadingCircle();
    }
    final url = MediaQueryService.toPreviewUrl(imageUri);
    return Hero(
        tag: imageUri,
        child: Image.network(url, cacheWidth: previewHeight, cacheHeight: previewHeight, fit: BoxFit.contain,
          headers: snapshot.data)
    );
  }

  Widget _loadingBuilder(BuildContext context, Widget child, ImageChunkEvent loadingProgress) {
    if (loadingProgress == null) {
      return LoadingCircle();
    }
    final percentage = 100 * (loadingProgress.cumulativeBytesLoaded ?? 0) / loadingProgress.expectedTotalBytes;
    print(percentage);
    if (percentage >= 100.0) {
      print('complete');
      return child;
    }
    return LoadingCircle(progressValue: percentage / 100.0);
  }
}