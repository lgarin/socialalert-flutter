import 'dart:async';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/base.dart';
import 'package:social_alert_app/feeling.dart';
import 'package:social_alert_app/local.dart';
import 'package:social_alert_app/profile.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/commentquery.dart';
import 'package:social_alert_app/service/configuration.dart';
import 'package:social_alert_app/service/dataobject.dart';
import 'package:social_alert_app/service/eventbus.dart';
import 'package:social_alert_app/service/mediaquery.dart';
import 'package:social_alert_app/service/mediastatistic.dart';
import 'package:social_alert_app/service/mediaupdate.dart';
import 'package:social_alert_app/service/profilequery.dart';
import 'package:timeago_flutter/timeago_flutter.dart';
import 'package:video_player/video_player.dart';

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

class RemoteMediaDetailPage extends StatefulWidget {

  final MediaInfo media;

  RemoteMediaDetailPage(this.media);

  String get mediaUri => media.mediaUri;

  String get mediaTitle => media.title;

  @override
  _RemoteMediaDetailPageState createState() => _RemoteMediaDetailPageState();
}

class _RemoteMediaDetailPageState extends BasePageState<RemoteMediaDetailPage> {
  static const spacing = 5.0;

  final _tabSelectionModel = _MediaTabSelectionModel();
  final _scrollController = ScrollController();

  _RemoteMediaDetailPageState() : super(AppRoute.RemoteMediaDetail);

  @override
  void initState() {
    super.initState();
    _tabSelectionModel.addListener(() => scrollToEnd(_scrollController));
  }

  AppBar buildAppBar() {
    return AppBar(
      title: Text(widget.mediaTitle, overflow: TextOverflow.ellipsis),
    );
  }

  Widget buildNavBar() {
    return ChangeNotifierProvider.value(
      value: _tabSelectionModel,
      child: _MediaBottomNavigationBar(),
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return FutureProvider<_MediaInfoModel>(
        initialData: null,
        create: _buildMediaModel,
        catchError: showUnexpectedError,
        child: Consumer<_MediaInfoModel>(
          builder: _buildContent,
          child: widget.media.hasVideoPreview
              ? RemoteVideoDisplay(media: widget.media, preview: true)
              : RemotePictureDisplay(media: widget.media, preview: true)
        )
    );
  }

  Future<_MediaInfoModel> _buildMediaModel(BuildContext context) async {
    try {
      final detail = await MediaQueryService.of(context).viewDetail(widget.mediaUri);
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
        SizedBox(height: spacing),
        WillPopScope(child: picture, onWillPop: () => _onCloseDetailPage(model)),
        _buildMediaTagList(context, model.detail),
        ChangeNotifierProvider.value(value: model, child: _buildBottomPanel(context)),
      ],
    );
  }

  Widget _buildBottomPanel(BuildContext context) {
    return ChangeNotifierProvider.value(
        value: _tabSelectionModel,
        child: _MediaTabWidget()
    );
  }

  Future<bool> _onCloseDetailPage(_MediaInfoModel model) {
    Navigator.of(context).pop(model.detail);
    return Future.value(false);
  }

