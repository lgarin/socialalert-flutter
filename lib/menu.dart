import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/profile.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/mediaupload.dart';

class UserMenu extends StatelessWidget {
  final String currentPage;

  UserMenu({this.currentPage});

  Widget build(BuildContext context) {
    return Theme(
        data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
        child: SafeArea(child: _buildDrawer(context))
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
        child: Column(
          children: <Widget>[
            Container(height: 10.0, color: Theme.of(context).primaryColorDark.withOpacity(0.9),),
            ProfileHeader(tapCallback: () => Navigator.of(context).popAndPushNamed(AppRoute.ProfileEditor), tapTooltip: 'Edit profile'),
            Expanded(
                child: _MenuBar(currentPage: currentPage)
            )
          ],
        ),
      );
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
            _MenuItem(currentPage: currentPage, targetPage: AppRoute.ProfileViewer, title: 'My Profile', icon: Icon(Icons.person)),
            _MenuItem(currentPage: currentPage, targetPage: AppRoute.UserNetwork, title: 'My Network', icon: Icon(Icons.people)),
            _MenuItem(currentPage: currentPage, targetPage: AppRoute.UploadManager, title: 'My Uploads', icon: _buildUploadIcon()),
            _MenuItem(currentPage: currentPage, targetPage: null, title: 'My Statistics', icon: Icon(Icons.show_chart)),
            _MenuItem(currentPage: currentPage, targetPage: AppRoute.SettingsEditor, title: 'My Settings', icon: Icon(Icons.settings)),
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
    if (uploads != null && uploads.length > 0) {
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
      enabled: targetPage != null && currentPage != targetPage,
      selected: currentPage == targetPage,
      leading: icon,
      title: Text(title),
      onTap: () {
        if (targetPage == AppRoute.Login) {
          Authentication.of(context).signOut().then((_) => Navigator.of(context).pushReplacementNamed(AppRoute.Login));
        } else if (targetPage != null) {
          Navigator.of(context).popAndPushNamed(targetPage);
        } else {
          Navigator.of(context).pop();
        }
      },
    );
  }
}

