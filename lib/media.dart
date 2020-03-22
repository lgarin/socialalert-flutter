
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/base.dart';
import 'package:social_alert_app/common.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/picture.dart';
import 'package:social_alert_app/service/configuration.dart';
import 'package:social_alert_app/service/mediaquery.dart';
import 'package:social_alert_app/service/mediaupdate.dart';
import 'package:timeago_flutter/timeago_flutter.dart';

class _MediaInfoModel with ChangeNotifier {
  MediaDetail _detail;

  _MediaInfoModel(this._detail);

  MediaDetail get detail => _detail;

  void refresh(MediaDetail newDetail) {
    _detail = newDetail;
    notifyListeners();
  }
}

class RemotePictureDetailPage extends StatefulWidget {

  final MediaInfo _media;

  RemotePictureDetailPage(this._media);

  String get mediaUri => _media.mediaUri;

  String get mediaTitle => _media.title;

  @override
  _RemotePictureDetailPageState createState() => _RemotePictureDetailPageState();
}

class _RemotePictureDetailPageState extends BasePageState<RemotePictureDetailPage> {
  static const spacing = 5.0;

  final _tabSelectionModel = _MediaTabSelectionModel();

  _RemotePictureDetailPageState() : super(AppRoute.RemotePictureDetail);

  Widget buildDrawer() => null;

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
        child: Consumer<_MediaInfoModel>(
          builder: _buildContent,
          child: NetworkPreviewImage(imageUri: widget.mediaUri),)
    );
  }

  Future<_MediaInfoModel> _readPictureDetail(BuildContext context) async {
    try {
      final detail = await MediaQueryService.current(context).viewDetail(widget.mediaUri);
      return _MediaInfoModel(detail);
    } catch (e) {
      showSimpleDialog(context, 'Load failed', e.toString());
      return null;
    }
  }

  Widget _buildContent(BuildContext context, _MediaInfoModel model, Widget picture) {
    if (model == null) {
      return LoadingCircle();
    }
    return ListView(
      padding: EdgeInsets.all(2 * spacing),
      children: <Widget>[
        _buildCreatorBanner(context, model.detail),
        Divider(),
        _buildMediaTitle(context, model.detail),
        _buildMediaDescription(context, model.detail),
        SizedBox(height: spacing),
        picture,
        ChangeNotifierProvider.value(value: model,
          child: _tabSelectionModel.buildBottomPanel()
        )
      ],
    );
  }

  Text _buildMediaDescription(BuildContext context, MediaDetail media) {
    return Text(media.description ?? '', softWrap: true);
  }

  Text _buildMediaTitle(BuildContext context, MediaDetail media) {
    return Text(media.title, overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.headline6);
  }

  Widget _buildCreatorBanner(BuildContext context, MediaDetail media) {
    return Row(
      children: <Widget>[
        UserAvatar(imageUri: media.creator.imageUri, online: media.creator.online, radius: 50.0),
        SizedBox(width: spacing),
        Text(media.creator.username, style: Theme.of(context).textTheme.headline6),
        Spacer(),
        Timeago(date: media.timestamp, builder: (_, value) => Text(value, style: TextStyle(fontStyle: FontStyle.italic),)),
      ],
    );
  }
}

class _MediaDetailPanel extends StatelessWidget {

  _MediaDetailPanel({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<_MediaInfoModel>(context);
    final media = model.detail;
    return Column(
      children: <Widget>[
        _MediaInteractionBar(feed: false),
        Divider(),
        PictureInfoPanel(timestamp: media.timestamp, location: media.location, camera: media.camera, format: media.format)
      ],
    );
  }
}

class _MediaFeedPanel extends StatelessWidget {

  _MediaFeedPanel({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
        children: <Widget>[
          _MediaInteractionBar(feed: true),
          Divider(),
          _buildNoContent(context)
        ]
    );
  }

  Column _buildNoContent(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(Icons.create, size: 100, color: Colors.grey),
        Text('No content yet', style: Theme
            .of(context)
            .textTheme
            .headline6),
        Text('Be the first to post some comments here.')
      ],
    );
  }
}

class _MediaInteractionBar extends StatelessWidget {

