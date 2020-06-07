

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/base.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/profile.dart';
import 'package:social_alert_app/service/authentication.dart';

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

class SettingsEditorPage extends StatefulWidget implements ScaffoldPage {

  final GlobalKey<ScaffoldState> scaffoldKey;

  SettingsEditorPage(this.scaffoldKey);

  @override
  _SettingsEditorPageState createState() => _SettingsEditorPageState(scaffoldKey);
}

class _SettingsEditorPageState extends BasePageState<SettingsEditorPage> {

  final _tabSelectionModel = _SettingsTabSelectionModel();

  _SettingsEditorPageState(GlobalKey<ScaffoldState> scaffoldKey) : super(scaffoldKey, AppRoute.SettingsEditor);

  @override
  Widget buildBody(BuildContext context) {
    return ListView(
      children: <Widget>[
        ProfileHeader(tapCallback: _showProfile, tapTooltip: 'Show profile',),
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
  Widget buildNavBar() {
    return ChangeNotifierProvider.value(
      value: _tabSelectionModel,
      child: _SettingsBottomNavigationBar(),
    );
  }
}

class _SettingsTabPanel extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final tabSelectionModel = Provider.of<_SettingsTabSelectionModel>(context);
    if (tabSelectionModel.identitySelected) {
      return _IdentityPanel();
    } else if (tabSelectionModel.privacySelected) {
      return SizedBox(height: 0, width: 0);
    } else {
      return null;
    }
  }
}

class _IdentityPanel extends StatelessWidget {
  static final creationFormat = DateFormat('d MMM yyyy');
  static final buttonColor = Color.fromARGB(255, 231, 40, 102);

  // TODO add last password change

  @override
  Widget build(BuildContext context) {
    UserProfile profile = Provider.of(context, listen: false);
    return Column(
      children: <Widget>[
        ListTile(leading: Icon(Icons.alternate_email),
            title: Text('Email address'),
            subtitle: _buildEmail(profile),
            dense: true),
        Divider(height: 5.0),
        ListTile(leading: Icon(Icons.event),
          title: Text('Registration date'),
          subtitle: _buildCreation(profile),
          dense: true),
        Divider(height: 5.0),
        _buildPasswordButton(context),
        _buildDeleteButton(context)
      ],
    );
  }

  Text _buildEmail(UserProfile profile) => Text(profile.email, style: TextStyle(fontSize: 16), overflow: TextOverflow.ellipsis);

  Text _buildCreation(UserProfile profile) => Text(creationFormat.format(profile.createdTimestamp), style: TextStyle(fontSize: 16), overflow: TextOverflow.ellipsis);

  Widget _buildDeleteButton(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child:  WideRoundedButton(text: 'Delete account',
          onPressed: () => Navigator.of(context).pushNamed(AppRoute.DeleteAccount),
          color: buttonColor)
    );
  }

  Widget _buildPasswordButton(BuildContext context) {
    return Container(
        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child:  WideRoundedButton(text: 'Change password',
            onPressed: () => Navigator.of(context).pushNamed(AppRoute.ChangePassword),
            color: Theme.of(context).primaryColor)
    );
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
