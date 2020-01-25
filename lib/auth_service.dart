import 'dart:async';
import 'package:flutter/material.dart';

class AuthService with ChangeNotifier {
  String _token;
  void loginUser({String username, String password}) async {
    _token = await Future.delayed(Duration(seconds: 10), () => "abcd");
    notifyListeners();
  }
}