import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/annotate.dart';
import 'package:social_alert_app/home.dart';
import 'package:social_alert_app/login.dart';
import 'package:social_alert_app/media.dart';
import 'package:social_alert_app/network.dart';
import 'package:social_alert_app/picture.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/cameradevice.dart';
import 'package:social_alert_app/service/geolocation.dart';
import 'package:social_alert_app/service/mediamodel.dart';
import 'package:social_alert_app/service/mediaquery.dart';
import 'package:social_alert_app/service/mediaupdate.dart';
import 'package:social_alert_app/service/mediaupload.dart';
import 'package:social_alert_app/service/profileupdate.dart';
import 'package:social_alert_app/upload.dart';
import 'package:social_alert_app/user.dart';

void main() => runApp(SocialAlertApp());

class SocialAlertApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          Provider<CameraDeviceService>(create: (_) => CameraDeviceService()),
          Provider<GeoLocationService>(create: (_) => GeoLocationService(), dispose: (_, service) => service.dispose()),
          StreamProvider<GeoLocation>(create: (context) => GeoLocationService.current(context).locationStream, lazy: false),
          Provider<AuthService>(create: (_) => AuthService(), dispose: (_, service) => service.dispose()),
          Provider<ProfileUpdateService>(create: (context) => ProfileUpdateService(AuthService.current(context)), dispose: (_, service) => service.dispose()),
          StreamProvider<UserProfile>(create: (context) => ProfileUpdateService.current(context).profileStream, lazy: false),
          StreamProvider<AvatarUploadProgress>(create: (context) => ProfileUpdateService.current(context).uploadProgressStream, lazy: false),
          Provider<MediaUploadService>(create: (context) => MediaUploadService(AuthService.current(context), GeoLocationService.current(context)), dispose: (_, service) => service.dispose()),
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
        onGenerateRoute: _buildRoute,
      );
  }

  MaterialPageRoute _buildRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoute.Login: return MaterialPageRoute(
        builder: (context) => LoginPage()
      );
      case AppRoute.Home: return MaterialPageRoute(
          builder: (context) => HomePage()
      );
      case AppRoute.UploadManager: return MaterialPageRoute(
          builder: (context) => UploadManagerPage()
      );
      case AppRoute.AnnotatePicture: return MaterialPageRoute(
          builder: (context) => AnnotatePicturePage(settings.arguments)
      );
      case AppRoute.Network: return MaterialPageRoute(
          builder: (context) => NetworkPage()
      );
      case AppRoute.LocalPictureInfo: return MaterialPageRoute(
          builder: (context) => LocalPictureInfoPage(settings.arguments)
      );
      case AppRoute.RemotePictureDetail: return MaterialPageRoute<MediaDetail>(
        builder: (context) => RemotePictureDetailPage(settings.arguments)
      );
      case AppRoute.ProfileEditor: return MaterialPageRoute(
        builder: (context) => ProfileEditorPage()
      );
      default: return null;
    }
  }
}

class AppRoute {
  static const Login = 'login';
  static const Home = 'home';
  static const AnnotatePicture = 'annotatePicture';
  static const UploadManager = 'uploadManager';
  static const Network = 'network';
  static const LocalPictureInfo = 'pictureInfo';
  static const RemotePictureDetail ='pictureDetail';
  static const ProfileEditor = 'profileEditor';
}