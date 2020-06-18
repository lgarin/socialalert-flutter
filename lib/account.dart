import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/base.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/configuration.dart';
import 'package:social_alert_app/service/useraccount.dart';

class _PasswordModel {
  bool _showPassword = false;
  String _password = '';

  _PasswordModel();

  String get password => _password;

  bool get showPassword => _showPassword;
  void switchPasswordVisibility() => _showPassword = !_showPassword;

  void setPassword(String password) => _password = password;

  bool hasInput() => hasPasswordInput();

  bool hasPasswordInput() => _password != '';
}

class _NewPasswordModel extends _PasswordModel {
  String _newPassword = '';

  _NewPasswordModel();

  String get newPassword => _newPassword;

  void setNewPassword(String newPassword) => _newPassword = newPassword;

  bool hasInput() => hasPasswordInput() || hasNewPasswordInput();

  bool hasNewPasswordInput() => _newPassword != '';
}

class _PasswordWidget extends StatelessWidget {
  _PasswordWidget({
    @required this.label,
    @required this.model,
    @required this.onSwitchVisibility
  });

  final String label;
  final _PasswordModel model;
  final VoidCallback onSwitchVisibility;

  @override
  Widget build(BuildContext context) {
    return WideRoundedField(
        child: TextFormField(
          autofocus: !model.hasPasswordInput(),
          initialValue: model.password,
          onSaved: model.setPassword,
          obscureText: !model.showPassword,
          decoration: InputDecoration(
              hintText: label,
              icon: Icon(Icons.lock_open),
              suffixIcon: IconButton(
                  icon: Icon(model.showPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: onSwitchVisibility
              )
          ),
          validator: RequiredValidator(errorText: "$label required"),
        )
    );
  }
}

class _NewPasswordWidget extends StatelessWidget {
  _NewPasswordWidget({
    @required this.label,
    @required this.model,
    @required this.onSwitchVisibility
  });

  final String label;
  final _NewPasswordModel model;
  final VoidCallback onSwitchVisibility;

  @override
  Widget build(BuildContext context) {
    return WideRoundedField(
        child: TextFormField(
          autofocus: model.hasPasswordInput() && !model.hasNewPasswordInput(),
          initialValue: model.newPassword,
          onSaved: model.setNewPassword,
          obscureText: !model.showPassword,
          decoration: InputDecoration(
              hintText: label,
              icon: Icon(Icons.lock_open),
              suffixIcon: IconButton(
                  icon: Icon(model.showPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: onSwitchVisibility
              )
          ),
          validator: MinLengthValidator(minPasswordLength, errorText: "At least $minPasswordLength characters required"),
        )
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  static const color = Color.fromARGB(255, 231, 40, 102);

  _ConfirmButton({
    @required this.label,
    @required this.onConfirm
  });

  final String label;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return WideRoundedButton(
        text: label,
        onPressed: onConfirm,
        color: color
    );
  }
}

class _CancelButton extends StatelessWidget {
  static const color = Color.fromARGB(255, 32, 47, 128);
  static const label = 'Cancel';

  @override
  Widget build(BuildContext context) {
    return WideRoundedButton(
      text: label,
      onPressed: () => Navigator.of(context).maybePop(),
      color: color,
    );
  }
}

class _HintText extends StatelessWidget {

  final IconData icon;
  final String message;

  _HintText({Key key, this.icon, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon),
        SizedBox(width: 10.0),
        Flexible(child: Text(message)),
      ]);
  }
}

class _DeleteAccountForm extends StatefulWidget {
  @override
  _DeleteAccountFormState createState() => _DeleteAccountFormState();
}

class _DeleteAccountFormState extends State<_DeleteAccountForm> {
  static const spacing = 10.0;

