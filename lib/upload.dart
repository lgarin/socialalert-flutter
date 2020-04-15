import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/base.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/service/mediaupload.dart';
import 'package:timeago_flutter/timeago_flutter.dart';

class UploadManagerPage extends StatefulWidget {

  @override
  _UploadManagerPageState createState() => _UploadManagerPageState();
}

enum _UploadErrorAction {
  RETRY,
  DELETE
}

class _UploadErrorItem {
  final _UploadErrorAction action;
  final MediaUploadTask task;

  _UploadErrorItem(this.action, this.task);
}

class _UploadManagerPageState extends BasePageState<UploadManagerPage> {

  static const iconSize = 50.0;

  _UploadManagerPageState() : super(AppRoute.UploadManager);

  @override
  AppBar buildAppBar() {
    if (Navigator.canPop(context)) {
      return AppBar(title: Text('My Uploads'));
    }
    return super.buildAppBar();
  }

  @override
  Widget buildDrawer() => null;

  @override
  Widget buildBody(BuildContext context) {
    return Consumer<MediaUploadList>(
        builder: (context, uploads, _) => ChangeNotifierProvider.value(value: uploads,
          child: Consumer<MediaUploadList>(
            builder: (context, value, _) => _buildList(context, value)
          )
        )
    );
  }

  Widget _buildList(BuildContext context, MediaUploadList uploads) {
    if (uploads == null) {
      return LoadingCircle();
    } else if (uploads.isEmpty) {
      return _buildEmpty(context);
    }
    return ListView.builder(
        itemCount: uploads.length,
        itemBuilder: (context, index) => _buildTask(context, uploads.elementAt(index))
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Icon(Icons.cloud_upload, size: 100, color: Colors.grey),
        Text('No upload in progress', style: Theme.of(context).textTheme.headline6),
        Text('Content waiting to be uploaded'),
        Text('or enriched is displayed here.')
      ],
    ));
  }

  Widget _buildTask(BuildContext context, MediaUploadTask task) {
    return Card(
          key: ValueKey(task.id),
          margin: EdgeInsets.only(left: 10, right: 10, top: 10),
          child: ChangeNotifierProvider.value(value: task, child: _buildListTile(context, task))
      );
  }

  Widget _buildListTile(BuildContext context, MediaUploadTask task) {
    return Consumer<MediaUploadTask>(
      child: Hero(tag: task.id, child: Image.file(task.file, height: 70, width: 70, fit: BoxFit.cover)),
      builder: (context, task, child) => ListTile(
            leading: child,
            title: Text(task.title ?? '?'),
            isThreeLine: true,
            subtitle: _buildSubtitle(context, task),
            trailing: _buildIcon(context, task),
            onTap: () => _onItemSelected(task),
          )
    );
  }

  Widget _buildSubtitle(BuildContext context, MediaUploadTask task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Timeago(
          date: task.timestamp,
          builder: (_, value) => Text(value)
        ),
        Text(task.location.formatShort())
      ],
    );
  }

  Widget _buildIcon(BuildContext context, MediaUploadTask task) {
    if (task.status == MediaUploadStatus.UPLOADING) {
      return CircularProgressIndicator(
        value: task.uploadProgress,
      );
    } else if (task.status == MediaUploadStatus.LOCATING || task.status == MediaUploadStatus.CLAIMING) {
      return CircularProgressIndicator();
    } else if (task.status == MediaUploadStatus.CREATED) {
      return Icon(Icons.navigate_next, size: iconSize);
    } else if (task.status == MediaUploadStatus.ANNOTATED || task.status == MediaUploadStatus.LOCATED || task.status == MediaUploadStatus.UPLOADED) {
      return SizedBox(width: 0, height: 0);
    } else if (task.status == MediaUploadStatus.UPLOAD_ERROR || task.status == MediaUploadStatus.LOCATE_ERROR || task.status == MediaUploadStatus.CLAIM_ERROR) {
      return PopupMenuButton(
        child: Icon(Icons.error, size: iconSize),
        itemBuilder: (context) => _buildUploadErrorMenu(context, task),
        onSelected: _onErrorItemSelection,
      );
    } else if (task.status == MediaUploadStatus.CLAIMED) {
      return Icon(Icons.done, size: iconSize);
    } else {
      return null;
    }
  }

  List<PopupMenuItem<_UploadErrorItem>> _buildUploadErrorMenu(BuildContext context, MediaUploadTask task) {
    return [
      PopupMenuItem(value: _UploadErrorItem(_UploadErrorAction.RETRY, task),
        child: ListTile(title: Text('Retry'), leading: Icon(Icons.refresh)),
      ),
      PopupMenuItem(value:  _UploadErrorItem(_UploadErrorAction.DELETE, task),
        child: ListTile(title: Text('Delete'), leading: Icon(Icons.delete)),
      )
    ];
  }

  void _onErrorItemSelection(_UploadErrorItem item) async {
    if (item.action == _UploadErrorAction.DELETE) {
      final confirmed = await showConfirmDialog(context, 'Delete Snype', 'Do you really want to delete this upload?');
      if (confirmed) {
        _onConfirmUploadDeletion(item.task);
      }
    } else if (item.action == _UploadErrorAction.RETRY) {
      MediaUploadService.current(context).restartTask(item.task);
    }
  }

  void _onConfirmUploadDeletion(MediaUploadTask task) {
    MediaUploadService.current(context).deleteTask(task);
  }

  void _onItemSelected(MediaUploadTask task) {
    if (task.status == MediaUploadStatus.CREATED) {
      Navigator.of(context).pushNamed(AppRoute.AnnotatePicture, arguments: task);
    } else if (task.status == MediaUploadStatus.CLAIMED) {
      MediaUploadService.current(context).deleteTask(task);
    } else {
      Navigator.of(context).pushNamed(AppRoute.LocalPictureInfo, arguments: task);
    }
  }
}
