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

class PageWrapper extends StatefulWidget {

  final GlobalKey<ScaffoldState> pageKey;
  final String pageName;
  final Widget page;

  const PageWrapper({this.pageKey, this.pageName, this.page});

  @override
  _PageWrapperState createState() => _PageWrapperState();
}

class _PageWrapperState extends State<PageWrapper> {

  PageManager _pageManager;

  @override
  void initState() {
    super.initState();
    _pageManager = PageManager.current(context);
    _pageManager.pushPage(widget.pageKey, widget.pageName);
  }

  @override
  void dispose() {
    _pageManager.discardPage(widget.pageKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: widget.page,
      onWillPop: _onPagePop,
    );
  }

  Future<bool> _onPagePop() {
    _pageManager.popPage(widget.pageKey);
    return Future.value(true);
  }
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

  void discardPage(GlobalKey<ScaffoldState> key) {
    final index = _pageKeys.lastIndexOf(key);
    if (index >= 0) {
      _pageKeys.removeAt(index);
      _pageNames.removeAt(index);
    }
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

  ScaffoldState get currentPageState => _lastPageKey?.currentState;

  String get currentPageName => _lastPageName;

  @override
  void dispose() {
    _pageKeys.clear();
    _pageNames.clear();
  }
}
