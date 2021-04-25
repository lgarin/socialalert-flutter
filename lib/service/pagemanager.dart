import 'package:flutter/widgets.dart';
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

  String _currentPageName;

  PageManager(BuildContext context) : super(context);

  EventBus get _eventBus => lookup();

  void setCurrent(String pageName) {
    if (pageName == _currentPageName) {
      return;
    }
    if (_currentPageName != null) {
      _eventBus.fire(PageEvent(_currentPageName, PageEventType.HIDE));
    }
    _currentPageName = pageName;
    Future(() => _eventBus.fire(PageEvent(pageName, PageEventType.SHOW)));
  }

  String get currentPageName => _currentPageName;

  @override
  void dispose() {
  }
}
