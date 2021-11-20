import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/account.dart';
import 'package:social_alert_app/annotate.dart';
import 'package:social_alert_app/capture.dart';
import 'package:social_alert_app/home.dart';
import 'package:social_alert_app/local.dart';
import 'package:social_alert_app/login.dart';
import 'package:social_alert_app/network.dart';
import 'package:social_alert_app/notification.dart';
import 'package:social_alert_app/profile.dart';
import 'package:social_alert_app/register.dart';
import 'package:social_alert_app/remote.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/cameradevice.dart';
import 'package:social_alert_app/service/commentquery.dart';
import 'package:social_alert_app/service/dataobject.dart';
import 'package:social_alert_app/service/eventbus.dart';
import 'package:social_alert_app/service/feedquery.dart';
import 'package:social_alert_app/service/filesystem.dart';
import 'package:social_alert_app/service/geolocation.dart';
import 'package:social_alert_app/service/datasource.dart';
import 'package:social_alert_app/service/mediaquery.dart';
import 'package:social_alert_app/service/mediastatistic.dart';
import 'package:social_alert_app/service/mediaupdate.dart';
import 'package:social_alert_app/service/mediaupload.dart';
import 'package:social_alert_app/service/navigation.dart';
import 'package:social_alert_app/service/pagemanager.dart';
import 'package:social_alert_app/service/permission.dart';
import 'package:social_alert_app/service/profilequery.dart';
import 'package:social_alert_app/service/profileupdate.dart';
import 'package:social_alert_app/service/serviceprodiver.dart';
import 'package:social_alert_app/service/useraccount.dart';
import 'package:social_alert_app/service/userstatistic.dart';
import 'package:social_alert_app/service/videoencoder.dart';
import 'package:social_alert_app/service/servernotification.dart';
import 'package:social_alert_app/settings.dart';
import 'package:social_alert_app/statistic.dart';
import 'package:social_alert_app/upload.dart';

import 'helper.dart';

void main() => runApp(SocialAlertApp(GlobalKey<NavigatorState>()));

class SocialAlertApp extends StatelessWidget {

  final GlobalKey<NavigatorState> _navigatorKey;

