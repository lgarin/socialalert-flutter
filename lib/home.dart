import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/base.dart';
import 'package:social_alert_app/feed.dart';
import 'package:social_alert_app/gallery.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/map.dart';
import 'package:social_alert_app/service/configuration.dart';
import 'package:social_alert_app/service/mediaquery.dart';

class HomePage extends StatefulWidget {

  @override
  _HomePageState createState() => _HomePageState();
}

class _KeywordSearchModel extends ChangeNotifier {
  bool _searching = false;
  final _searchKeyword = TextEditingController();
  final ValueChanged<String> _keywordChanged;

  _KeywordSearchModel(this._keywordChanged);

  TextEditingController get controller => _searchKeyword;

  bool get searching => _searching;

  void switchSearching() {
    if (!_searching) {
      _searching = true;
      _searchKeyword.clear();
    } else {
      _searching = false;
      _keywordChanged(null);
    }
    notifyListeners();
  }

  void beginSearch(String keywords) {
    if (keywords.isNotEmpty) {
      _searchKeyword.text = keywords;
      notifyListeners();
      _keywordChanged(keywords);
    } else {
      switchSearching();
    }
  }

  String get keyword => _searchKeyword.text;
}

class _KeywordSearchWidget extends StatelessWidget {

  final String _inactiveText;
  final SuggestionsCallback<String> _suggestionsCallback;

  _KeywordSearchWidget(this._inactiveText, this._suggestionsCallback);

  @override
  Widget build(BuildContext context) {
    final searchModel = Provider.of<_KeywordSearchModel>(context);
    return searchModel.searching ? _buildSearchField(searchModel) : Text(_inactiveText);
  }

  Widget _buildSearchField(_KeywordSearchModel searchModel) {
    return TypeAheadField<String>(
      direction: AxisDirection.down,
      suggestionsBoxDecoration: SuggestionsBoxDecoration(borderRadius: BorderRadius.all(Radius.circular(5))),
      textFieldConfiguration: TextFieldConfiguration(
          controller: searchModel.controller,
          onSubmitted: (v) => searchModel.beginSearch(v as String),
          autofocus: searchModel.keyword.isEmpty,
          textInputAction: TextInputAction.search,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: false,
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
            hintText: "Enter keyword here",
            icon: Icon(Icons.search, color: Colors.white),
          )
      ),
      itemBuilder: (context, suggestion) => ListTile(title: Text(suggestion)),
      errorBuilder: (context, error) => null,
      noItemsFoundBuilder: (context) => null,
      loadingBuilder: (context) => null,
      suggestionsCallback: _suggestionsCallback,
      hideOnError: true,
      hideOnEmpty: true,
      hideOnLoading: true,
      onSuggestionSelected: searchModel.beginSearch,
      debounceDuration: Duration(milliseconds: 500),
    );
  }
}

class _SearchTriggerWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final searchModel = Provider.of<_KeywordSearchModel>(context);
    return IconButton(
      icon: Icon(searchModel.searching ? Icons.cancel : Icons.search),
      tooltip: searchModel.searching ? 'Cancel' : 'Search',
      onPressed: searchModel.switchSearching,
    );
  }
}

class _HomePageState extends BasePageState<HomePage> with SingleTickerProviderStateMixin {
  static const _galleryIndex = 0;
  static const _feedIndex = 1;
  static const _mapIndex = 2;

  int _currentDisplayIndex = _galleryIndex;
  static final extendedCategoryLabels = ['All']..addAll(categoryLabels);
  static final extendedCategoryTokens = <String>[null]..addAll(categoryTokens);

  _KeywordSearchModel _searchModel;
  TabController _categoryController;
  String _keyword = '';

  _HomePageState() : super(AppRoute.Home);

  void _beginSearch(String keyword) {
    keyword = keyword ?? '';
    if (keyword != _keyword) {
      setState(() {
        _keyword = keyword;
      });
    }
  }

  void _tabSelected(int index) {
    setState(() {
      _currentDisplayIndex = index;
    });
  }

  void initState() {
    super.initState();
    _searchModel = _KeywordSearchModel(_beginSearch);
    _categoryController = TabController(length: extendedCategoryLabels.length, vsync: this);
  }

  Widget _createCurrentDisplay(String categoryToken, String keyword) {
    switch (_currentDisplayIndex) {
      case _galleryIndex:
        return GalleryDisplay(categoryToken, keyword);
      case _feedIndex:
        return FeedDisplay(categoryToken, keyword);
      case _mapIndex:
        return MapDisplay(categoryToken, keyword);
      default:
        return null;
    }
  }

  Widget _createTabContent(String categoryToken) {
    return _createCurrentDisplay(categoryToken, _keyword);
  }

  Tab _buildTab(String category) => Tab(child: Text(category));

  AppBar buildAppBar() {
    return AppBar(
      title: ChangeNotifierProvider.value(value: _searchModel,
          child: _KeywordSearchWidget(appName, _fetchSuggestions)),
      actions: <Widget>[
        ChangeNotifierProvider.value(value: _searchModel,
            child: _SearchTriggerWidget()),
        SizedBox(width: 20),
      ],
      bottom: TabBar(isScrollable: true,
        controller: _categoryController,
        tabs: extendedCategoryLabels.map(_buildTab).toList())
    );
  }

  BottomNavigationBar buildNavBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _currentDisplayIndex,
        onTap: _tabSelected,
        items: <BottomNavigationBarItem>[
          new BottomNavigationBarItem(
            icon: Icon(Icons.panorama),
            title: Text('Snypes'),
          ),
          new BottomNavigationBarItem(
            icon: Icon(Icons.forum),
            title: Text('Feed'),
          ),
          new BottomNavigationBarItem(
              icon: Icon(Icons.place),
              title: Text('Map')
          )
        ]
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return TabBarView(
      controller: _categoryController,
      physics: _currentDisplayIndex != _mapIndex ? BouncingScrollPhysics() : NeverScrollableScrollPhysics(),
      children: extendedCategoryTokens.map(_createTabContent).toList(),
    );
  }

  Future<List<String>> _fetchSuggestions(String pattern) {
    return MediaQueryService.current(context).suggestTags(pattern, 5);
  }
}
