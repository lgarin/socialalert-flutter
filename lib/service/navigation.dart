import 'package:flutter/widgets.dart';
import 'package:social_alert_app/service/serviceprodiver.dart';

class NavigationService extends Service {

  static NavigationService of(BuildContext context) => ServiceProvider.of(context);

  final GlobalKey<NavigatorState> navigatorKey;

  NavigationService(BuildContext context, this.navigatorKey) : super(context);

  Future<T> pushPage<T>(String pageName) {
    final navigator = navigatorKey.currentState;
    return navigator?.pushNamed(pageName);
  }

  Future<T> removeAllAndPushPage<T>(String pageName) {
    final navigator = navigatorKey.currentState;
    return navigator?.pushNamedAndRemoveUntil(pageName, (route) => true);
  }

  @override
  void dispose() {
  }
}