  SocialAlertApp(this._navigatorKey);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ServiceProvider<NavigationService>(create: (context) => NavigationService(context, _navigatorKey)),
          ServiceProvider<EventBus>(create: (context) => EventBus(context)),
          ServiceProvider<PageManager>(create: (context) => PageManager(context)),
          ServiceProvider<PermissionManager>(create: (context) => PermissionManager(context)),
          ServiceProvider<FileSystem>(create: (context) => FileSystem(context)),
          ServiceProvider<DataSource>(create: (context) => DataSource(context)),
          ServiceProvider<CameraDevice>(create: (context) => CameraDevice(context)),
          ServiceProvider<VideoEncoder>(create: (context) => VideoEncoder(context)),
          ServiceProvider<GeoLocationService>(create: (context) => GeoLocationService(context)),
          StreamProvider<GeoLocation>(create: (context) => GeoLocationService.of(context).locationStream, lazy: false, initialData: null),
          ServiceProvider<Authentication>(create: (context) => Authentication(context)),
          ServiceProvider<UserAccountService>(create: (context) => UserAccountService(context)),
          ServiceProvider<ProfileQueryService>(create: (context) => ProfileQueryService(context)),
          ServiceProvider<ProfileUpdateService>(create: (context) => ProfileUpdateService(context)),
          StreamProvider<UserProfile>(create: (context) => ProfileUpdateService.of(context).profileStream, lazy: false, initialData: null),
          StreamProvider<AvatarUploadProgress>(create: (context) => ProfileUpdateService.of(context).uploadProgressStream, lazy: false, initialData: null),
          ServiceProvider<MediaUploadService>(create: (context) => MediaUploadService(context)),
          FutureProvider<MediaUploadList>(create: (context) => MediaUploadService.of(context).currentUploads(), catchError: showUnexpectedError, lazy: false, initialData: null),
          ServiceProvider<MediaQueryService>(create: (context) => MediaQueryService(context)),
          ServiceProvider<MediaUpdateService>(create: (context) => MediaUpdateService(context)),
          ServiceProvider<CommentQueryService>(create: (context) => CommentQueryService(context)),
          ServiceProvider<FeedQueryService>(create: (context) => FeedQueryService(context)),
          ServiceProvider<ServerNotification>(create: (context) => ServerNotification(context)),
          StreamProvider<UserNotification>(create: (context) => ServerNotification.of(context).userNotificationStream, lazy: false, initialData: null),
          ServiceProvider<UserStatisticService>(create: (context) => UserStatisticService(context)),
          ServiceProvider<MediaStatisticService>(create: (context) => MediaStatisticService(context)),
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
          backgroundColor: Color.fromARGB(255, 63, 79, 167),
          appBarTheme: AppBarTheme(backgroundColor: Color.fromARGB(255, 63, 79, 167)),
          textTheme: TextTheme(
            button: TextStyle(fontSize: 18, color: Colors.white),
            subtitle2: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)
          ),
        ),
        initialRoute: AppRoute.Login,
        navigatorKey: _navigatorKey,
        onGenerateRoute: _buildRoute,
      );
  }

  MaterialPageRoute _buildRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoute.Login: return _TrackedMaterialPageRoute(
          settings: settings,
          builder: (_) => LoginPage()
      );
      case AppRoute.Register: return _TrackedMaterialPageRoute(
          settings: settings,
          builder: (_) => RegisterPage()
      );
      case AppRoute.Home: return _TrackedMaterialPageRoute(
          settings: settings,
          builder: (_) => HomePage()
      );
      case AppRoute.UploadManager: return _TrackedMaterialPageRoute(
          settings: settings,
          builder: (_) => UploadManagerPage()
      );
      case AppRoute.AnnotateMedia: return _TrackedMaterialPageRoute(
          settings: settings,
          builder: (_) => AnnotateMediaPage(settings.arguments)
      );
      case AppRoute.UserNetwork: return _TrackedMaterialPageRoute(
          settings: settings,
          builder: (_) => UserNetworkPage(settings.arguments)
      );
      case AppRoute.LocalMediaInfo: return _TrackedMaterialPageRoute(
          settings: settings,
          builder: (_) => LocalMediaInfoPage(settings.arguments)
      );
      case AppRoute.RemoteMediaDetail: return _TrackedMaterialPageRoute<MediaDetail>(
          settings: settings,
          builder: (_) => RemoteMediaDetailPage(settings.arguments)
      );
      case AppRoute.ProfileViewer: return _TrackedMaterialPageRoute<UserProfile>(
          settings: settings,
          builder: (_) => ProfileViewerPage(settings.arguments)
      );
      case AppRoute.ProfileEditor: return _TrackedMaterialPageRoute(
          settings: settings,
          builder: (_) => ProfileEditorPage()
      );
      case AppRoute.SettingsEditor: return _TrackedMaterialPageRoute(
          settings: settings,
          builder: (_) => SettingsEditorPage()
      );
      case AppRoute.LocalMediaDisplay: return _TrackedMaterialPageRoute(
          skipAnimation: true,
          settings: settings,
          builder: (_) => LocalMediaDisplayPage(settings.arguments)
      );
      case AppRoute.RemoteMediaDisplay: return _TrackedMaterialPageRoute(
          skipAnimation: true,
          settings: settings,
          builder: (_) => RemoteMediaDisplayPage(settings.arguments)
      );
      case AppRoute.CaptureMedia: return _TrackedMaterialPageRoute(
          skipAnimation: true,
          settings: settings,
          builder: (_) => CaptureMediaPage()
      );
      case AppRoute.DeleteAccount: return _TrackedMaterialPageRoute(
          settings: settings,
          builder: (_) => DeleteAccountPage()
      );
      case AppRoute.ChangePassword: return _TrackedMaterialPageRoute(
          settings: settings,
          builder: (_) => ChangePasswordPage()
      );
      case AppRoute.MediaNotification: return _TrackedMaterialPageRoute(
        settings: settings,
        builder: (_) => MediaNotificationPage()
      );
      case AppRoute.UserStatistic: return _TrackedMaterialPageRoute(
          settings: settings,
          builder: (_) => UserStatisticPage()
      );
      default: return null;
    }
  }
}

class AppRoute {
  static const Login = 'login';
  static const Register = 'register';
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
  static const DeleteAccount = 'deleteAccount';
  static const ChangePassword = 'changePassword';
  static const MediaNotification = 'mediaNotification';
  static const UserStatistic = "userStatistic";
}

class _TrackedMaterialPageRoute<T> extends MaterialPageRoute<T> {

  final bool skipAnimation;

  _TrackedMaterialPageRoute({
    @required WidgetBuilder builder,
    @required RouteSettings settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
    this.skipAnimation = false,
  }) : super(
      builder: builder,
      maintainState: maintainState,
      settings: settings,
      fullscreenDialog: fullscreenDialog);

  String get pageName => settings?.name;

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {

    if (skipAnimation) {
      return child;
    }
    return super.buildTransitions(context, animation, secondaryAnimation, child);
  }

  void _notifyPageChange() {
    if (isCurrent) {
      PageManager pageManager = navigator.context.read();
      pageManager.setCurrent(pageName);
    }
  }

  @override
  void didAdd() {
    super.didAdd();
    _notifyPageChange();
  }

  @override
  void didReplace(Route<dynamic> oldRoute) {
    super.didReplace(oldRoute);
    _notifyPageChange();
  }

  @override
  void didChangePrevious(Route<dynamic> previousRoute) {
    super.didChangePrevious(previousRoute);
    _notifyPageChange();
  }

  @override
  void didChangeNext(Route<dynamic> nextRoute) {
    super.didChangeNext(nextRoute);
    _notifyPageChange();
  }

  @override
  void didPopNext(Route<dynamic> nextRoute) {
    super.didPopNext(nextRoute);
    _notifyPageChange();
  }
}