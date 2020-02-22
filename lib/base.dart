import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/menu.dart';
import 'package:social_alert_app/service/geolocation.dart';
import 'package:social_alert_app/service/upload.dart';

abstract class BasePageState<T extends StatefulWidget> extends State<T> {
  final String pageName;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  BasePageState(this.pageName);

  @override
  void initState() {
    super.initState();
    UploadService.current(context).uploadResultStream.listen(_showSnackBar);
  }

  void _showSnackBar(UploadTask task) {
    if (_scaffoldKey == null) {
      return;
    }

    if (task.title == null) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text('Title for media is missing', style: TextStyle(color: Colors.orange)),
          action: SnackBarAction(label: 'Edit', onPressed: () => Navigator.pushNamed(context, AppRoute.Annotate, arguments: task))
      ));
    } else if (task.status == UploadStatus.UPLOADED) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('Upload of "${task.title}" has completed', style: TextStyle(color: Colors.green)),
      ));
    } else if (task.status == UploadStatus.UPLOAD_ERROR) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('Upload of "${task.title}" has failed', style: TextStyle(color: Colors.red)),
        action: SnackBarAction(label: 'Retry', onPressed: () => UploadService.current(context).manageTask(task)),
      ));
    }
  }

  Future<UploadList> _loadUploadList(BuildContext context) async {
    final uploadList = await UploadService.current(context).currentUploads();
    for (final upload in uploadList) {
      if (upload.title == null) {
        _showSnackBar(upload);
      }
    }
    return uploadList;
  }

  @override
  Widget build(BuildContext context) {
    return FutureProvider<UploadList>(
        create: _loadUploadList,
        lazy: false,
        child: Scaffold(
            key: _scaffoldKey,
            appBar: _buildAppBar(),
            drawer: UserMenu(currentPage: pageName),
            body: buildBody(context),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            floatingActionButton: _buildCaptureButton(context),
            bottomNavigationBar: buildNavBar(context)
        )
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text("Snypix"),
      actions: <Widget>[
        Icon(Icons.place),
        SizedBox(width: 20),
        Icon(Icons.search),
        SizedBox(width: 20),
        Icon(Icons.more_vert),
        SizedBox(width: 10),
      ],
    );
  }

  FloatingActionButton _buildCaptureButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _takePicture(context),
      tooltip: 'Take picture',
      backgroundColor: Theme.of(context).primaryColor,
      child: Icon(Icons.add_a_photo, color: Colors.white,),
    );
  }

  void _takePicture(BuildContext context) async {
    final position = GeoLocationService.current(context).readPosition();
    final image = await ImagePicker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final task = UploadTask(file: image, type: UploadType.PICTURE, position: await position);
      await UploadService.current(context).manageTask(task);
      await Navigator.of(context).pushNamed(AppRoute.Annotate, arguments: task);
    }
  }

  BottomNavigationBar buildNavBar(BuildContext context) {
    return null;
  }

  Widget buildBody(BuildContext context);
}