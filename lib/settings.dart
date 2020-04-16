

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/base.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/profile.dart';

class _SettingsTabSelectionModel with ChangeNotifier {
  static const identityIndex = 0;
  static const privacyIndex = 1;

  int _currentDisplayIndex = identityIndex;

  int get currentDisplayIndex => _currentDisplayIndex;
  bool get identitySelected => _currentDisplayIndex == identityIndex;
  bool get privacySelected => _currentDisplayIndex == privacyIndex;

  void tabSelected(int index) {
    _currentDisplayIndex = index;
    notifyListeners();
  }
}

class SettingsEditorPage extends StatefulWidget {
  @override
  _SettingsEditorPageState createState() => _SettingsEditorPageState();
}

class _SettingsEditorPageState extends BasePageState<SettingsEditorPage> {

  final _tabSelectionModel = _SettingsTabSelectionModel();

  _SettingsEditorPageState() : super(AppRoute.SettingsEditor);

  @override
  Widget buildBody(BuildContext context) {
    return ListView(
      children: <Widget>[
        ProfileHeader(tapCallback: _showProfile),
        _buildBottomPanel(context),
      ],
    );
  }

  void _showProfile() {
    Navigator.of(context).pushNamed(AppRoute.ProfileEditor);
  }

  Widget _buildBottomPanel(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _tabSelectionModel,
      child: _SettingsTabPanel(),
    );
  }

  @override
  AppBar buildAppBar() {
    return AppBar(title: Text('My settings'));
  }

  @override
  Widget buildNavBar(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _tabSelectionModel,
      child: _SettingsBottomNavigationBar(),
    );
  }
}

class _SettingsTabPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //final tabSelectionModel = Provider.of<_SettingsTabSelectionModel>(context);
    return SizedBox(height: 0, width: 0);
  }
}


class _SettingsBottomNavigationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tabSelectionModel = Provider.of<_SettingsTabSelectionModel>(context);
    return BottomNavigationBar(
        currentIndex: tabSelectionModel.currentDisplayIndex,
        onTap: tabSelectionModel.tabSelected,
        items: <BottomNavigationBarItem>[
          new BottomNavigationBarItem(
            icon: Icon(Icons.https),
            title: Text('Identity'),
          ),
          new BottomNavigationBarItem(
            icon: Icon(Icons.security),
            title: Text('Privacy'),
          )
        ]
    );
  }
}