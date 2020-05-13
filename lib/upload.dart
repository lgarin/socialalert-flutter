import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/base.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/service/mediaupload.dart';
import 'package:social_alert_app/service/videoservice.dart';
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
  static final itemMargin = EdgeInsets.only(left: 10, right: 10, top: 10);

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
    return Dismissible(
        key: ValueKey(task.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => _confirmDelete(),
        onDismissed: (_) => _onConfirmUploadDeletion(task),
        background: _buildDismissibleBackground(),
        child: Card(margin: itemMargin,
            child: ChangeNotifierProvider.value(value: task, child: _buildListTile(context, task))
          )
    );
  }

  Container _buildDismissibleBackground() {
    return Container(alignment: AlignmentDirectional.centerEnd,
        padding: EdgeInsets.all(10),
        margin: itemMargin,
        color: Colors.grey,
        child: Icon(Icons.delete)
    );
  }

  Widget _buildListTile(BuildContext context, MediaUploadTask task) {
    return Consumer<MediaUploadTask>(
      child: Hero(tag: task.id, child: _buildThumbnail(context, task)),
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

  Widget _buildThumbnail(BuildContext context, MediaUploadTask task) {
    if (!task.isVideo()) {
      return Image.file(task.file, height: 160, width: 90, fit: BoxFit.cover);
    }

    return FutureBuilder(
      key: ValueKey(task.id),
      future: VideoService.current(context).createThumbnail(task.file),
      builder: (context, snapshot) {
        if (snapshot.data == null) {
          return LoadingCircle();
        }
        return Image.file(snapshot.data, height: 160, width: 90, fit: BoxFit.cover);
      }
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
    } else if (task.hasError) {
      return PopupMenuButton(
        child: Icon(Icons.error, size: iconSize),
        itemBuilder: (context) => _buildUploadErrorMenu(context, task),
        onSelected: _onErrorItemSelection,
      );
    } else {
      return SizedBox(width: 0, height: 0);
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
      bool confirmed = await _confirmDelete();
      if (confirmed) {
        _onConfirmUploadDeletion(item.task);
      }
    } else if (item.action == _UploadErrorAction.RETRY) {
      MediaUploadService.current(context).restartTask(item.task);
    }
  }

  Future<bool> _confirmDelete() {
    return showConfirmDialog(context, 'Delete Snype', 'Do you really want to delete this upload?');
  }

  void _onConfirmUploadDeletion(MediaUploadTask task) {
    MediaUploadService.current(context).deleteTask(task);
  }

  void _onItemSelected(MediaUploadTask task) {
    if (task.status == MediaUploadStatus.CREATED) {
      Navigator.of(context).pushNamed(AppRoute.AnnotateMedia, arguments: task);
    } else {
      Navigator.of(context).pushNamed(AppRoute.LocalMediaInfo, arguments: task);
    }
  }
}
