import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Credential {
  final String username;
  final String password;

  Credential.empty() : username = null, password = null;

  Credential(this.username , this.password);

  Credential.fromJson(Map<String, dynamic> json) :
    username = json['username'],
    password = json['password'];

  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
  };
}

class CredentialStore {
  static const key = 'crendential';
  final _storage = new FlutterSecureStorage();

  Future<Credential> load() async {
    try {
      final json = await _storage.read(key: key);
      if (json == null) {
        return Credential.empty();
      }
      return Credential.fromJson(jsonDecode(json));
    } catch (e) {
      print(e.toString());
      return Credential.empty();
    }
  }

  Future<void> store(Credential credential) async {
    try {
      await _storage.write(key: key, value: jsonEncode(credential));
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      print(e.toString());
    }
  }
}
