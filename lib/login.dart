import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/credential.dart';

import 'main.dart';

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
          Text(message, style: Theme.of(context).textTheme.subtitle2)
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
        validator: NonEmptyValidator(errorText: "$label required"),
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
          validator: RequiredValidator(errorText: "$label required"),
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
  Credential _credential;

  void _onLogin(LoginModel model) {
    final form = _formKey.currentState;
    if (form.validate()) {
      setState(() {
        _credential = Credential(model.username.text, model.password.text);
      });
    }
  }

  Future<LoginModel> _prepareModel(BuildContext context) async {
    final credential = await AuthService.current(context).initialCredential;
    if (credential.isDefined()) {
      _credential = credential;
    }
    return LoginModel.fromCredential(credential);
  }

  Future<bool> _handleLoginPhases() {
    if (_credential != null) {
      return _authenticateUser();
    } else {
      return Future.value(false);
    }
  }

  Future<bool> _authenticateUser() async {
    try {
      final profile = await AuthService.current(context).authenticate(_credential);
      await Navigator.pushReplacementNamed(context, AppRoute.Home, arguments: profile);
      return true;
    } catch (e) {
      await showSimpleDialog(context, "Login failed", e.toString());
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureProvider<LoginModel>(
        create: _prepareModel,
        lazy: true,
        child: FutureBuilder<bool>(
          initialData: false,
          future: _handleLoginPhases(),
          builder: _buildWidget)
    );
  }

  Widget _buildWidget(BuildContext context, AsyncSnapshot<bool> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return LoadingCircle();
    } else if (snapshot.data) {
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

class LoginPage extends StatelessWidget {
  static const backgroundImagePath = "images/login_bg.jpg";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        body: DecoratedBox(
            decoration: BoxDecoration(
                image: DecorationImage(
                    alignment: AlignmentDirectional.bottomCenter,
                    fit: BoxFit.fill,
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
