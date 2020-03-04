import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/base.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/service/upload.dart';
import 'package:timeago_flutter/timeago_flutter.dart';

class UploadsPage extends StatefulWidget {
  @override
  _UploadsPageState createState() => _UploadsPageState();
}

enum _UploadErrorAction {
  RETRY,
  DELETE
}

class _UploadErrorItem {
  final _UploadErrorAction action;
  final UploadTask task;

  _UploadErrorItem(this.action, this.task);
}

class _UploadsPageState extends BasePageState<UploadsPage> {

  static const iconSize = 50.0;

  _UploadsPageState() : super(AppRoute.Uploads);

  @override
  Widget buildBody(BuildContext context) {
    return Consumer<UploadList>(
        builder: (context, uploads, _) => ChangeNotifierProvider.value(value: uploads,
          child: Consumer<UploadList>(
            builder: (context, value, _) => _buildList(context, value)
          )
        )
    );
  }

  Widget _buildList(BuildContext context, UploadList uploads) {
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

  Widget _buildTask(BuildContext context, UploadTask task) {
    return Card(
          key: ValueKey(task.id),
          margin: EdgeInsets.only(left: 10, right: 10, top: 10),
          child: ChangeNotifierProvider.value(value: task, child: _buildListTile(context, task))
      );
  }

  Widget _buildListTile(BuildContext context, UploadTask task) {
    return Consumer<UploadTask>(
      child: Hero(tag: task.file.path, child: Image.file(task.file, height: 70, width: 70, fit: BoxFit.cover)),
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

  Widget _buildSubtitle(BuildContext context, UploadTask task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Timeago(
          date: task.timestamp,
          builder: (_, value) => Text(value)
        ),
        Text(task.location.format())
      ],
    );
  }

  Widget _buildIcon(BuildContext context, UploadTask task) {
    if (task.status == UploadStatus.UPLOADING) {
      return CircularProgressIndicator(
        value: task.uploadProgress,
      );
    } else if (task.status == UploadStatus.CLAIMING) {
      return CircularProgressIndicator();
    } else if (task.status == UploadStatus.CREATED) {
      return Icon(Icons.navigate_next, size: iconSize);
    } else if (task.status == UploadStatus.ANNOTATED || task.status == UploadStatus.UPLOADED) {
      return Icon(Icons.refresh, size: iconSize);
    } else if (task.status == UploadStatus.UPLOAD_ERROR || task.status == UploadStatus.CLAIM_ERROR) {
      return PopupMenuButton(
        child: Icon(Icons.error, size: iconSize),
        itemBuilder: (context) => _buildUploadErrorMenu(context, task),
        onSelected: _onErrorItemSelection,
      );
    } else if (task.status == UploadStatus.CLAIMED) {
      return Icon(Icons.done, size: iconSize);
    } else {
      return null;
    }
  }

  List<PopupMenuItem<_UploadErrorItem>> _buildUploadErrorMenu(BuildContext context, UploadTask task) {
    return [
      PopupMenuItem(value: _UploadErrorItem(_UploadErrorAction.RETRY, task),
        child: ListTile(title: Text('Retry'), leading: Icon(Icons.refresh)),
      ),
      PopupMenuItem(value:  _UploadErrorItem(_UploadErrorAction.DELETE, task),
        child: ListTile(title: Text('Delete'), leading: Icon(Icons.delete)),
      )
    ];
  }

  void _onErrorItemSelection(_UploadErrorItem item) {
    if (item.action == _UploadErrorAction.DELETE) {
      showConfirmDialog(context, 'Delete Snype', 'Do you really want to delete this upload?', () => _onConfirmUploadDeletion(item.task));
    } else if (item.action == _UploadErrorAction.RETRY) {
      UploadService.current(context).manageTask(item.task);
    }
  }

  void _onConfirmUploadDeletion(UploadTask task) {
    UploadService.current(context).deleteTask(task);
  }

  void _onItemSelected(UploadTask task) {
    if (task.status == UploadStatus.CREATED) {
      Navigator.of(context).pushNamed(AppRoute.Annotate, arguments: task);
    } else if (task.status == UploadStatus.CLAIMED) {
      UploadService.current(context).deleteTask(task);
    } else {
      Navigator.of(context).pushNamed(AppRoute.PictureInfo, arguments: task);
    }
  }
}
