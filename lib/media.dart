
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/base.dart';
import 'package:social_alert_app/common.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/picture.dart';
import 'package:social_alert_app/service/configuration.dart';
import 'package:social_alert_app/service/mediamodel.dart';
import 'package:social_alert_app/service/mediaquery.dart';
import 'package:social_alert_app/service/mediaupdate.dart';
import 'package:timeago_flutter/timeago_flutter.dart';

class _MediaInfoModel with ChangeNotifier {
  MediaDetail _detail;

  _MediaInfoModel(this._detail);

  String get mediaUri => _detail.mediaUri;

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
  final _scrollController = ScrollController();

  _RemotePictureDetailPageState() : super(AppRoute.RemotePictureDetail);

  @override
  void initState() {
    super.initState();
    _tabSelectionModel.addListener(() => _scrollController.jumpTo(_scrollController.position.maxScrollExtent));
  }

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
        create: _buildMediaModel,
        child: Consumer<_MediaInfoModel>(
          builder: _buildContent,
          child: NetworkPreviewImage(imageUri: widget.mediaUri)
        )
    );
  }

  Future<_MediaInfoModel> _buildMediaModel(BuildContext context) async {
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
      controller: _scrollController,
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
        SizedBox(width: 2 * spacing),
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
        _buildInteractionBar(media),
        Divider(),
        PictureInfoPanel(timestamp: media.timestamp, location: media.location, camera: media.camera, format: media.format)
      ],
    );
  }

  Widget _buildInteractionBar(MediaDetail media) {
    return Row(
        children: <Widget>[
          _ApprovalButton(ApprovalModifier.LIKE),
          SizedBox(width: 10.0,),
          _ApprovalButton(ApprovalModifier.DISLIKE),
          Spacer(),
          _buildViewCountButton(media)
        ]
    );
  }

  RaisedButton _buildViewCountButton(MediaDetail media) {
    return RaisedButton.icon(onPressed: null,
        disabledTextColor: Colors.black,
        icon: Icon(Icons.remove_red_eye),
        label: Text(media.hitCount.toString())
    );
  }
}

class _MediaFeedPanel extends StatefulWidget {

  _MediaFeedPanel({Key key}) : super(key: key);

  @override
  _MediaFeedPanelState createState() => _MediaFeedPanelState();
}

class _MediaFeedPanelState extends State<_MediaFeedPanel> {

  static final buttonColor = Color.fromARGB(255, 231, 40, 102);

  final _formKey = GlobalKey<FormState>();
  var _editingComment = false;

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<_MediaInfoModel>(context);
    final media = model.detail;
    return Column(
        children: <Widget>[
          _buildInteractionBar(media),
          Divider(),
          _editingComment ? _buildNewCommentForm(context) : SizedBox(height: 350, child: _MediaCommentList(model.mediaUri))
        ]
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    if (!_editingComment) {
      return SizedBox(width: 0);
    }
    return FlatButton.icon(
        label: Text('Cancel'),
        icon: Icon(Icons.cancel),
        color: Colors.grey,
        onPressed: _endEditingComment,
      );
  }

  void _startEditingComment() {
    setState(() {
      _editingComment = true;
    });
  }

  void _endEditingComment() {
    setState(() {
      _editingComment = false;
    });
  }

  FlatButton _buildSubmitButton(BuildContext context) {
    return FlatButton.icon(
        label: Text('Post'),
        icon: Icon(Icons.add_comment),
        color: buttonColor,
        onPressed: _editingComment ? _onPostComment : _startEditingComment
    );
  }

  void _onPostComment() {
    final formState = _formKey.currentState;
    if (formState != null && formState.validate()) {
      formState.save();
      _endEditingComment();
    }
  }

  Widget _buildNewCommentForm(BuildContext context) {
    return Form(
        key: _formKey,
        child: _buildCommentField(context)
    );
  }

  Container _buildCommentField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(10))),
      padding: EdgeInsets.all(10),
      child: TextFormField(
        onSaved: _postComment,
        autofocus: true,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        decoration: InputDecoration(
            labelText: 'Comment',
            icon: Icon(Icons.insert_comment)),
        validator: MultiValidator([
          NonEmptyValidator(errorText: "Comment required"),
          MaxLengthValidator(50, errorText: "Maximum length reached")
        ])
      ),
    );
  }

  Widget _buildInteractionBar(MediaDetail media) {
    return Row(
        children: <Widget>[
         _buildSubmitButton(context),
          SizedBox(width: 10.0,),
          _buildCancelButton(context),
          Spacer(),
          _buildCommentCountButton(media)
        ]
    );
  }

  RaisedButton _buildCommentCountButton(MediaDetail media) {
    return RaisedButton.icon(
        onPressed: null,
        disabledTextColor: Colors.black,
        icon: Icon(Icons.mode_comment),
        label: Text(media.commentCount.toString()));
  }

  void _postComment(String comment) async {
    final model = Provider.of<_MediaInfoModel>(context, listen: false);
    try {
      await MediaUpdateService.current(context).postComment(model.mediaUri, comment);
    } catch (e) {
      showSimpleDialog(context, "Post failed", e.toString());
    }
    MediaQueryService.current(context).viewDetail(model.mediaUri).then(model.refresh);
  }
}

class _MediaCommentList extends StatefulWidget {

  final String mediaUri;

  _MediaCommentList(this.mediaUri) : super(key: ValueKey(mediaUri));

  @override
  _MediaCommentListState createState() => _MediaCommentListState();
}

class _MediaCommentListState extends BasePagingState<_MediaCommentList, MediaCommentInfo> {
  @override
  Widget buildContent(BuildContext context, List<MediaCommentInfo> data) {
    if (data.isEmpty) {
      return _buildNoContent(context);
    }

    return ListView(
      children: ListTile.divideTiles(
        context: context,
        tiles: data.map(_buildTile).toList(),
      ).toList(),
    );
  }

  ListTile _buildTile(MediaCommentInfo commentInfo) {
    return ListTile(
      key: ValueKey(commentInfo.id),
      leading: UserAvatar(imageUri: commentInfo.creator.imageUri, online: commentInfo.creator.online, radius: 50.0),
      title: Row(
        children: <Widget>[
          Text(commentInfo.creator.username, style: Theme.of(context).textTheme.subtitle1,),
          Spacer(),
          Timeago(date: commentInfo.creation,
            builder: (_, value) => Text(value, style: Theme.of(context).textTheme.caption),
          )
        ],
      ),
      subtitle: Text(commentInfo.comment, softWrap: true),
    );
  }

  @override
  Future<ResultPage<MediaCommentInfo>> loadNextPage(PagingParameter parameter) {
    return MediaQueryService.current(context).listComments(widget.mediaUri, parameter);
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
        MediaUpdateService.current(context).changeApproval(model.mediaUri, _approval).then(model.refresh);
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