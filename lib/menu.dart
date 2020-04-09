import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/user.dart';
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
            _MenuItem(currentPage: currentPage, targetPage: AppRoute.Home, title: 'Home', icon: Icon(Icons.home)),
            _MenuItem(currentPage: currentPage, targetPage: AppRoute.ProfileEditor, title: 'My Profile', icon: Icon(Icons.person)),
            _MenuItem(currentPage: currentPage, targetPage: AppRoute.Network, title: 'My Network', icon: Icon(Icons.people)),
            _MenuItem(currentPage: currentPage, targetPage: AppRoute.UploadManager, title: 'My Uploads', icon: _buildUploadIcon()),
            _MenuItem(currentPage: currentPage, targetPage: null, title: 'My Statistics', icon: Icon(Icons.show_chart)),
            _MenuItem(currentPage: currentPage, targetPage: null, title: 'My Settings', icon: Icon(Icons.settings)),
            Divider(),
            _MenuItem(currentPage: currentPage, targetPage: AppRoute.Login, title: 'Sign Out', icon: Icon(Icons.power_settings_new)),
          ]
        )
      )
    );
  }

  Consumer<MediaUploadList> _buildUploadIcon() {
    return Consumer<MediaUploadList>(
            builder: _buildUploadBadge,
            child: Icon(Icons.cloud_upload),
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

class _MenuItem extends StatelessWidget {
  _MenuItem({
    this.currentPage,
    this.targetPage,
    this.title,
    this.icon
  }) : super(key: ValueKey(targetPage));

  final String currentPage;
  final String targetPage;
  final String title;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: currentPage != targetPage,
      selected: currentPage == targetPage,
      leading: icon,
      title: Text(title),
      onTap: () {
        if (targetPage == AppRoute.Login) {
          AuthService.current(context).signOut().then((_) => Navigator.pushReplacementNamed(context, AppRoute.Login));
        } else if (targetPage != null) {
          Navigator.popAndPushNamed(context, targetPage);
        } else {
          Navigator.pop(context);
        }
      },
    );
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
    if (location == null || location.locality == null) {
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
    return UserAvatar(radius: 100.0, imageUri: profile.imageUri, online: null);
  }
}