  final bool feed;

  const _MediaInteractionBar({Key key, this.feed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<_MediaInfoModel>(context);
    Widget lastWidget = feed ? _buildAddCommentButton(model) : _buildViewCountButton(model);
    return Row(
        children: <Widget>[
          _ApprovalButton(ApprovalModifier.LIKE),
          SizedBox(width: 10.0,),
          _ApprovalButton(ApprovalModifier.DISLIKE),
          Spacer(),
          lastWidget
        ]
    );
  }

  RaisedButton _buildAddCommentButton(_MediaInfoModel model) {
    final media = model.detail;
    return RaisedButton.icon(onPressed: () {}, color: Colors.grey, icon: Icon(Icons.add_comment), label: Text(media.commentCount.toString()));
  }

  RaisedButton _buildViewCountButton(_MediaInfoModel model) {
    final media = model.detail;
    return RaisedButton.icon(onPressed: null,
        disabledTextColor: Colors.black,
        icon: Icon(Icons.remove_red_eye),
        label: Text(media.hitCount.toString())
    );
  }
}

class _ApprovalButton extends StatelessWidget {
  static final buttonColor = Color.fromARGB(255, 231, 40, 102);

  final ApprovalModifier _approval;
  final ApprovalModifier _inverseApproval;

  static ApprovalModifier _computeInverse(ApprovalModifier modifier) {
    if (modifier == ApprovalModifier.DISLIKE) {
      return ApprovalModifier.LIKE;
    } else if (modifier == ApprovalModifier.LIKE) {
      return ApprovalModifier.DISLIKE;
    } else {
      return null;
    }
  }

  _ApprovalButton(this._approval) : _inverseApproval = _computeInverse(_approval);

  IconData _computeIcon(MediaDetail media) {
    switch (_approval) {
      case ApprovalModifier.DISLIKE: return Icons.thumb_down;
      case ApprovalModifier.LIKE: return Icons.thumb_up;
      default: return null;
    }
  }

  String _computeLabel(MediaDetail media) {
    switch (_approval) {
      case ApprovalModifier.DISLIKE: return media.dislikeCount.toString();
      case ApprovalModifier.LIKE: return media.likeCount.toString();
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<_MediaInfoModel>(context);
    final media = model.detail;
    VoidCallback onPressed;
    if (media.userApprovalModifier == null || media.userApprovalModifier == _inverseApproval) {
      onPressed = () {
        MediaUpdateService.current(context).changeApproval(media.mediaUri, _approval).then(model.refresh);
      };
    }
    return RaisedButton.icon(onPressed: onPressed,
        color: buttonColor,
        disabledColor: buttonColor,
        icon: Icon(_computeIcon(media)),
        label: Text(_computeLabel(media))
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

  final List<Widget> _pages = [
    _MediaDetailPanel(
      key: PageStorageKey('Detail'),
    ),
    _MediaFeedPanel(
      key: PageStorageKey('Feed'),
    ),
  ];

  Widget buildBottomPanel() {
    return ChangeNotifierProvider.value(value: this,
      child: Consumer<_MediaTabSelectionModel>(
        builder: (context, value, _) => PageStorage(
          child: _pages[_currentDisplayIndex],
          bucket: bucket)
      )
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
      return _buildProgressIndicator(context, null);
    }
    final orientation = MediaQuery.of(context).orientation;
    final url = MediaQueryService.toPreviewUrl(imageUri);
    return Hero(
        tag: imageUri,
        child: Image.network(url, cacheWidth: previewHeight, cacheHeight: previewHeight,
            fit: orientation == Orientation.portrait ? BoxFit.fitWidth : BoxFit.fitHeight,
            headers: snapshot.data, loadingBuilder: _loadingBuilder)
    );
  }

  Widget _loadingBuilder(BuildContext context, Widget child, ImageChunkEvent loadingProgress) {
    if (loadingProgress == null) {
      return child;
    }
    final progress = loadingProgress.expectedTotalBytes == null ? null :
      loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes;
    return _buildProgressIndicator(context, progress);
  }
  
  Widget _buildProgressIndicator(BuildContext context, double progress) {
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