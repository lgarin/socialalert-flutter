import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/service/configuration.dart';
import 'package:social_alert_app/service/useraccount.dart';

class _RegisterModel {
  bool _showPassword = false;
  String _username = '';
  String _email = '';
  String _password = '';

  _RegisterModel();

  String get username => _username;
  String get email => _email;
  String get password => _password;

  bool get showPassword => _showPassword;
  void switchPasswordVisibility() => _showPassword = !_showPassword;

  void setUsername(String newUsername) => _username = newUsername;
  void setEmail(String newEmail) => _email = newEmail;
  void setPassword(String newPassword) => _password = newPassword;

  bool hasInput() => hasUsernameInput() || hasEmailInput() || hasPasswordInput();

  bool hasUsernameInput() => _username != '';

  bool hasEmailInput() => _email != '';

  bool hasPasswordInput() => _password != '';
}


class _UsernameWidget extends StatelessWidget {
  static const label = 'Username';

  _UsernameWidget({
    @required this.model,
  });

  final _RegisterModel model;

  @override
  Widget build(BuildContext context) {
    return WideRoundedField(
      child: TextFormField(
        autofocus: !model.hasUsernameInput(),
        initialValue: model.username,
        onSaved: model.setUsername,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
            hintText: label,
            icon: Icon(Icons.perm_identity)),
        validator: NonEmptyValidator(errorText: "$label required"),
      ),
    );
  }
}

class _EmailWidget extends StatelessWidget {
  static const label = 'Email';

  _EmailWidget({
    @required this.model,
  });

  final _RegisterModel model;

  @override
  Widget build(BuildContext context) {
    return WideRoundedField(
      child: TextFormField(
        autofocus: model.hasUsernameInput() && !model.hasEmailInput(),
        initialValue: model.email,
        onSaved: model.setEmail,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
            hintText: label,
            icon: Icon(Icons.alternate_email)),
        validator: MultiValidator([
          NonEmptyValidator(errorText: "Email address required"),
          EmailValidator(errorText: "Valid email address required")]
        )
      ),
    );
  }
}

class _PasswordWidget extends StatelessWidget {
  static const label = 'Password';

  _PasswordWidget({
    @required this.model,
    @required this.onSwitchVisibility
  });

  final _RegisterModel model;
  final VoidCallback onSwitchVisibility;

  @override
  Widget build(BuildContext context) {
    return WideRoundedField(
        child: TextFormField(
          autofocus: model.hasUsernameInput() && model.hasEmailInput() && !model.hasPasswordInput(),
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
          validator: MinLengthValidator(minPasswordLength, errorText: "At least $minPasswordLength characters required"),
        )
    );
  }
}

class _RegisterButton extends StatelessWidget {
  static const color = Color.fromARGB(255, 231, 40, 102);
  static const label = 'Register';

  _RegisterButton({
    @required this.onRegister
  });

  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return WideRoundedButton(
        text: label,
        onPressed: onRegister,
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

class _RegisterForm extends StatefulWidget {
  @override
  _RegisterFormState createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  static const spacing = 10.0;

  final _formKey = GlobalKey<FormState>();
  final _model = _RegisterModel();

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        autovalidateMode: _model.hasInput() ? AutovalidateMode.always : AutovalidateMode.onUserInteraction,
        child: _buildContent()
    );
  }

  Column _buildContent() {
    return Column(
        children: <Widget>[
          _UsernameWidget(model: _model),
          SizedBox(height: spacing),
          _EmailWidget(model: _model),
          SizedBox(height: spacing),
          _PasswordWidget(model: _model, onSwitchVisibility: _onSwitchPasswordVisibility),
          /*
          SizedBox(height: spacing),
          _VerificationWidget(model: _model, onSwitchVisibility: _onSwitchPasswordVisibility),
           */
          SizedBox(height: spacing),
          _RegisterButton(onRegister: _onRegister),
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

  void _onRegister() {
    final form = _formKey.currentState;
    if (form != null && form.validate()) {
      form.save();
      _startRegistration();
    }
  }
  
  void _startRegistration() async {
    try {
      final result = await UserAccountService.of(context).createUser(_model.username, _model.email, _model.password);
      await _handleRegistrationResult(result);
    } catch (e) {
      showSimpleDialog(context, 'Registration failure', e.toString());
    }
  }

  Future<void> _handleRegistrationResult(bool result) async {
    if (result) {
      await Navigator.of(context).maybePop();
      showSuccessSnackBar(context, 'New user account has been created');
    } else {
      // TODO differentiate between duplicated username or email address
      await showSimpleDialog(context, 'Account already exists', 'Please use a different username or email address.');
    }
  }
}

class _RegisterHeader extends StatelessWidget {
  static const logoPath = "images/logo_login.png";

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
          logoPath,
          filterQuality: FilterQuality.high,
          height: 200,
      )
    );
  }
}

class RegisterPage extends StatelessWidget {
  static const backgroundImagePath = "images/login_bg.jpg";
  static const margin = 40.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        body: _buildBody());
  }

  DecoratedBox _buildBody() {
    return DecoratedBox(
        decoration: BoxDecoration(
            image: DecorationImage(
                alignment: AlignmentDirectional.bottomCenter,
                fit: BoxFit.fill,
                image: AssetImage(backgroundImagePath))),
        child: _buildContent());
  }

  ListView _buildContent() {
    return ListView(
        children: <Widget>[
          Container(
              margin: EdgeInsets.only(top: margin, left: margin, right: margin),
              child: _RegisterHeader()
          ),
          Container(
            margin: EdgeInsets.all(margin),
            child: _RegisterForm(),
          ),
        ]);
  }
}