  Widget _buildMediaTitle(BuildContext context, MediaDetail media) {
    final text = Text(media.title, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.headline6);
    final feeling = Feeling.fromValue(media.feeling);
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

  Widget _buildMediaTagList(BuildContext context, MediaDetail media) {
    final children = <Widget>[];
    if (media.category != null) {
      children.add(Chip(label: Text(media.category), backgroundColor: Colors.blueAccent));
    }
    for (final tag in media.tags ?? []) {
      children.add(Chip(label: Text(tag), backgroundColor: Colors.grey));
    }
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: children
    );
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

  Widget _buildCreatorBanner(BuildContext context, MediaDetail media) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 5.0),
      dense: true,
      isThreeLine: true,
      onTap: () => _showUserProfile(media.creator.userId),
      leading: Hero(tag: media.creator.userId,
          child: ProfileAvatar(radius: 50.0,
            imageUri: media.creator.imageUri,
            online: media.creator.online
          )
      ),
      trailing: _buildUploadTimestamp(context, media),
      title: UsernameCountry(
          username: media.creator.username,
          country: media.creator.country,
          textStyle: Theme.of(context).textTheme.headline6
      ),
      subtitle: HorizontalUserStatistic(statistic: media.creator.statistic),
    );
  }

  Widget _buildUploadTimestamp(BuildContext context, MediaDetail media) {
    final textStyle = TextStyle(fontStyle: FontStyle.italic);
    return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 100),
        child: Timeago(date: media.timestamp,
            builder: (_, value) => Text('Uploaded ' + value, softWrap: true, style: textStyle))
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
        MediaInfoPanel(timestamp: media.timestamp, location: media.location, camera: media.camera, format: media.format)
      ],
    );
  }

  Widget _buildInteractionBar(MediaDetail media) {
    return Row(
        children: <Widget>[
          _ApprovalButton(ApprovalModifier.LIKE),
          SizedBox(width: 10.0,),
          _ApprovalButton(ApprovalModifier.DISLIKE),
          SizedBox(width: 10.0,),
          _FeelingDropdown(),
          Spacer(),
          _buildViewCountButton(media)
        ]
    );
  }

  Widget _buildViewCountButton(MediaDetail media) {
    return Tooltip(
      message: 'Hit count',
      child: ElevatedButton.icon(onPressed: null,
          style: ElevatedButton.styleFrom(primary: Colors.black),
          icon: Icon(Icons.remove_red_eye),
          label: Text(media.hitCount.toString())
      ),
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
    return TextButton.icon(
        label: Text('Cancel'),
        icon: Icon(Icons.cancel),
        style: TextButton.styleFrom(backgroundColor: Colors.grey, primary: Colors.black),
        onPressed: _endEditingComment
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

  TextButton _buildSubmitButton(BuildContext context) {
    return TextButton.icon(
        label: Text(_editingComment ? 'Post scribe' : 'Add scribe'),
        icon: Icon(_editingComment ? Icons.send : Icons.create),
        style: TextButton.styleFrom(backgroundColor: buttonColor, primary: Colors.black),
        onPressed: _editingComment ? _onPostComment : _startEditingComment
    );
  }

  void _onPostComment() {
    final formState = _formKey.currentState;
    if (formState != null && formState.validate()) {
      formState.save();
    }
  }

  Widget _buildNewCommentForm(BuildContext context) {
    return Form(
        key: _formKey,
        child: _buildCommentField(context)
    );
  }

  Widget _buildCommentField(BuildContext context) {
    return WideRoundedField(
      child: TextFormField(
        onSaved: _postComment,
        autofocus: true,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        decoration: InputDecoration(
            labelText: 'Scribe',
            icon: Icon(Icons.insert_comment)),
        validator: MultiValidator([
          NonEmptyValidator(errorText: "Scribe required"),
          MaxLengthValidator(maxCommentLength, errorText: "Maximum length reached")
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

  Widget _buildCommentCountButton(MediaDetail media) {
    return Tooltip(
      message: 'Comment count',
      child: ElevatedButton.icon(
          onPressed: null,
          style: ElevatedButton.styleFrom(primary: Colors.black),
          icon: Icon(Icons.create),
          label: Text(media.commentCount.toString())),
    );
  }

  void _postComment(String comment) async {
    final model = Provider.of<_MediaInfoModel>(context, listen: false);
    try {
      await MediaUpdateService.of(context).postComment(model.mediaUri, comment);
      showSuccessSnackBar(context, 'Scribe for "${model.detail.title}" has been posted');
      _endEditingComment();
    } catch (e) {
      showSimpleDialog(context, "Post failed", e.toString());
    }
    MediaQueryService.of(context).viewDetail(model.mediaUri).then(model.refresh);
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

  void _showUserProfile(String userId) async {
    final currentProfile = Provider.of<UserProfile>(context, listen: false);
    if (userId != currentProfile.userId) {
      final profile = await ProfileQueryService.of(context).get(userId);
      Navigator.of(context).pushNamed(AppRoute.ProfileViewer, arguments: profile);
    } else {
      Navigator.of(context).pushNamed(AppRoute.ProfileViewer);
    }
  }

  ListTile _buildTile(MediaCommentInfo commentInfo) {
    return ListTile(
      key: ValueKey(commentInfo.id),
      leading: ProfileAvatar(radius: 50.0,
          imageUri: commentInfo.creator.imageUri,
          online: commentInfo.creator.online,
          tapCallback: () => _showUserProfile(commentInfo.creator.userId)
      ),
      title: Row(
        children: <Widget>[
          UsernameCountry(
            username: commentInfo.creator.username,
            country: commentInfo.creator.country,
            textStyle: Theme.of(context).textTheme.subtitle1
          ),
          Spacer(),
          Timeago(date: commentInfo.creation,
            builder: (_, value) => Text(value, style: Theme.of(context).textTheme.caption.copyWith(fontStyle: FontStyle.italic)),
          )
        ],
      ),
      subtitle: Text(commentInfo.comment, softWrap: true),
      trailing: PopupMenuButton(
        child: Column(children: <Widget>[
          SizedBox(height: 2.0),
          Icon(Icons.thumbs_up_down),
          SizedBox(height: 2.0),
          Text(commentInfo.approvalDelta)
        ]),
        itemBuilder: (context) => _buildActionMenu(context, commentInfo),
        onSelected: _onActionSelection,
      ),
    );
  }

  void _showSnackBar(BuildContext context, MediaCommentInfo comment, ApprovalModifier modifier) {
    if (modifier == ApprovalModifier.LIKE) {
      showSuccessSnackBar(context, 'You liked the scribe from "${comment.creator.username}"');
    } else if (modifier == ApprovalModifier.DISLIKE) {
      showWarningSnackBar(context, 'You disliked the scribe from "${comment.creator.username}"');
    }
  }

  void _onActionSelection(_CommentActionItem selection) {
    if (selection.action == _CommentAction.LIKE || selection.action == _CommentAction.DISLIKE) {
      MediaUpdateService.of(context).changeCommentApproval(selection.commentId, selection.modifier)
          .catchError((error) => showSimpleDialog<MediaCommentInfo>(context, 'Failure', error.toString()))
          .then(_refreshItem)
          .then((_) => _showSnackBar(context, selection.item, selection.modifier));
    }
  }

  void _refreshItem(MediaCommentInfo newInfo) {
    replaceItem((item) => item.id == newInfo.id, newInfo);
  }

  List<PopupMenuItem<_CommentActionItem>> _buildActionMenu(BuildContext context, MediaCommentInfo commentInfo) {
    return [
      PopupMenuItem(value: _CommentActionItem(_CommentAction.LIKE, commentInfo),
        enabled: commentInfo.userApprovalModifier != ApprovalModifier.LIKE,
        child: ListTile(title: Text(commentInfo.likeCount.toString()), leading: Icon(Icons.thumb_up)),
      ),
      PopupMenuItem(value:  _CommentActionItem(_CommentAction.DISLIKE, commentInfo),
        enabled: commentInfo.userApprovalModifier != ApprovalModifier.DISLIKE,
        child: ListTile(title: Text(commentInfo.dislikeCount.toString()), leading: Icon(Icons.thumb_down)),
      )
    ];
  }

  @override
  Future<ResultPage<MediaCommentInfo>> loadNextPage(PagingParameter parameter) {
    return CommentQueryService.of(context).listMediaComments(widget.mediaUri, parameter);
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
        Text('Be the first to post a scribe here.')
      ],
    );
  }
}

enum _CommentAction {
  LIKE,
  DISLIKE,
}

class _CommentActionItem {
  final _CommentAction action;
  final MediaCommentInfo item;

  _CommentActionItem(this.action, this.item);

  ApprovalModifier get modifier {
    switch (action) {
      case _CommentAction.LIKE: return ApprovalModifier.LIKE;
      case _CommentAction.DISLIKE: return ApprovalModifier.DISLIKE;
      default: return null;
    }
  }
  String get commentId => item.id;
}

class _FeelingDropdown extends StatelessWidget {
  static final buttonColor = Color.fromARGB(255, 231, 40, 102);

  DropdownMenuItem<Feeling> _buildMenuItem(Feeling feeling) {
    return DropdownMenuItem(child: Icon(feeling.icon, size: 24), value: feeling);
  }

  void _showSnackBar(BuildContext context, MediaInfo media, Feeling feeling) {
    showSuccessSnackBar(context, 'You feel ${feeling.description} about "${media.title}".');
  }

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<_MediaInfoModel>(context);
    return  Container(
      decoration: BoxDecoration(
        color: buttonColor,
        borderRadius: BorderRadius.all(Radius.circular(2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            offset: Offset(0, 1),
            blurRadius: 1,
          )
        ]
      ),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: DropdownButton<Feeling>(
          elevation: 16,
          iconSize: 32,
          hint: Icon(Feeling.neutral.icon, size: 24, color: Colors.black38),
          isDense: true,
          underline: SizedBox(height: 0,),
          items: Feeling.allDescending.map(_buildMenuItem).toList(growable: false),
          onChanged: (feeling) {
            MediaUpdateService.of(context).setFeeling(model.mediaUri, feeling.value)
                .catchError((error) => showSimpleDialog<MediaDetail>(context, 'Failure', error.toString()))
                .then(model.refresh)
                .then((_) => _showSnackBar(context, model.detail, feeling));
          },
          value: Feeling.fromValue(model.detail.userFeeling))
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

  String _computeTooltip(MediaDetail media, bool enabled) {
    switch (_approval) {
      case ApprovalModifier.DISLIKE: return enabled ? 'Add dislike' : 'Dislike count';
      case ApprovalModifier.LIKE: return enabled ? 'Add like' : 'Like count';
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

  void _showSnackBar(BuildContext context, MediaInfo media, ApprovalModifier modifier) {
    if (modifier == ApprovalModifier.LIKE) {
      showSuccessSnackBar(context, 'You liked "${media.title}"');
    } else if (modifier == ApprovalModifier.DISLIKE) {
      showWarningSnackBar(context, 'You disliked "${media.title}"');
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<_MediaInfoModel>(context);
    final media = model.detail;
    VoidCallback onPressed;
    if (media.userApprovalModifier == null || media.userApprovalModifier == _inverseApproval) {
      onPressed = () {
        MediaUpdateService.of(context).changeMediaApproval(model.mediaUri, _approval)
            .catchError((error) => showSimpleDialog<MediaDetail>(context, 'Failure', error.toString()))
            .then(model.refresh)
            .then((_) => _showSnackBar(context, media, _approval));
      };
    }
    return Tooltip(
      message: _computeTooltip(media, onPressed != null),
      child: ElevatedButton.icon(onPressed: onPressed,
          style: ElevatedButton.styleFrom(primary: buttonColor, onPrimary: Colors.black),
          icon: Icon(_computeIcon(media)),
          label: Text(_computeLabel(media))
      ),
    );
  }
}

class _MediaStatisticPanel extends StatefulWidget {

  @override
  _MediaStatisticPanelState createState() => _MediaStatisticPanelState();
}

class _MediaStatisticPanelState extends State<_MediaStatisticPanel> {

  StatisticParameter _parameter = StatisticParameter(Period.MONTH, true);

  void _onParameterChanged(StatisticParameter newParameter) {
    setState(() {
      _parameter = newParameter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<_MediaInfoModel>(context);
    final likeCount = model.detail.likeCount;
    final hitCount = model.detail.hitCount;
    return Column(children: [
      StatisticChart<MediaStatisticSource>(title: 'Likes (Total $likeCount)', objectId: model.mediaUri, source: MediaStatisticSource.LIKES, parameter: _parameter, service: MediaStatisticService.of(context)),
      StatisticChart<MediaStatisticSource>(title: 'Views (Total $hitCount)', objectId: model.mediaUri, source: MediaStatisticSource.VIEWS, parameter: _parameter, service: MediaStatisticService.of(context)),
      StatisticControlWidget(parameter: _parameter, onChanged: _onParameterChanged),
    ]);
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
            label: 'Details',
          ),
          new BottomNavigationBarItem(
            icon: Icon(Icons.create),
            label: 'Scribes',
          ),
          new BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Statistics',
          ),
        ]
    );
  }
}

class _MediaTabWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tabSelectionModel = Provider.of<_MediaTabSelectionModel>(context);
    if (tabSelectionModel.infoSelected) {
      return _MediaDetailPanel();
    } else if (tabSelectionModel.feedSelected) {
      return _MediaFeedPanel();
    } else if (tabSelectionModel.statisticSelected) {
      return _MediaStatisticPanel();
    } else {
      return null;
    }
  }
}

class _MediaTabSelectionModel with ChangeNotifier {
  static const infoIndex = 0;
  static const feedIndex = 1;
  static const statisticIndex = 2;

  int _currentDisplayIndex = infoIndex;

  int get currentDisplayIndex => _currentDisplayIndex;
  bool get feedSelected => _currentDisplayIndex == feedIndex;
  bool get infoSelected => _currentDisplayIndex == infoIndex;
  bool get statisticSelected => _currentDisplayIndex == statisticIndex;

  void tabSelected(int index) {
    _currentDisplayIndex = index;
    notifyListeners();
  }
}

class RemotePictureDisplay extends StatelessWidget {

  RemotePictureDisplay({@required this.media, this.preview = false});

  final MediaInfo media;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context);
    final constraints = preview ?
      BoxConstraints.tightFor(height: previewHeight.roundToDouble() / screen.devicePixelRatio) :
      BoxConstraints.expand(height: screen.size.height);
    return Container(
        color: Colors.black,
        constraints: constraints,
        child: FutureBuilder(
          future: _buildRequestHeader(context),
          builder: _buildImage,
      )
    );
  }

  Future<Map<String, String>> _buildRequestHeader(BuildContext context) {
    try {
      return MediaQueryService.of(context).buildImagePreviewHeader();
    } catch (e) {
      return null;
    }
  }

  Widget _buildImage(BuildContext context, AsyncSnapshot<Map<String, String>> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return _buildProgressIndicator(context, null);
    }
    final url = preview ? MediaQueryService.toPreviewUrl(media.mediaUri) : MediaQueryService.toFullUrl(media.mediaUri);
    return ClipRect(child: PhotoView(
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * (preview ? 2.0 : 8.0),
      initialScale: preview ? PhotoViewComputedScale.covered : PhotoViewComputedScale.contained,
      scaleStateCycle: preview ? (c) => c : defaultScaleStateCycle,
      tightMode: preview,
      onTapUp: preview && (!media.isVideo || media.hasVideoPreview) ? _onTap : null,
      imageProvider: NetworkImage(url, headers: snapshot.data),
      loadingBuilder: _loadingBuilder,
      errorBuilder: _errorBuilder,
      heroAttributes: PhotoViewHeroAttributes(tag: media.mediaUri),
    ));
  }

  void _onTap(BuildContext context, TapUpDetails details, PhotoViewControllerValue controllerValue) {
    Navigator.of(context).pushNamed(AppRoute.RemoteMediaDisplay, arguments: media);
  }

  Widget _loadingBuilder(BuildContext context, ImageChunkEvent loadingProgress) {
    if (loadingProgress == null) {
      return _buildProgressIndicator(context, null);
    }
    final progress = loadingProgress.expectedTotalBytes == null ? null :
    loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes;
    return _buildProgressIndicator(context, progress);
  }

  Widget _errorBuilder(BuildContext context, Object error, StackTrace stackTrace) {
    showSimpleDialog(context, 'Cannot load image', error);
    return _MediaDownloadFailedMessage();
  }

  Widget _buildProgressIndicator(BuildContext context, double progress) {
    return Center(
      child: CircularProgressIndicator(value: progress)
    );
  }
}

class _MediaDownloadFailedMessage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.broken_image, size: 100, color: Colors.grey),
          Text('Download failed', style: Theme.of(context).textTheme.headline6.copyWith(color: Colors.grey)),
          Text('Please retry later.', style: TextStyle(color: Colors.grey))
        ],
      ),
    );
  }
}

