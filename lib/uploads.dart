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

class _UploadsPageState extends BasePageState<UploadsPage> {

  _UploadsPageState() : super(AppRoute.Uploads);

  @override
  Widget buildBody(BuildContext context) {
    return Consumer<UploadList>(
        builder: (context, value, child) => _buildList(context, value)
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
        Text('No upload in progress', style: Theme
            .of(context)
            .textTheme
            .headline6),
        Text('Content waiting to be uploaded'),
        Text('or enriched is displayed here.')
      ],
    ));
  }

  Widget _buildTask(BuildContext context, UploadTask task) {
    return ChangeNotifierProvider.value(value: task,
        child: Card(
          key: ValueKey(task.id),
          margin: EdgeInsets.only(left: 10, right: 10, top: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildListTile(task, context),
              //_buildButtonBar(),
            ],
          )
        ),
      );
  }

  ButtonBar _buildButtonBar() {
    return ButtonBar(
            children: <Widget>[
              FlatButton(
                child: const Text('Cancel'),
                onPressed: () { /* ... */ },
              ),
              FlatButton(
                child: const Text('Retry'),
                onPressed: () { /* ... */ },
              ),
            ],
          );
  }

  ListTile _buildListTile(UploadTask task, BuildContext context) {
    return ListTile(
            leading: Image.file(task.file, height: 70, width: 70, fit: BoxFit.cover),
            title: Text(task.title ?? 'TODO'),
            isThreeLine: true,
            subtitle: _buildSubtitle(context, task),
            trailing: Icon(Icons.navigate_next, size: 70),
            onTap: () => Navigator.of(context).pushNamed(AppRoute.Annotate, arguments: task),
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
}