  final _formKey = GlobalKey<FormState>();
  final _model = _PasswordModel();

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        autovalidate: _model.hasInput(),
        child: _buildContent()
    );
  }

  Column _buildContent() {
    return Column(
      children: <Widget>[
        _HintText(icon: Icons.warning,
          message:'Your account will be permanently deleted. You must confirm this action by entering your current password.'
        ),
        SizedBox(height: spacing),
        _PasswordWidget(label: 'Password', model: _model, onSwitchVisibility: _onSwitchPasswordVisibility),
        SizedBox(height: spacing),
        _ConfirmButton(label: 'Delete account', onConfirm: _onConfirm),
        SizedBox(height: spacing),
        _CancelButton()
      ],
    );
  }

  void _onSwitchPasswordVisibility() {
    setState(() {
      _model.switchPasswordVisibility();
    });
  }

  void _onConfirm() {
    final form = _formKey.currentState;
    if (form != null && form.validate()) {
      form.save();
      _deleteAccount(_model.password);
    }
  }

  void _deleteAccount(String password) async {
    try {
      UserProfile profile = Provider.of(context, listen: false);
      await UserAccountService.of(context).deleteAccount(profile.username, password);
      await Authentication.of(context).signOut();
      final navigator = Navigator.of(context);
      while (navigator.canPop()) {
        await navigator.maybePop();
      }
      navigator.pushReplacementNamed(AppRoute.Login);
      // TODO pushReplacement never completes and consequently a snackbar cannot be shown in this case
    } catch (e) {
      showSimpleDialog(context, 'Deletion failure', e.toString());
    }
  }
}

class _ChangePasswordForm extends StatefulWidget {
  @override
  _ChangePasswordFormState createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<_ChangePasswordForm> {
  static const spacing = 10.0;

  final _formKey = GlobalKey<FormState>();
  final _model = _NewPasswordModel();

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        autovalidate: _model.hasInput(),
        child: _buildContent()
    );
  }

  Column _buildContent() {
    return Column(
      children: <Widget>[
        _HintText(icon: Icons.info,
          message: 'You must confirm the password change by entering first your current password.'
        ),
        SizedBox(height: spacing),
        _PasswordWidget(label: 'Current Password', model: _model, onSwitchVisibility: _onSwitchPasswordVisibility),
        SizedBox(height: spacing),
        _NewPasswordWidget(label: 'New Password', model: _model, onSwitchVisibility: _onSwitchPasswordVisibility),
        SizedBox(height: spacing),
        _ConfirmButton(label: 'Change password', onConfirm: _onConfirm),
        SizedBox(height: spacing),
        _CancelButton()
      ],
    );
  }

  void _onSwitchPasswordVisibility() {
    setState(() {
      _model.switchPasswordVisibility();
    });
  }

  void _onConfirm() {
    final form = _formKey.currentState;
    if (form != null && form.validate()) {
      form.save();
      _changePassword(_model.password, _model.newPassword);
    }
  }

  void _changePassword(String oldPassword, String newPassword) async {
    try {
      UserProfile profile = Provider.of(context, listen: false);
      await UserAccountService.of(context).changePassword(profile.username, oldPassword, newPassword);
      await Navigator.of(context).maybePop();
      showSuccessSnackBar(context, 'Your password has been changed');
    } catch (e) {
      showSimpleDialog(context, 'Password change failure', e.toString());
    }
  }
}

abstract class BaseAccountPage extends StatelessWidget implements ScaffoldPage {
  static const margin = 40.0;
  static const backgroundColor = Color.fromARGB(255, 240, 240, 240);
  final GlobalKey<ScaffoldState> scaffoldKey;
  final String title;

  BaseAccountPage(this.scaffoldKey, this.title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: scaffoldKey,
        backgroundColor: backgroundColor,
        appBar: AppBar(title: Text(title, overflow: TextOverflow.ellipsis)),
        body: _buildContent(context)
    );
  }

  ListView _buildContent(BuildContext context) {
    return ListView(
        children: <Widget>[
          Container(
            margin: EdgeInsets.all(margin),
            child: _buildBody(context),
          ),
        ]);
  }

  Widget _buildBody(BuildContext context);
}

class DeleteAccountPage extends BaseAccountPage {

  DeleteAccountPage(GlobalKey<ScaffoldState> scaffoldKey) : super(scaffoldKey, 'Delete Account');

  Widget _buildBody(BuildContext context) {
    return _DeleteAccountForm();
  }
}

class ChangePasswordPage extends BaseAccountPage {

  ChangePasswordPage(GlobalKey<ScaffoldState> scaffoldKey) : super(scaffoldKey, 'Change Password');

  Widget _buildBody(BuildContext context) {
    return _ChangePasswordForm();
  }
}
