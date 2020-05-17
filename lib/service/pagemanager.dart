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

  static PageManager current(BuildContext context) => ServiceProvider.of(context);

  final _pageKeys = List<GlobalKey<ScaffoldState>>();
  final _pageNames = List<String>();

  PageManager(BuildContext context) : super(context);

  EventBus get _eventBus => lookup();

  String get _lastPageName => _pageNames.isEmpty ? null : _pageNames.last;
  GlobalKey<ScaffoldState> get _lastPageKey => _pageKeys.isEmpty ? null : _pageKeys.last;

  void pushPage(GlobalKey<ScaffoldState> key, String pageName) {
    final previousPage = _lastPageName;
    if (previousPage != null) {
      _eventBus.fire(PageEvent(previousPage, PageEventType.HIDE));
    }
    _pageKeys.add(key);
    _pageNames.add(pageName);
    Future(() => _eventBus.fire(PageEvent(pageName, PageEventType.SHOW)));
  }

  void popPage(GlobalKey<ScaffoldState> key) {
    final index = _pageKeys.lastIndexOf(key);
    assert(index >= 0);
    _pageKeys.removeAt(index);
    final pageName = _pageNames.removeAt(index);
    _eventBus.fire(PageEvent(pageName, PageEventType.HIDE));

    final previousPage = _lastPageName;
    if (previousPage != null) {
      Future(() => _eventBus.fire(PageEvent(previousPage, PageEventType.SHOW)));
    }
  }

  ScaffoldState get currentPageState => _lastPageKey.currentState;

  String get currentPageName => _lastPageName;

  @override
  void dispose() {
    _pageKeys.forEach((element) => element.currentState?.dispose());
    _pageKeys.clear();
    _pageNames.clear();
  }
}
