import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/menu.dart';
import 'package:social_alert_app/service/geolocation.dart';
import 'package:social_alert_app/service/mediamodel.dart';
import 'package:social_alert_app/service/mediaupload.dart';

abstract class BasePageState<T extends StatefulWidget> extends State<T> {
  final appName = 'Snypix';

  final String pageName;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription<MediaUploadTask> uploadResultListener;

  BasePageState(this.pageName);

  @override
  void initState() {
    super.initState();
    uploadResultListener = MediaUploadService.current(context).uploadResultStream.listen(_showSnackBar);
  }

  @override
  void dispose() {
    uploadResultListener.cancel();
    super.dispose();
  }

  void _showSnackBar(MediaUploadTask task) {
    if (_scaffoldKey.currentState == null) {
      return;
    }

    if (task.title == null) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text('Title for media is missing', style: TextStyle(color: Colors.orange)),
          action: SnackBarAction(label: 'Edit', onPressed: () => Navigator.pushNamed(context, AppRoute.Annotate, arguments: task))
      ));
    } else if (task.status == MediaUploadStatus.UPLOADED) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('Upload of "${task.title}" has completed', style: TextStyle(color: Colors.green)),
      ));
    } else if (task.status == MediaUploadStatus.UPLOAD_ERROR || task.status == MediaUploadStatus.CLAIM_ERROR) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('Upload of "${task.title}" has failed', style: TextStyle(color: Colors.red)),
        action: SnackBarAction(label: 'Retry', onPressed: () => MediaUploadService.current(context).restartTask(task)),
      ));
    }
  }

  Future<MediaUploadList> _loadUploadList(BuildContext context) async {
    final uploadList = await MediaUploadService.current(context).currentUploads();
    for (final upload in uploadList) {
      if (upload.title == null) {
        _showSnackBar(upload);
      }
    }
    return uploadList;
  }

  @override
  Widget build(BuildContext context) {
    return FutureProvider<MediaUploadList>(
        create: _loadUploadList,
        lazy: false,
        child: Scaffold(
            key: _scaffoldKey,
            appBar: buildAppBar(),
            drawer: buildDrawer(),
            body: buildBody(context),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            floatingActionButton: buildCaptureButton(context),
            bottomNavigationBar: buildNavBar(context)
        )
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      title: Text(appName)
    );
  }

  Widget buildDrawer() => UserMenu(currentPage: pageName);

  FloatingActionButton buildCaptureButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _takePicture(context),
      tooltip: 'Take picture',
      backgroundColor: Theme.of(context).primaryColor,
      child: Icon(Icons.add_a_photo, color: Colors.white,),
    );
  }

  void _takePicture(BuildContext context) async {
    final position = GeoLocationService.current(context).readPosition(50.0);
    final image = await ImagePicker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final task = MediaUploadTask(file: image, type: MediaUploadType.PICTURE, position: await position);
      await MediaUploadService.current(context).saveTask(task);
      await Navigator.of(context).pushNamed(AppRoute.Annotate, arguments: task);
    }
  }

  Widget buildNavBar(BuildContext context) => null;

  Widget buildBody(BuildContext context);
}

abstract class BasePagingState<T extends StatefulWidget, E> extends State<T> {
  static final pageSize = 20;

  List<E> _data;
  PagingParameter _nextPage = PagingParameter(pageSize: pageSize, pageNumber: 0);
  RefreshController _refreshController = RefreshController(initialRefresh: true);

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
    final result = List<E>(a.length + b.length);
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
        child: _buildBody(context));
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