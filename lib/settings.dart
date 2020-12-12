

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/base.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/profile.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/dataobjet.dart';
import 'package:social_alert_app/service/profileupdate.dart';

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
  final _scrollController = ScrollController();

  _SettingsEditorPageState(GlobalKey<ScaffoldState> scaffoldKey) : super(scaffoldKey, AppRoute.SettingsEditor);

  @override
  void initState() {
    super.initState();
    _tabSelectionModel.addListener(() => scrollToEnd(_scrollController));
  }

  @override
  Widget buildBody(BuildContext context) {
    return ListView(
      controller: _scrollController,
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
      return _PrivacyForm();
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
        _buildDeleteButton(context),
        SizedBox(height: 80)
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

class _PrivacyFormModel extends ChangeNotifier {
  bool _nameMasked;
  bool _genderMasked;
  bool _birthdateMasked;
  bool _locationBlurred;

  _PrivacyFormModel(UserProfile profile) {
    _nameMasked = profile.privacy.nameMasked;
    _genderMasked = profile.privacy.genderMasked;
    _birthdateMasked = profile.privacy.birthdateMasked;
    _locationBlurred = profile.privacy.location == LocationPrivacy.BLUR;
  }

  bool get nameMasked => _nameMasked;
  bool get genderMasked => _genderMasked;
  bool get birthdateMasked => _birthdateMasked;
  bool get locationBlurred => _locationBlurred;

  void setNameMasked(bool newValue) {
    _nameMasked = newValue;
    notifyListeners();
  }

  void setGenderMasked(bool newValue) {
    _genderMasked = newValue;
    notifyListeners();
  }

  void setBirthdateMasked(bool newValue) {
    _birthdateMasked = newValue;
    notifyListeners();
  }

  void setLocationBlurred(bool newValue) {
    _locationBlurred = newValue;
    notifyListeners();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _PrivacyFormModel &&
          runtimeType == other.runtimeType &&
          _nameMasked == other._nameMasked &&
          _genderMasked == other._genderMasked &&
          _birthdateMasked == other._birthdateMasked &&
          _locationBlurred == other._locationBlurred;

  @override
  int get hashCode => _nameMasked.hashCode ^ _genderMasked.hashCode ^ _birthdateMasked.hashCode ^ _locationBlurred.hashCode;

  UserPrivacy toPrivacySettings() => UserPrivacy(nameMasked: _nameMasked, genderMasked: _genderMasked, birthdateMasked: _birthdateMasked, location: _locationBlurred ? LocationPrivacy.BLUR : null);
}

class _PrivacyForm extends StatefulWidget {
  @override
  _PrivacyFormState createState() => _PrivacyFormState();
}

class _PrivacyFormState extends State<_PrivacyForm> {

  final _formKey = GlobalKey<FormState>();
  _PrivacyFormModel _formModel;
  _PrivacyFormModel _initialModel;

  @override
  void initState() {
    super.initState();
    _formModel = _PrivacyFormModel(context.read());
    _initialModel = _PrivacyFormModel(context.read());
  }

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        onWillPop: _allowPop,
        child: ChangeNotifierProvider.value(value: _formModel, child: _buildContent())
    );
  }

  Column _buildContent() {
    return Column(
          children: <Widget>[
            _HideNameSwitch(),
            _HideGenderSwitch(),
            _HideBirthdateSwitch(),
            _BlurLocationSwitch(),
            _PrivacySaveButton(onSave: _onSave, initialSettings: _initialModel),
            SizedBox(height: 80)
          ]
      );
  }


  Future<bool> _allowPop() async {
    if (_initialModel == _formModel) {
      return true;
    }
    return await showConfirmDialog(context, 'Unsaved changes', 'Do you want to leave without saving your changes?', confirmText: 'Yes', cancelText: 'No');
  }

  void _onSave() async {
    final form = _formKey.currentState;
    if (form != null && form.validate()) {
      form.save();
      try {
        final profile = await ProfileUpdateService.of(context).updatePrivacy(_formModel.toPrivacySettings());
        _initialModel = _PrivacyFormModel(profile);
        await Navigator.of(context).maybePop();
        showSuccessSnackBar(context, 'Your privacy settings have been saved');
      } catch (e) {
        showSimpleDialog(context, 'Update failed', e.toString());
      }
    }
  }
}

class _HideNameSwitch extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    _PrivacyFormModel model = context.watch();
    return SwitchListTile(
        title: Text('Hide real name'),
        secondary: Icon(Icons.person),
        value: model.nameMasked,
        onChanged: model.setNameMasked
    );
  }
}

class _HideGenderSwitch extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    _PrivacyFormModel model = context.watch();
    return SwitchListTile(
        title: Text('Hide gender'),
        secondary: Icon(Icons.wc),
        value: model.genderMasked,
        onChanged: model.setGenderMasked
    );
  }
}

class _HideBirthdateSwitch extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    _PrivacyFormModel model = context.watch();
    return SwitchListTile(
        title: Text('Hide birth date'),
        secondary: Icon(Icons.cake),
        value: model.birthdateMasked,
        onChanged: model.setBirthdateMasked
    );
  }
}

class _BlurLocationSwitch extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    _PrivacyFormModel model = context.watch();
    return SwitchListTile(
        title: Text('Blur GPS position'),
        secondary: Icon(Icons.gps_fixed),
        value: model.locationBlurred,
        onChanged: model.setLocationBlurred
    );
  }
}

class _PrivacySaveButton extends StatelessWidget {

  final VoidCallback onSave;
  final _PrivacyFormModel initialSettings;

  _PrivacySaveButton({this.onSave, this.initialSettings});

  @override
  Widget build(BuildContext context) {
    _PrivacyFormModel model = context.watch();
    return Container(
        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: WideRoundedButton(
            text: 'Save',
            onPressed: initialSettings != model ? onSave : null,
        )
    );
  }
}

class _SettingsBottomNavigationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    _SettingsTabSelectionModel tabSelectionModel = Provider.of(context);
    return BottomNavigationBar(
        currentIndex: tabSelectionModel.currentDisplayIndex,
        onTap: tabSelectionModel.tabSelected,
        items: <BottomNavigationBarItem>[
          new BottomNavigationBarItem(
            icon: Icon(Icons.https),
            label: 'Identity',
          ),
          new BottomNavigationBarItem(
            icon: Icon(Icons.security),
            label: 'Privacy',
          )
        ]
    );
  }
}
