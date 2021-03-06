import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/menu.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/dataobjet.dart';
import 'package:social_alert_app/service/eventbus.dart';
import 'package:social_alert_app/service/mediaupload.dart';
import 'package:social_alert_app/service/pagemanager.dart';
import 'package:social_alert_app/service/permission.dart';
import 'package:social_alert_app/service/profileupdate.dart';

class _NotificationHook extends StatefulWidget {
  final String pageName;
  final Widget child;

  _NotificationHook({@required this.pageName, @required this.child});

  @override
  _NotificationHookState createState() => _NotificationHookState();
}

class _NotificationEvent {
  final String message;
  final Color color;
  final SnackBarAction action;
  final DateTime timestamp;

  _NotificationEvent(this.message, this.color, this.action, this.timestamp);
}

class _NotificationHookState extends State<_NotificationHook> {

  static final repeatMessageDelay = Duration(seconds: 2);
  static final oldUploadAge = Duration(minutes: 2);

  StreamSubscription<PageEvent> _pageListener;
  StreamSubscription<MediaUploadTask> _uploadResultListener;
  StreamSubscription<UserProfile> _userProfileListener;
  final _previousEvents = <_NotificationEvent>[];

  @override
  void initState() {
    super.initState();
    _uploadResultListener = MediaUploadService.of(context).uploadResultStream.listen(_showUploadSnackBar);
    _userProfileListener = ProfileUpdateService.of(context).profileStream.listen(_showUserProfileSnackBar);
    _pageListener = EventBus.of(context).on<PageEvent>().listen(_onPageEvent);
  }

  void _onPageEvent(PageEvent event) {
    if (event.type != PageEventType.SHOW || event.pageName != widget.pageName) {
      return;
    }

    final recentTimestamp = DateTime.now().subtract(repeatMessageDelay);
    _showRecentSnackBars(recentTimestamp);

    UserProfile userProfile = Provider.of(context, listen: false);
    _showUserProfileSnackBar(userProfile);

    MediaUploadList uploadList = Provider.of(context, listen: false);
    _showAllUploadSnackBars(uploadList);
  }

  void _showRecentSnackBars(DateTime minTimestamp) {
    _previousEvents.where((event) => event.timestamp.isAfter(minTimestamp)).forEach((element) => _showSnackBar(element.message, element.color, element.action));
    _previousEvents.clear();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    _pageListener.cancel();
    _uploadResultListener.cancel();
    _userProfileListener.cancel();
    super.dispose();
  }

  void _showSnackBar(String message, Color color, SnackBarAction action) {

    if (PageManager.of(context).currentPageName != widget.pageName) {
      _previousEvents.add(_NotificationEvent(message, color, action, DateTime.now()));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message, style: TextStyle(color: color)), action: action));
  }

  void showSuccessSnackBar(String message, {SnackBarAction action}) {
    _showSnackBar(message, Colors.green, action);
  }

  void showWarningSnackBar(String message, {SnackBarAction action}) {
    _showSnackBar(message, Colors.orange, action);
  }

  void showErrorSnackBar(String message, {SnackBarAction action}) {
    _showSnackBar(message, Colors.red, action);
  }

  void _showUploadSnackBar(MediaUploadTask task) {
    if (task.isDeleted) {
      showSuccessSnackBar('New Snype has been deleted');
    } else if (task.isTitleMissing) {
      showWarningSnackBar('Title for new Snype is missing',
          action: SnackBarAction(label: 'Edit', onPressed: () => _onEditUpload(task))
      );
    } else if (task.isNew) {
      showSuccessSnackBar('New Snype has been saved localy');
    } else if (task.isCompleted) {
      showSuccessSnackBar('Upload of "${task.title}" has completed');
    } else if (task.hasError) {
      showErrorSnackBar('Upload of "${task.title}" has failed',
        action: SnackBarAction(label: 'Retry', onPressed: () => _onRestartUpload(task)),
      );
    }
  }

  void _onEditUpload(MediaUploadTask task) {
    if (task.isNew) {
      Navigator.of(context).pushNamed(AppRoute.AnnotateMedia, arguments: task);
    }
  }

  void _onRestartUpload(MediaUploadTask task) {
    if (task.hasError) {
      MediaUploadService.of(context).restartTask(task);
    }
  }

  void _showUserProfileSnackBar(UserProfile profile) {
    if (profile == null) {
      return;
    }

    if (!profile.anonym && profile.incomplete && PageManager.of(context).currentPageName != AppRoute.ProfileEditor) {
      showWarningSnackBar('Your profile is missing some information',
          action: SnackBarAction(label: 'Edit', onPressed: _onEditProfile));
    }
  }

  void _onEditProfile() {
    Navigator.of(context).pushNamed(AppRoute.ProfileEditor);
  }

  void _showAllUploadSnackBars(MediaUploadList uploadList) {
    if (uploadList == null) {
      return;
    }

    final oldUploadTimestamp = DateTime.now().subtract(oldUploadAge);
    for (final upload in uploadList) {
      if (upload.isTitleMissing && upload.timestamp.isBefore(oldUploadTimestamp)) {
        _showUploadSnackBar(upload);
      }
    }
  }
}

