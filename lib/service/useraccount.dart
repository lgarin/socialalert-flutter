import 'package:flutter/widgets.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/datasource.dart';
import 'package:social_alert_app/service/serviceprodiver.dart';

class _NewUserParameter {
  final String username;
  final String email;
  final String password;

  _NewUserParameter(this.username, this.email, this.password);

  Map<String, dynamic> toJson() => {
    'username': username,
    'email': email,
    'password': password,
  };
}


class _UserManagerApi {

  final DataSource dataSource;

  _UserManagerApi(this.dataSource);

  Future<bool> createUser(_NewUserParameter parameter) async {
    final uri = '/user/create';
    final response = await dataSource.postJson(uri: uri, body: parameter);
    if (response.statusCode == 201) {
      return true;
    } else if (response.statusCode == 409) {
      return false;
    }
    throw response.reasonPhrase;
  }

  Future<void> changePassword({String password, String accessToken}) async {
    final uri = '/user/changePassword';
    final response = await dataSource.postText(uri: uri, body: password, accessToken: accessToken);
    if (response.statusCode != 204) {
      throw response.reasonPhrase;
    }
  }
}

class UserAccountService extends Service {

  UserAccountService(BuildContext context) : super(context);

  static UserAccountService of(BuildContext context) => ServiceProvider.of(context);

  Authentication get _authService => lookup();

  _UserManagerApi get _userApi => _UserManagerApi(lookup());

  Future<bool> createUser(String username, String email, String password) async {
    try {
      return await _userApi.createUser(_NewUserParameter(username, email, password));
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<void> changePassword(String newPassword) async {
    final accessToken = await _authService.accessToken;
    try {
      return await _userApi.changePassword(password: newPassword, accessToken: accessToken);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  @override
  void dispose() {
  }
}