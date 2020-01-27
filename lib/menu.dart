import 'package:flutter/material.dart';
import 'package:social_alert_app/session.dart';

class Menu extends StatelessWidget {
  Widget build(BuildContext context) {
    return Theme(
        data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
        child: Drawer(
          child: Column(
            children: <Widget>[
              _Header(),
              Expanded(
                  child: _MenuBar()
              )
            ],
          ),
        ));
  }
}

class _MenuBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(color: Theme.of(context).primaryColor.withOpacity(0.9),
      child: ListView(
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.perm_identity),
            title: Text('My Profile'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              Navigator.pop(context);
            },
          )
        ]
      )
    );
  }
}

class _Header extends StatelessWidget {
  Widget build(BuildContext context) {
    final username = UserSession.current(context).username;
    final location = 'Switzerland';
    final imageUrl = null;
    return Container(
        height: 240,
        color: Theme.of(context).primaryColorDark.withOpacity(0.9),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 50),
              _buildAvatar(context, imageUrl),
              SizedBox(height: 10),
              _buildUsername(context, username),
              SizedBox(height: 5),
              _buildLocation(context, location)
            ]));
  }

  Text _buildUsername(BuildContext context, String username) {
    return Text(
              username,
              style: Theme.of(context).textTheme.subtitle,
            );
  }

  Row _buildLocation(BuildContext context, String location) {
    return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.place),
                  Text(location, style: Theme.of(context).textTheme.body2),
                ]);
  }

  Container _buildAvatar(BuildContext context, String imageUrl) {
    return Container(
      width: 100.0,
      height: 100.0,
      decoration: BoxDecoration(
        color: Theme.of(context).accentColor,
        image: DecorationImage(
          image: imageUrl != null
              ? NetworkImage(imageUrl)
              : AssetImage('images/unknown_user.png'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.all(Radius.circular(50.0)),
        border: Border.all(color: Colors.white, width: 4.0),
      ),
    );
  }
}
