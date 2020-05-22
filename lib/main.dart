import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/annotate.dart';
import 'package:social_alert_app/base.dart';
import 'package:social_alert_app/capture.dart';
import 'package:social_alert_app/home.dart';
import 'package:social_alert_app/local.dart';
import 'package:social_alert_app/login.dart';
import 'package:social_alert_app/network.dart';
import 'package:social_alert_app/profile.dart';
import 'package:social_alert_app/remote.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/cameradevice.dart';
import 'package:social_alert_app/service/commentquery.dart';
import 'package:social_alert_app/service/dataobjet.dart';
import 'package:social_alert_app/service/eventbus.dart';
import 'package:social_alert_app/service/feedquery.dart';
import 'package:social_alert_app/service/filesystem.dart';
import 'package:social_alert_app/service/geolocation.dart';
import 'package:social_alert_app/service/datasource.dart';
import 'package:social_alert_app/service/mediaquery.dart';
import 'package:social_alert_app/service/mediaupdate.dart';
import 'package:social_alert_app/service/mediaupload.dart';
import 'package:social_alert_app/service/pagemanager.dart';
import 'package:social_alert_app/service/permission.dart';
import 'package:social_alert_app/service/profilequery.dart';
import 'package:social_alert_app/service/profileupdate.dart';
import 'package:social_alert_app/service/serviceprodiver.dart';
import 'package:social_alert_app/service/videoencoder.dart';
import 'package:social_alert_app/settings.dart';
import 'package:social_alert_app/upload.dart';

import 'helper.dart';

void main() => runApp(SocialAlertApp());

class SocialAlertApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ServiceProvider<DataSource>(create: (context) => DataSource(context)),
          ServiceProvider<CameraDevice>(create: (context) => CameraDevice(context)),
          ServiceProvider<GeoLocationService>(create: (context) => GeoLocationService(context)),
          StreamProvider<GeoLocation>(create: (context) => GeoLocationService.of(context).locationStream, lazy: false),
          ServiceProvider<Authentication>(create: (context) => Authentication(context)),
          ServiceProvider<ProfileQueryService>(create: (context) => ProfileQueryService(context)),
          ServiceProvider<ProfileUpdateService>(create: (context) => ProfileUpdateService(context)),
          StreamProvider<UserProfile>(create: (context) => ProfileUpdateService.of(context).profileStream, lazy: false),
          StreamProvider<AvatarUploadProgress>(create: (context) => ProfileUpdateService.of(context).uploadProgressStream, lazy: false),
          ServiceProvider<MediaUploadService>(create: (context) => MediaUploadService(context)),
          FutureProvider<MediaUploadList>(create: (context) => MediaUploadService.of(context).currentUploads(), lazy: false, catchError: showUnexpectedError),
          ServiceProvider<MediaQueryService>(create: (context) => MediaQueryService(context)),
          ServiceProvider<MediaUpdateService>(create: (context) => MediaUpdateService(context)),
          ServiceProvider<CommentQueryService>(create: (context) => CommentQueryService(context)),
          ServiceProvider<FeedQueryService>(create: (context) => FeedQueryService(context)),
          ServiceProvider<FileSystem>(create: (context) => FileSystem(context)),
          ServiceProvider<VideoEncoder>(create: (context) => VideoEncoder(context)),
          ServiceProvider<EventBus>(create: (context) => EventBus(context)),
          ServiceProvider<PageManager>(create: (context) => PageManager(context)),
          ServiceProvider<PermissionManager>(create: (context) => PermissionManager(context)),
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

  static WidgetBuilder _createRouteBuilder(RouteSettings settings, ScaffoldPage pageWidget) {
    return (context) => PageWrapper(page: pageWidget, pageKey: pageWidget.scaffoldKey, pageName: settings.name);
  }

  MaterialPageRoute _buildRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoute.Login: return MaterialPageRoute(
        builder: _createRouteBuilder(settings, LoginPage(GlobalKey<ScaffoldState>()))
      );
      case AppRoute.Home: return MaterialPageRoute(
          builder: _createRouteBuilder(settings, HomePage(GlobalKey<ScaffoldState>()))
      );
      case AppRoute.UploadManager: return MaterialPageRoute(
          builder: _createRouteBuilder(settings, UploadManagerPage(GlobalKey<ScaffoldState>()))
      );
      case AppRoute.AnnotateMedia: return MaterialPageRoute(
          builder: _createRouteBuilder(settings, AnnotateMediaPage(GlobalKey<ScaffoldState>(), settings.arguments))
      );
      case AppRoute.UserNetwork: return MaterialPageRoute(
          builder: _createRouteBuilder(settings, UserNetworkPage(GlobalKey<ScaffoldState>()))
      );
      case AppRoute.LocalMediaInfo: return MaterialPageRoute(
          builder: _createRouteBuilder(settings, LocalMediaInfoPage(GlobalKey<ScaffoldState>(), settings.arguments))
      );
      case AppRoute.RemoteMediaDetail: return MaterialPageRoute<MediaDetail>(
        builder: _createRouteBuilder(settings, RemoteMediaDetailPage(GlobalKey<ScaffoldState>(), settings.arguments))
      );
      case AppRoute.ProfileViewer: return MaterialPageRoute<UserProfile>(
        builder: _createRouteBuilder(settings, ProfileViewerPage(GlobalKey<ScaffoldState>(), settings.arguments))
      );
      case AppRoute.ProfileEditor: return MaterialPageRoute(
        builder: _createRouteBuilder(settings, ProfileEditorPage(GlobalKey<ScaffoldState>()))
      );
      case AppRoute.SettingsEditor: return MaterialPageRoute(
        builder: _createRouteBuilder(settings, SettingsEditorPage(GlobalKey<ScaffoldState>()))
      );
      case AppRoute.LocalMediaDisplay: return NoAnimationMaterialPageRoute(
          builder: _createRouteBuilder(settings, LocalMediaDisplayPage(GlobalKey<ScaffoldState>(), settings.arguments))
      );
      case AppRoute.RemoteMediaDisplay: return NoAnimationMaterialPageRoute(
        builder: _createRouteBuilder(settings, RemoteMediaDisplayPage(GlobalKey<ScaffoldState>(), settings.arguments))
      );
      case AppRoute.CaptureMedia: return NoAnimationMaterialPageRoute(
          builder: _createRouteBuilder(settings, CaptureMediaPage(GlobalKey<ScaffoldState>()))
      );
      default: return null;
    }
  }
}

class AppRoute {
  static const Login = 'login';
  static const Home = 'home';
  static const CaptureMedia = 'captureMedia';
  static const AnnotateMedia = 'annotateMedia';
  static const UploadManager = 'uploadManager';
  static const UserNetwork = 'userNetwork';
  static const LocalMediaInfo = 'localMediaInfo';
  static const LocalMediaDisplay = 'localMediaDisplay';
  static const RemoteMediaDetail = 'remoteMediaDetail';
  static const RemoteMediaDisplay = 'remoteMediaDisplay';
  static const ProfileEditor = 'profileEditor';
  static const ProfileViewer = 'profileViewer';
  static const SettingsEditor = 'settingsEditor';
}