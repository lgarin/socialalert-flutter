import 'package:flutter/material.dart';
import 'package:social_alert_app/profile.dart';

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
            leading: Icon(Icons.person, color: Colors.white),
            title: Text('My Profile', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.settings, color: Colors.white),
            title: Text('Settings', style: TextStyle(color: Colors.white)),
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
    final profile = UserProfile.current(context);
    return Container(
        height: 240,
        color: Theme.of(context).primaryColorDark.withOpacity(0.9),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 50),
              _buildAvatar(context, profile),
              SizedBox(height: 10),
              _buildUsername(context, profile),
              SizedBox(height: 5),
              _buildLocation(context, profile)
            ]));
  }

  Text _buildUsername(BuildContext context, UserProfile profile) {
    return Text(
      profile.username + " (" + profile.email + ")",
      style: Theme.of(context).textTheme.subtitle
    );
  }

  Row _buildLocation(BuildContext context, UserProfile profile) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.place, color: Colors.white, size: 14),
          Text(profile.country ?? '???', style: TextStyle(color: Colors.white, fontSize: 12)),
        ]);
  }

  Container _buildAvatar(BuildContext context, UserProfile profile) {
    return Container(
      width: 100.0,
      height: 100.0,
      decoration: BoxDecoration(
        color: Theme.of(context).accentColor,
        image: DecorationImage(
          image: profile.picture,
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.all(Radius.circular(50.0)),
        border: Border.all(color: Colors.white, width: 4.0),
      ),
    );
  }
}
