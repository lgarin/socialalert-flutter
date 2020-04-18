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
import 'package:social_alert_app/service/eventbus.dart';
import 'package:social_alert_app/service/geolocation.dart';
import 'package:social_alert_app/service/httpservice.dart';
import 'package:social_alert_app/service/mediamodel.dart';
import 'package:social_alert_app/service/mediaquery.dart';
import 'package:social_alert_app/service/mediaupdate.dart';
import 'package:social_alert_app/service/mediaupload.dart';
import 'package:social_alert_app/service/profileupdate.dart';
import 'package:social_alert_app/service/serviceprodiver.dart';
import 'package:social_alert_app/settings.dart';
import 'package:social_alert_app/upload.dart';
import 'package:social_alert_app/profile.dart';

import 'helper.dart';

void main() => runApp(SocialAlertApp());

class SocialAlertApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ServiceProvider<JsonHttpService>(create: (context) => JsonHttpService(context)),
          ServiceProvider<CameraDeviceService>(create: (context) => CameraDeviceService(context)),
          ServiceProvider<GeoLocationService>(create: (context) => GeoLocationService(context)),
          StreamProvider<GeoLocation>(create: (context) => GeoLocationService.current(context).locationStream, lazy: false),
          ServiceProvider<AuthService>(create: (context) => AuthService(context)),
          ServiceProvider<ProfileUpdateService>(create: (context) => ProfileUpdateService(context)),
          StreamProvider<UserProfile>(create: (context) => ProfileUpdateService.current(context).profileStream, lazy: false),
          StreamProvider<AvatarUploadProgress>(create: (context) => ProfileUpdateService.current(context).uploadProgressStream, lazy: false),
          ServiceProvider<MediaUploadService>(create: (context) => MediaUploadService(context)),
          ServiceProvider<MediaQueryService>(create: (context) => MediaQueryService(context)),
          ServiceProvider<MediaUpdateService>(create: (context) => MediaUpdateService(context)),
          ServiceProvider<EventBus>(create: (context) => EventBus(context)),
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
      case AppRoute.UserNetwork: return MaterialPageRoute(
          builder: (context) => NetworkPage()
      );
      case AppRoute.LocalPictureInfo: return MaterialPageRoute(
          builder: (context) => LocalPictureInfoPage(settings.arguments)
      );
      case AppRoute.RemotePictureDetail: return MaterialPageRoute<MediaDetail>(
        builder: (context) => RemotePictureDetailPage(settings.arguments)
      );
      case AppRoute.ProfileViewer: return MaterialPageRoute(
        builder: (context) => ProfileViewerPage()
      );
      case AppRoute.ProfileEditor: return MaterialPageRoute(
        builder: (context) => ProfileEditorPage()
      );
      case AppRoute.SettingsEditor: return MaterialPageRoute(
        builder: (context) => SettingsEditorPage()
      );
      case AppRoute.RemotePictureDisplay: return NoAnimationMaterialPageRoute(
        builder: (context) => RemoteImageDisplayPage(settings.arguments)
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
  static const UserNetwork = 'userNetwork';
  static const LocalPictureInfo = 'pictureInfo';
  static const RemotePictureDetail ='pictureDetail';
  static const RemotePictureDisplay = 'pictureDisplay';
  static const ProfileEditor = 'profileEditor';
  static const ProfileViewer = 'profileViewer';
  static const SettingsEditor = 'settingsEditor';
}