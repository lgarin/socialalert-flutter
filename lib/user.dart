
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:social_alert_app/base.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/service/configuration.dart';

class UserAvatar extends StatelessWidget {
  final String imageUri;
  final bool online;
  final double radius;

  UserAvatar({this.imageUri, this.online, this.radius}) : super(key: ValueKey('$imageUri/$online'));

  @override
  Widget build(BuildContext context) {
    final format = radius < 60.0 ? 'small' : 'large';
    final url = imageUri != null ? '$baseServerUrl/file/avatar/$format/$imageUri' : null;
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        color: Colors.white,
        image: DecorationImage(
          image: url != null ? NetworkImage(url) : AssetImage('images/unknown_user.png'),
          fit: BoxFit.fill,
        ),
        borderRadius: BorderRadius.all(Radius.circular(radius / 2)),
        //boxShadow: [BoxShadow(color: online ? Theme.of(context).accentColor : Colors.grey, spreadRadius: 1.0, blurRadius: 1.0)],
        border: online != null ? Border.all(color: online ? Theme.of(context).accentColor : Colors.grey, width: 2) : null,
      ),
    );
  }
}

class ProfileEditorPage extends StatefulWidget {
  @override
  _ProfileEditorPageState createState() => _ProfileEditorPageState();
}

class _ProfileEditorPageState extends BasePageState<ProfileEditorPage> {
  _ProfileEditorPageState() : super(AppRoute.ProfileEditor);


  void _onSave() {

  }

  @override
  AppBar buildAppBar() {
    return AppBar(title: Text('Edit profile'),
        actions: <Widget>[
          IconButton(onPressed: _onSave, icon: Icon(Icons.done))
        ]
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return SizedBox(height: 0, width: 0,);
  }
}