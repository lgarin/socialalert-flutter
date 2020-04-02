import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/credential.dart';

class _LoginModel {
  final username = TextEditingController();
  final password = TextEditingController();

  _LoginModel();

  _LoginModel.fromCredential(Credential credential) {
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

  bool isDefined() {
    return hasUsernameInput() && hasPasswordInput();
  }

  @override
  String toString() {
    return '$runtimeType(${username.text}, ${password.text})';
  }

  Credential toCredential() => Credential(username.text, password.text);
}

typedef _LoginCallBack = void Function(_LoginModel);

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

  final _LoginModel model;

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

  final _LoginModel model;

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
  static const color = Color.fromARGB(255, 231, 40, 102);
  static const label = 'Login';

  _LoginButton({
    Key key,
    @required this.model,
    @required this.onLogin
  }) : super(key: key);

  final _LoginCallBack onLogin;
  final _LoginModel model;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: double.infinity,
        height: 40,
        child:
        RaisedButton(
          child: Text(label, style: Theme.of(context).textTheme.button),
          onPressed: () => onLogin(model),
          color: color,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20))),
        )
    );
  }
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();

  void _onLogin(_LoginModel model) {
    final form = _formKey.currentState;
    if (form != null && form.validate()) {
      setState(() {});
    }
  }

  Future<UserProfile> _findCurrentUser(BuildContext context) async {
    return await AuthService.current(context).currentUser();
  }

  Future<_LoginModel> _prepareModel(BuildContext context) async {
    final credential = await AuthService.current(context).initialCredential;
    return _LoginModel.fromCredential(credential);
  }

  Future<UserProfile> _handleLoginPhases(UserProfile user, _LoginModel login) {
    if (user != null) {
      _showNextPage(user);
      return Future.value(user);
    } else if (login != null && login.isDefined()) {
      return _authenticateUser(login.toCredential());
    } else {
      return Future.value(null);
    }
  }

  void _showNextPage(UserProfile userProfile) {
    if (userProfile.offline) {
      Future(() => Navigator.pushReplacementNamed(context, AppRoute.UploadManager, arguments: userProfile));
    } else {
      Future(() => Navigator.pushReplacementNamed(context, AppRoute.Home, arguments: userProfile));
    }
  }

  Future<UserProfile> _authenticateUser(Credential credential) async {
    try {
      final userProfile = await AuthService.current(context).authenticate(credential);
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
        lazy: false,
        child: FutureProvider<_LoginModel>(
          create: _prepareModel,
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
    Key key,
    @required this.formKey,
    @required this.onLogin,
  }) : super(key: key);

  final GlobalKey<FormState> formKey;
  final _LoginCallBack onLogin;

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
                margin: EdgeInsets.all(margin),
                child: _LoginHeader()
              ),
              Container(
                margin: EdgeInsets.all(margin),
                child: _LoginForm(),
              ),
            ]);
  }
}
