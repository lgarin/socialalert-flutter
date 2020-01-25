import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/auth_service.dart';

import 'helper.dart';

class LoginModel {
  final username = TextEditingController();
  final password = TextEditingController();

  LoginModel();

  LoginModel.fromJson(Map<String, dynamic> json) {
    username.text = json['username'];
    password.text = json['password'];
  }

  Map<String, dynamic> toJson() =>
  {
    'username': username.text,
    'password': password.text,
  };

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

// TODO should be a credential store for LoginParameter
class _LoginStore {
  final _storage = new FlutterSecureStorage();

  Future<LoginModel> _loadModel() async {
    try {
      final json = await _storage.read(key: "lastLogin");
      if (json == null) {
        return LoginModel();
      }
      return LoginModel.fromJson(jsonDecode(json));
    } catch (e) {
      print(e);
      return LoginModel();
    }
  }

  Future<void> _saveModel(LoginModel model) async {
    try {
      await _storage.write(key: "lastLogin", value: jsonEncode(model));
    } catch (e) {
      print(e);
    }
  }
}

class _LoginHeader extends StatelessWidget {
  final String logoPath = "images/logo_login.png";
  final String message = "Show your world as it is";

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
          Text(message, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white))
        ])
    );
  }
}

class _UsernameWidget extends StatelessWidget {
  const _UsernameWidget({
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
            hintText: "Username",
            icon: Icon(Icons.perm_identity)),
        validator: RequiredValidator(errorText: "Username required"),
      ),
    );
  }
}

class _PasswordWidget extends StatelessWidget {
  const _PasswordWidget({
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
              hintText: "Password",
              icon: Icon(Icons.lock_open)),
          validator: RequiredValidator(errorText: "Password required"),
        ));
  }
}

class _LoginButton extends StatelessWidget {

  const _LoginButton({
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
              "Login", style: TextStyle(color: Colors.white, fontSize: 18)),
          onPressed: () => onLogin(model),
          color: Color.fromARGB(255, 32, 47, 128),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                  Radius.circular(20))),
        )
    );
  }
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _loginStore = _LoginStore();
  final _authService = AuthService();
  LoginParameter _credentials;

  void _onLogin(LoginModel model) {
    final form = _formKey.currentState;
    if (form.validate()) {
      setState(() {
        _credentials = LoginParameter(model.username.text, model.password.text);
      });
    }
  }

  Future<LoginModel> _prepareModel(BuildContext context) {
    return _loginStore._loadModel();
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
      //await Future.delayed(Duration(seconds: 3), () => 'ok');
      // TODO cleanup
      await _loginStore._saveModel(LoginModel.fromJson(_credentials.toJson()));
      var response = await _authService.loginUser(_credentials);
      //await buildErrorDialog(context, "Success", "Hello ${response.username}");
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

  const _LoginWidget({
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
  final String backgroundImagePath = "images/login_bg.jpg";
  final Color backgroundColor = Color.fromARGB(255, 63, 79, 167);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: backgroundColor,
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
