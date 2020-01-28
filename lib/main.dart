import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/home.dart';
import 'package:social_alert_app/login.dart';
import 'package:social_alert_app/session.dart';

void main() => runApp(SocialAlertApp());

class SocialAlertApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Provider<UserSession>(create: (_) => UserSession(),
            child: _buildApp()
        );
  }

  MaterialApp _buildApp() {
    return MaterialApp(
        title: 'Snypix',
        theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: Color.fromARGB(255, 54, 71, 163),
          primaryColorDark: Color.fromARGB(255, 43, 56, 130),
          accentColor: Color.fromARGB(255, 82, 173, 243),
          buttonColor: Color.fromARGB(255, 32, 47, 128),
          backgroundColor: Color.fromARGB(255, 63, 79, 167),
          textTheme: TextTheme(
            button: TextStyle(fontSize: 18, color: Colors.white),
            subtitle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)
          ),
        ),
        initialRoute: "login",
        routes: {
          "login": (context) => LoginScreen(),
          "home": (context) => HomePage(ModalRoute.of(context).settings.arguments),
        },
      );
  }
}
