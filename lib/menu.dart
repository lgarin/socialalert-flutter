import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/common.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/geolocation.dart';
import 'package:social_alert_app/service/mediaupload.dart';

class UserMenu extends StatelessWidget {
  final String currentPage;

  UserMenu({this.currentPage});

  Widget build(BuildContext context) {
    return Theme(
        data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
        child: Drawer(
          child: Column(
            children: <Widget>[
              _Header(),
              Expanded(
                  child: _MenuBar(currentPage: currentPage)
              )
            ],
          ),
        ));
  }
}

class _MenuBar extends StatelessWidget {
  final String currentPage;

  const _MenuBar({Key key, this.currentPage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(color: Theme.of(context).primaryColor.withOpacity(0.9),
      child: ListTileTheme(
        style: ListTileStyle.drawer,
        iconColor: Colors.white,
        textColor: Colors.white,
        child: ListView(
          children: <Widget>[
            ListTile(
              enabled: currentPage != AppRoute.Home,
              selected: currentPage == AppRoute.Home,
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, AppRoute.Home);
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('My Profile'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              enabled: currentPage != AppRoute.Network,
              selected: currentPage == AppRoute.Network,
              leading: Icon(Icons.people),
              title: Text('My Network'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, AppRoute.Network);
              },
            ),
            ListTile(
              enabled: currentPage != AppRoute.Uploads,
              selected: currentPage == AppRoute.Uploads,
              leading: Consumer<MediaUploadList>(
                builder: _buildUploadBadge,
                child: Icon(Icons.cloud_upload),
              ),
              title: Text('My Uploads'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, AppRoute.Uploads);
              },
            ),
            ListTile(
              leading: Icon(Icons.show_chart),
              title: Text('My Statistics'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('My Settings'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ]
        )
      )
    );
  }

  Widget _buildUploadBadge(BuildContext context, MediaUploadList uploads, Widget child) {
    if (uploads != null) {
      return Badge(
        badgeColor: Colors.grey,
        badgeContent: Text(uploads.length.toString()),
        child: child,
      );
    }
    return child;
  }
}

class _Header extends StatelessWidget {
  Widget build(BuildContext context) {
    final profile = Provider.of<UserProfile>(context);
    final location = Provider.of<GeoLocation>(context);
    return Container(
        height: 240,
        color: Theme.of(context).primaryColorDark.withOpacity(0.9),
        child: profile != null ? _buildBody(context, profile, location) : LoadingCircle()
      );
  }

  Column _buildBody(BuildContext context, UserProfile profile, GeoLocation location) {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 50),
            _buildAvatar(context, profile),
            SizedBox(height: 10),
            _buildUsername(context, profile),
            _buildEmail(context, profile),
            SizedBox(height: 5),
            _buildLocation(context, location)
          ]);
  }

  Text _buildUsername(BuildContext context, UserProfile profile) {
    return Text(
      profile.username,
      style: Theme.of(context).textTheme.subtitle2
    );
  }

  Text _buildEmail(BuildContext context, UserProfile profile) {
    return Text(
        profile.email,
        style: TextStyle(color: Colors.white, fontSize: 12)
    );
  }

  Widget _buildLocation(BuildContext context, GeoLocation location) {
    if (location == null) {
      return Row();
    }
    return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.place, color: Colors.white, size: 14),
          Text(location.format(), style: TextStyle(color: Colors.white, fontSize: 12)),
        ]);
  }

  Widget _buildAvatar(BuildContext context, UserProfile profile) {
    return UserAvatar(radius: 100.0, imageUri: profile.imageUri, online: true);
  }
}