class RemoteVideoDisplay extends StatefulWidget {
  RemoteVideoDisplay({@required this.media, this.preview = false});

  final MediaInfo media;
  final bool preview;

  @override
  _RemoteVideoDisplayState createState() => _RemoteVideoDisplayState();
}

class _RemoteVideoDisplayState extends State<RemoteVideoDisplay> {

  VideoPlayerController _videoPlayerController;
  ChewieController _chewieController;
  StreamSubscription<VideoAction> _actionSubscription;

  @override
  void initState() {
    super.initState();
    _actionSubscription = EventBus.of(context).on<VideoAction>().listen((event) {
      _chewieController?.pause();
    });
    final url = MediaQueryService.toVideoUrl(widget.media.mediaUri);
    _videoPlayerController = VideoPlayerController.network(url);
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      fullScreenByDefault: !widget.preview,
      allowFullScreen: widget.preview,
      aspectRatio: 16 / 9,
      autoInitialize: true,
      autoPlay: !widget.preview,
      looping: false,
      errorBuilder: _buildVideoError,
    );
  }

  @override
  void dispose() {
    _actionSubscription?.cancel();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context);
    final constraints = widget.preview ?
    BoxConstraints.tightFor(height: previewHeight.roundToDouble() / screen.devicePixelRatio) :
    BoxConstraints.expand(height: screen.size.height);
    return Container(
        color: Colors.black,
        constraints: constraints,
        child: _buildVideo()
    );
  }

  Widget _buildVideoError(BuildContext context, String errorMessage) {
    showSimpleDialog(context, 'Cannot load video', errorMessage);
    return _MediaDownloadFailedMessage();
  }

  Widget _buildVideo() {
    return Chewie(controller: _chewieController);
  }
}

class RemoteMediaDisplayPage extends StatelessWidget {

  final MediaInfo mediaInfo;

  RemoteMediaDisplayPage(this.mediaInfo);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(mediaInfo.title, overflow: TextOverflow.ellipsis)),
      body: mediaInfo.hasVideoPreview
          ? RemoteVideoDisplay(media: mediaInfo)
          : RemotePictureDisplay(media: mediaInfo)
    );
  }
}
