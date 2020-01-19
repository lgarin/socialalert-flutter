import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginModel {
  String username;
  String password;

  LoginModel.of(String username, String password) : this.username = username, this.password = password;

  LoginModel();

  @override
  String toString() {
    return '$runtimeType($username, $password)';
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
        autofocus: model?.username == null,
        enabled: model != null,
        controller: TextEditingController(text: model?.username),
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
            hintText: "Username",
            icon: Icon(Icons.perm_identity)),
        validator: RequiredValidator(errorText: "Username required"),
        onSaved: (value) => model.username = value,
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
          autofocus: model?.username != null,
          controller: TextEditingController(text: model?.password),
          enabled: model != null,
          obscureText: true,
          decoration: InputDecoration(
              hintText: "Password",
              icon: Icon(Icons.lock_open)),
          validator: RequiredValidator(errorText: "Password required"),
          onSaved: (value) => model.password = value,
        ));
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    Key key,
    @required this.onLogin
  }) : super(key: key);

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: double.infinity,
        height: 40,
        child:
        RaisedButton(
          child: Text(
              "Login", style: TextStyle(color: Colors.white)),
          onPressed: onLogin,
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
  final _storage = new FlutterSecureStorage();
  var _autovalidate = false;
  final _model = LoginModel();

  Future<LoginModel> _loadModel() async {
    try {
      _model.username = await _storage.read(key: "username");
      _model.password = await _storage.read(key: "password");
    } catch (e) {
      print(e);
    }
    return _model;
  }

  void _saveModel() async {
    try {
      await _storage.write(key: "username", value: _model.username);
      await _storage.write(key: "password", value: _model.password);
    } catch (e) {
      print(e);
    }
  }

  void _onLogin() {
    var form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      _saveModel();
    } else {
      setState(() {
        _autovalidate = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(future: _loadModel(),
        builder: (BuildContext context,
            AsyncSnapshot<LoginModel> snapshot) =>
            _LoginWidget(model: snapshot.data, formKey: _formKey, autovalidate: _autovalidate, onLogin: _onLogin,)
    );
  }
}

class _LoginWidget extends StatelessWidget {

  const _LoginWidget({
    Key key,
    @required this.model,
    @required this.formKey,
    @required this.autovalidate,
    @required this.onLogin
  }) : super(key: key);

  final GlobalKey<FormState> formKey;
  final LoginModel model;
  final bool autovalidate;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Form(
        key: formKey,
        autovalidate: autovalidate,
        child: Column(
          children: <Widget>[
            _UsernameWidget(model: model),
            SizedBox(height: 10),
            _PasswordWidget(model: model),
            SizedBox(height: 10),
            _LoginButton(onLogin: onLogin)
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
