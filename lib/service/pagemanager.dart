import 'package:flutter/material.dart';
import 'package:social_alert_app/service/eventbus.dart';
import 'package:social_alert_app/service/serviceprodiver.dart';

enum PageEventType {
  SHOW,
  HIDE,
}

class PageEvent {
  final String pageName;
  final PageEventType type;

  PageEvent(this.pageName, this.type);
}

class PageManager extends Service {

  static PageManager of(BuildContext context) => ServiceProvider.of(context);

  GlobalKey<ScaffoldState> _currentPageKey;
  String _currentPageName;

  PageManager(BuildContext context) : super(context);

  EventBus get _eventBus => lookup();

  void setCurrent(GlobalKey<ScaffoldState> pageKey, String pageName) {
    if (pageKey == _currentPageKey) {
      return;
    }
    if (_currentPageKey != null) {
      _eventBus.fire(PageEvent(_currentPageName, PageEventType.HIDE));
    }
    _currentPageKey = pageKey;
    _currentPageName = pageName;
    Future(() => _eventBus.fire(PageEvent(pageName, PageEventType.SHOW)));
  }

  ScaffoldState get currentPageState => _currentPageKey?.currentState;

  String get currentPageName => _currentPageName;

  @override
  void dispose() {
  }
}
