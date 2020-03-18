
import 'package:flutter/cupertino.dart';
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

  final MediaInfo _media;

  RemotePictureDetailPage(this._media);

  String get mediaUri => _media.mediaUri;

  String get mediaTitle => _media.title;

  @override
  _RemotePictureDetailPageState createState() => _RemotePictureDetailPageState();
}

class _RemotePictureDetailPageState extends BasePageState<RemotePictureDetailPage> {

  final _tabSelectionModel = _MediaTabSelectionModel();

  _RemotePictureDetailPageState() : super(AppRoute.RemotePictureDetail);

  AppBar buildAppBar() {
    return AppBar(
      title: Text(widget.mediaTitle, overflow: TextOverflow.ellipsis),
    );
  }

  Widget buildNavBar(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _tabSelectionModel,
      child: _MediaBottomNavigationBar(),
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return FutureProvider(
        key: ValueKey(widget.mediaUri),
        create: _readPictureDetail,
        catchError: _handleError,
        child: Consumer<MediaDetail>(
          builder: _buildPictureDetail,
          child: NetworkPreviewImage(imageUri: widget.mediaUri),)
    );
  }

  MediaDetail _handleError(BuildContext context, Object error) {
   print(error.toString());
    return null;
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
        _buildMediaTitle(media, context),
        _buildMediaDescription(media),
        SizedBox(height: 5.0,),
        picture,
        ChangeNotifierProvider.value(value: _tabSelectionModel, child: _MediaInteractionBar()),
      ],
    );
  }

  Text _buildMediaDescription(MediaDetail media) {
    return Text(media.description ?? '', softWrap: true);
  }

  Text _buildMediaTitle(MediaDetail media, BuildContext context) {
    return Text(media.title, overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.headline6);
  }

  Widget _buildCreatorBanner(BuildContext context, MediaDetail media) {
    return Row(
      children: <Widget>[
        UserAvatar(imageUri: media.creator.imageUri, online: media.creator.online, radius: 50.0),
        SizedBox(width: 5.0,),
        Text(media.creator.username, style: Theme.of(context).textTheme.headline6),
        Spacer(),
        Timeago(date: media.timestamp, builder: (_, value) => Text(value, style: TextStyle(fontStyle: FontStyle.italic),)),
      ],
    );
  }
}

class _MediaInteractionBar extends StatelessWidget {

  static final buttonColor = Color.fromARGB(255, 231, 40, 102);

  @override
  Widget build(BuildContext context) {
    final tabSelectionModel = Provider.of<_MediaTabSelectionModel>(context);
    final media = Provider.of<MediaDetail>(context);
    Widget lastWidget = tabSelectionModel.feedSelected ? _buildAddCommentButton(media) : _buildViewCountButton(media);
    return Row(
        children: <Widget>[
          _buidLikeButton(media),
          SizedBox(width: 10.0,),
          _buidDislikeButton(media),
          Spacer(),
          lastWidget
        ]
    );
  }

  RaisedButton _buildAddCommentButton(MediaDetail media) {
    return RaisedButton.icon(onPressed: () {}, color: Colors.white, icon: Icon(Icons.add_comment), label: Text(media.commentCount.toString()));
  }

  RaisedButton _buildViewCountButton(MediaDetail media) {
    return RaisedButton.icon(onPressed: null,
        disabledTextColor: Colors.black,
        icon: Icon(Icons.remove_red_eye),
        label: Text(media.hitCount.toString())
    );
  }

  RaisedButton _buidLikeButton(MediaDetail media) {
    VoidCallback onPressed;
    if (media.userApprovalModifier == null || media.userApprovalModifier == ApprovalModifier.DISLIKE) {
      onPressed = () {

      };
    }
    return RaisedButton.icon(onPressed: onPressed,
        color: buttonColor,
        disabledColor: buttonColor,
        icon: Icon(Icons.thumb_up),
        label: Text(media.likeCount.toString())
    );
  }

  RaisedButton _buidDislikeButton(MediaDetail media) {
    VoidCallback onPressed;
    if (media.userApprovalModifier == null || media.userApprovalModifier == ApprovalModifier.LIKE) {
      onPressed = () {

      };
    }
    return RaisedButton.icon(onPressed: onPressed,
        color: buttonColor,
        disabledColor: buttonColor,
        icon: Icon(Icons.thumb_down),
        label: Text(media.dislikeCount.toString())
    );
  }
}

class _MediaBottomNavigationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tabSelectionModel = Provider.of<_MediaTabSelectionModel>(context);
    return BottomNavigationBar(
        currentIndex: tabSelectionModel._currentDisplayIndex,
        onTap: tabSelectionModel.tabSelected,
        items: <BottomNavigationBarItem>[
          new BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            title: Text('Details'),
          ),
          new BottomNavigationBarItem(
            icon: Icon(Icons.create),
            title: Text('Scribes'),
          ),
        ]
    );
  }
}

class _MediaTabSelectionModel with ChangeNotifier {
  static const infoIndex = 0;
  static const feedIndex = 1;

  int _currentDisplayIndex = infoIndex;

  final bucket = PageStorageBucket();

  int get currentDisplayIndex => _currentDisplayIndex;

  bool get feedSelected => _currentDisplayIndex == feedIndex;

  bool get infoSelected => _currentDisplayIndex == infoIndex;

  void tabSelected(int index) {
    _currentDisplayIndex = index;
    notifyListeners();
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
        child: Image.network(url, cacheWidth: previewHeight, cacheHeight: previewHeight, fit: BoxFit.fitWidth,
          headers: snapshot.data, loadingBuilder: _loadingBuilder)
    );
  }

  Widget _loadingBuilder(BuildContext context, Widget child, ImageChunkEvent loadingProgress) {
    if (loadingProgress == null) {
      return child;
    }
    final progress = loadingProgress.expectedTotalBytes == null ? null :
      loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes;
    return Container(
      decoration: BoxDecoration(border: Border.all()),
      height: previewHeight.roundToDouble() / MediaQuery.of(context).devicePixelRatio,
      width: previewWidth.roundToDouble() / MediaQuery.of(context).devicePixelRatio,
      child: Center(
        child: CircularProgressIndicator(value: progress)
      )
    );
  }
}