import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/credential.dart';

import 'base.dart';

class _LoginModel {
  String _username = '';
  String _password = '';
  bool _storeCredential = false;

  _LoginModel();

  _LoginModel.fromCredential(Credential credential) {
    _username = credential.username ?? '';
    _password = credential.password ?? '';
    _storeCredential = hasUsernameInput() && hasPasswordInput();
  }

  String get username => _username;
  String get password => _password;
  bool get storeCredential => _storeCredential;

  void setUsername(String newUsername) => _username = newUsername;
  void setPassword(String newPassword) => _password = newPassword;
  void setStoreCredential(bool newValue) => _storeCredential = newValue;

  bool hasInput() => hasUsernameInput() || hasPasswordInput();

  bool hasUsernameInput() => _username != '';

  bool hasPasswordInput() => _password != '';

  bool isDefined() => hasUsernameInput() && hasPasswordInput();

  Credential toCredential() => Credential(username, password);
}

class _LoginHeader extends StatelessWidget {
  static const logoPath = "images/logo_login.png";
  static const message = "Show your world as it is";

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(children: <Widget>[
          Image.asset(
            logoPath,
            filterQuality: FilterQuality.high,
            height: 200,
          ),
          SizedBox(height: 10),
          Text(message, style: Theme.of(context).textTheme.subtitle2)
        ])
    );
  }
}

class _UsernameWidget extends StatelessWidget {
  static const label = 'Username';

  _UsernameWidget({
    @required this.model,
  });

  final _LoginModel model;

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

class _PasswordWidget extends StatelessWidget {
  static const label = 'Password';

  _PasswordWidget({
    @required this.model,
  });

  final _LoginModel model;

  @override
  Widget build(BuildContext context) {
    return WideRoundedField(
      child: TextFormField(
        autofocus: model.hasUsernameInput() && !model.hasPasswordInput(),
        initialValue: model.password,
        onSaved: model.setPassword,
        obscureText: true,
        decoration: InputDecoration(
            hintText: label,
            icon: Icon(Icons.lock_open)),
        validator: RequiredValidator(errorText: "$label required"),
      )
    );
  }
}

class _AutomaticLoginWidget extends StatelessWidget {
  static const label = 'Keep me signed in';

  _AutomaticLoginWidget({
    @required this.model,
  });

  final _LoginModel model;

  @override
  Widget build(BuildContext context) {
    return WideRoundedField(
        padding: EdgeInsets.symmetric(vertical: 10.0),
        child: CheckboxFormField(
          onSaved: model.setStoreCredential,
          initialValue: model.storeCredential,
          title: Text(label, style: Theme.of(context).textTheme.subtitle1),
          secondary: Icon(Icons.vpn_key),
        )
    );
  }
}

class _LoginButton extends StatelessWidget {
  static const color = Color.fromARGB(255, 231, 40, 102);
  static const label = 'Login';

  _LoginButton({
    @required this.onLogin
  });

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return WideRoundedButton(
      text: label,
      onPressed: onLogin,
      color: color
    );
  }
}

class _RegisterButton extends StatelessWidget {
  static const color = Color.fromARGB(255, 32, 47, 128);
  static const label = 'Register';

  @override
  Widget build(BuildContext context) {
    return WideRoundedButton(
        text: label,
        onPressed: () => Navigator.of(context).pushNamed(AppRoute.Register),
        color: color,
    );
  }
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();

  void _onLogin() {
    final form = _formKey.currentState;
    if (form != null && form.validate()) {
      form.save();
      setState(() {});
    }
  }

  Future<UserProfile> _findCurrentUser(BuildContext context) async {
    return await Authentication.of(context).currentUser();
  }

  Future<_LoginModel> _prepareModel(BuildContext context) async {
    final credential = await Authentication.of(context).initialCredential;
    return _LoginModel.fromCredential(credential);
  }

  Future<UserProfile> _handleLoginPhases(UserProfile user, _LoginModel login) {
    if (user != null) {
      _showNextPage(user);
      return Future.value(user);
    } else if (login != null && login.isDefined()) {
      return _authenticateUser(login.toCredential(), login.storeCredential);
    } else {
      return Future.value(null);
    }
  }

  void _showNextPage(UserProfile userProfile) {
    if (Navigator.of(context).canPop()) {
      Future(() => Navigator.of(context).maybePop(userProfile));
    } else if (userProfile.anonym) {
      Future(() => Navigator.of(context).pushReplacementNamed(AppRoute.UploadManager, arguments: userProfile));
    } else {
      Future(() => Navigator.of(context).pushReplacementNamed(AppRoute.Home, arguments: userProfile));
    }
  }

  Future<UserProfile> _authenticateUser(Credential credential, bool storeCredential) async {
    try {
      final userProfile = await Authentication.of(context).authenticate(credential, storeCredential);
      _showNextPage(userProfile);
      return userProfile;
    } catch (e) {
      showSimpleDialog(context, "Login failed", e.toString());
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureProvider<UserProfile>(
        create: _findCurrentUser,
        catchError: showUnexpectedError,
        lazy: false,
        child: FutureProvider<_LoginModel>(
          create: _prepareModel,
          catchError: showUnexpectedError,
          lazy: false,
          child: Consumer2<UserProfile, _LoginModel>(
            builder: (context, user, login, _) => FutureBuilder<UserProfile>(
              future: _handleLoginPhases(user, login),
              builder: _buildWidget
            )
          )
        )
    );
  }

  Widget _buildWidget(BuildContext context, AsyncSnapshot<UserProfile> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return LoadingCircle();
    } else if (snapshot.hasData) {
      return SizedBox(height: 0, width: 0);
    }
    return _LoginWidget(formKey: _formKey, onLogin: _onLogin);
  }
}

class _LoginWidget extends StatelessWidget {
  static const spacing = 10.0;

  _LoginWidget({
    @required this.formKey,
    @required this.onLogin,
  });

  final GlobalKey<FormState> formKey;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<_LoginModel>(context);
    if (model == null) {
      return LoadingCircle();
    }
    return Form(
        key: formKey,
        autovalidate: model.hasInput(),
        child: Column(
          children: <Widget>[
            _UsernameWidget(model: model),
            SizedBox(height: spacing),
            _PasswordWidget(model: model),
            SizedBox(height: spacing),
            _AutomaticLoginWidget(model: model),
            SizedBox(height: spacing),
            _LoginButton(onLogin: onLogin),
            SizedBox(height: spacing),
            _RegisterButton()
          ],
        ));
  }
}

class _LoginForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _LoginFormState();
  }
}

class LoginPage extends StatelessWidget implements ScaffoldPage {
  static const backgroundImagePath = "images/login_bg.jpg";
  static const margin = 40.0;

  final GlobalKey<ScaffoldState> scaffoldKey;

  LoginPage(this.scaffoldKey);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: scaffoldKey,
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
                child: _LoginHeader()
              ),
              Container(
                margin: EdgeInsets.all(margin),
                child: _LoginForm(),
              ),
            ]);
  }
}