abstract class BasePageState<T extends StatefulWidget> extends State<T> {
  final appName = 'Snypix';
  final String pageName;

  BasePageState(this.pageName);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          appBar: buildAppBar(),
          drawer: buildDrawer(),
          body: _NotificationHook(pageName: pageName, child: Builder(builder: buildBody)),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: buildCaptureButton(),
          bottomNavigationBar: buildNavBar()
      );
  }

  AppBar buildAppBar() {
    return AppBar(
      title: Text(appName)
    );
  }

  Widget buildDrawer() {
    if (Navigator.of(context).canPop()) {
      return null;
    }
    return UserMenu(currentPage: pageName);
  }

  FloatingActionButton buildCaptureButton() {
    return FloatingActionButton(
      onPressed: () => _captureMedia(context),
      tooltip: 'Capture a Snype',
      backgroundColor: Theme.of(context).primaryColor,
      child: Icon(Icons.add_a_photo, color: Colors.white,),
    );
  }

  void _captureMedia(BuildContext context) async {
    final requestedPermissions = [PermissionGroup.camera, PermissionGroup.microphone, PermissionGroup.locationWhenInUse];
    if (await PermissionManager.of(context).allows(requestedPermissions)) {
      Navigator.of(context).pushNamed(AppRoute.CaptureMedia);
    }
  }

  Widget buildNavBar() => null;

  Widget buildBody(BuildContext context);
}

abstract class BasePagingState<T extends StatefulWidget, E> extends State<T> {
  static final pageSize = 20;

  List<E> _data;
  var _nextPage = PagingParameter(pageSize: pageSize, pageNumber: 0);
  final _refreshController = RefreshController(initialRefresh: true);

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<ResultPage<E>> loadNextPage(PagingParameter parameter);

  void _onRefresh() async{
    try {
      _nextPage = PagingParameter(pageSize: pageSize, pageNumber: 0);
      final result = await loadNextPage(_nextPage);
      _data = null;
      _setData(result);
      _refreshController.refreshCompleted();
      if (_nextPage == null) {
        _refreshController.loadNoData();
      } else {
        _refreshController.loadComplete();
      }
    } catch (e) {
      _refreshController.refreshFailed();
      await showSimpleDialog(context, "Refresh failed", e.toString());
    }
    _refreshWidget();
  }

  void _onLoading() async {
    try {
      final result = await loadNextPage(_nextPage);
      _setData(result);
      if (_nextPage == null) {
        _refreshController.loadNoData();
      } else {
        _refreshController.loadComplete();
      }
    } catch (e) {
      _refreshController.loadFailed();
      await showSimpleDialog(context, "Load failed", e.toString());
    }
    _refreshWidget();
  }

  List<E> _createNewList(List<E> a, List<E> b) {
    final result = List<E>.filled(a.length + b.length, null);
    List.copyRange(result, 0, a);
    List.copyRange(result, a.length, b);
    return result;
  }

  void replaceItem(bool Function(E) test, E newValue)  {
    final index = _data.indexWhere(test);
    if (index != null) {
      setState(() {
        _data[index] = newValue;
      });
    }
  }

  void _setData(ResultPage<E> result) {
    if (_data == null) {
      _data = result.content;
    } else {
      _data = _createNewList(_data, result.content);
    }
    _nextPage = result.nextPage;
  }

  void _refreshWidget() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
        enablePullDown: true,
        enablePullUp: true,
        controller: _refreshController,
        onLoading: _onLoading,
        onRefresh: _onRefresh,
        header: WaterDropMaterialHeader(),
        footer: CustomFooter(
            loadStyle: LoadStyle.ShowWhenLoading,
            builder: _buildFooter
        ),
        child: _buildBody(context)
    );
  }

  Widget _buildFooter(BuildContext context, LoadStatus mode) {
    if (mode == LoadStatus.loading) {
      return Align(
          alignment: Alignment.bottomCenter,
          child: RefreshProgressIndicator(
            backgroundColor: Theme.of(context).primaryColor,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ));
    }
    return SizedBox(height: 0, width: 0,);
  }

  Widget _buildBody(BuildContext context) {
    if (_data == null) {
      return SizedBox(height: 0, width: 0,);
    }
    return buildContent(context, _data);
  }

  Widget buildContent(BuildContext context, List<E> data);
}