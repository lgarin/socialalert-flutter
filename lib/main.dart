import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/annotate.dart';
import 'package:social_alert_app/home.dart';
import 'package:social_alert_app/login.dart';
import 'package:social_alert_app/media.dart';
import 'package:social_alert_app/network.dart';
import 'package:social_alert_app/picture.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/geolocation.dart';
import 'package:social_alert_app/service/mediaquery.dart';
import 'package:social_alert_app/service/mediaupdate.dart';
import 'package:social_alert_app/service/mediaupload.dart';
import 'package:social_alert_app/uploads.dart';

void main() => runApp(SocialAlertApp());

class SocialAlertApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          Provider<GeoLocationService>(create: (_) => GeoLocationService(), dispose: (_, service) => service.dispose()),
          StreamProvider<GeoLocation>(create: (context) => GeoLocationService.current(context).locationStream),
          Provider<AuthService>(create: (_) => AuthService(), dispose: (_, service) => service.dispose()),
          StreamProvider<UserProfile>(create: (context) => AuthService.current(context).profileStream),
          Provider<MediaUploadService>(create: (context) => MediaUploadService(AuthService.current(context)), dispose: (_, service) => service.dispose()),
          Provider<MediaQueryService>(create: (context) => MediaQueryService(AuthService.current(context))),
          Provider<MediaUpdateService>(create: (context) => MediaUpdateService(AuthService.current(context))),
        ],
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
            subtitle2: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)
          ),
        ),
        initialRoute: AppRoute.Login,
        routes: {
          AppRoute.Login: (context) => LoginPage(),
          AppRoute.Home: (context) => HomePage(),
          AppRoute.Uploads: (context) => UploadsPage(),
          AppRoute.Annotate: (context) => AnnotatePage(ModalRoute.of(context).settings.arguments),
          AppRoute.Network: (context) => NetworkPage(),
          AppRoute.LocalPictureInfo: (context) => LocalPictureInfoPage(ModalRoute.of(context).settings.arguments),
          AppRoute.RemotePictureDetail: (context) => RemotePictureDetailPage(ModalRoute.of(context).settings.arguments),
        },
      );
  }
}

class AppRoute {
  static const Login = 'login';
  static const Home = 'home';
  static const Annotate = 'annotate';
  static const Uploads = 'uploads';
  static const Network = 'network';
  static const LocalPictureInfo = 'pictureInfo';
  static const RemotePictureDetail ='pictureDetail';
}