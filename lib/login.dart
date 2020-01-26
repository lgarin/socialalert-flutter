import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/authentication.dart';

import 'helper.dart';
import 'credential.dart';

class LoginModel {
  final username = TextEditingController();
  final password = TextEditingController();

  LoginModel();

  LoginModel.fromCredential(Credential credential) {
    username.text = credential.username ?? '';
    password.text = credential.password ?? '';
  }

  bool hasInput() {
    return username.text != '' || password.text != '';
  }

  bool hasUsernameInput() {
    return username.text != '';
  }

  bool hasPasswordInput() {
    return password.text != '';
  }

  @override
  String toString() {
    return '$runtimeType(${username.text}, ${password.text})';
  }
}

typedef LoginCallBack = void Function(LoginModel);

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
          Text(message, style: Theme.of(context).textTheme.subtitle)
        ])
    );
  }
}

class _UsernameWidget extends StatelessWidget {
  static const label = 'Username';

  _UsernameWidget({
    Key key,
    @required this.model,
  }) : super(key: key);

  final LoginModel model;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(10))),
      padding: EdgeInsets.all(10),
      child: TextFormField(
        autofocus: !model.hasUsernameInput(),
        controller: model.username,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
            hintText: label,
            icon: Icon(Icons.perm_identity)),
        validator: RequiredValidator(errorText: "Username required"),
      ),
    );
  }
}

class _PasswordWidget extends StatelessWidget {
  static const label = 'Password';

  _PasswordWidget({
    Key key,
    @required this.model,
  }) : super(key: key);

  final LoginModel model;

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(10))),
        padding: EdgeInsets.all(10),
        child: TextFormField(
          autofocus: model.hasUsernameInput() && !model.hasPasswordInput(),
          controller: model.password,
          obscureText: true,
          decoration: InputDecoration(
              hintText: label,
              icon: Icon(Icons.lock_open)),
          validator: RequiredValidator(errorText: "Password required"),
        ));
  }
}

class _LoginButton extends StatelessWidget {
  static const label = 'Login';

  _LoginButton({
    Key key,
    @required this.model,
    @required this.onLogin
  }) : super(key: key);

  final LoginCallBack onLogin;
  final LoginModel model;

  @override
  Widget build(BuildContext context) {

    return SizedBox(width: double.infinity,
        height: 40,
        child:
        RaisedButton(
          child: Text(
              label, style: Theme.of(context).textTheme.button),
          onPressed: () => onLogin(model),
          color: Theme.of(context).buttonColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                  Radius.circular(20))),
        )
    );
  }
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _credentialStore = CredentialStore();
  final _authService = AuthService();
  Credential _credentials;

  void _onLogin(LoginModel model) {
    final form = _formKey.currentState;
    if (form.validate()) {
      setState(() {
        _credentials = Credential(model.username.text, model.password.text);
      });
    }
  }

  Future<LoginModel> _prepareModel(BuildContext context) async {
    final credential = await _credentialStore.load();
    return LoginModel.fromCredential(credential);
  }

  Future<LoginResponse> _handleLoginPhases() {
    if (_credentials != null) {
      return _authenticateUser();
    } else {
      return Future.value(null);
    }
  }

  Future<LoginResponse> _authenticateUser() async {
    try {
      await _credentialStore.store(_credentials);
      var response = await _authService.loginUser(_credentials);
      await Navigator.pushReplacementNamed(context, "home", arguments: response);
      return response;
    } catch (e) {
      await showSimpleDialog(context, "Login failed", e);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureProvider<LoginModel>(
        create: _prepareModel,
        lazy: false,
        child: FutureBuilder<LoginResponse>(
          future: _handleLoginPhases(),
          builder: _buildWidget)
    );
  }

  Widget _buildWidget(BuildContext context, AsyncSnapshot<LoginResponse> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return LoadingCircle();
    } else if (snapshot.hasData) {
      return null;
    }
    return _LoginWidget(formKey: _formKey, onLogin: _onLogin);
  }
}

class _LoginWidget extends StatelessWidget {

  _LoginWidget({
    Key key,
    @required this.formKey,
    @required this.onLogin,
  }) : super(key: key);

  final GlobalKey<FormState> formKey;
  final LoginCallBack onLogin;

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<LoginModel>(context);
    if (model == null) {
      return LoadingCircle();
    }
    return Form(
        key: formKey,
        autovalidate: model.hasInput(),
        child: Column(
          children: <Widget>[
            _UsernameWidget(model: model),
            SizedBox(height: 10),
            _PasswordWidget(model: model),
            SizedBox(height: 10),
            _LoginButton(model: model, onLogin: onLogin)
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

class LoginScreen extends StatelessWidget {
  static const backgroundImagePath = "images/login_bg.jpg";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        body: DecoratedBox(
            decoration: BoxDecoration(
                image: DecorationImage(
                    alignment: AlignmentDirectional.bottomCenter,
                    fit: BoxFit.fitWidth,
                    image: AssetImage(backgroundImagePath))),
            child: ListView(
                //mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  SizedBox(height: 40),
                  _LoginHeader(),
                  Container(
                    margin: EdgeInsets.all(20),
                    padding: EdgeInsets.all(20),
                    child: _LoginForm(),
                  ),
                ])));
  }
}
