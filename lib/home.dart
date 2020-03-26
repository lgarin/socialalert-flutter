import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/base.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/service/configuration.dart';
import 'package:social_alert_app/service/geolocation.dart';
import 'package:social_alert_app/service/mediamodel.dart';
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
        return _GalleryDisplay(categoryToken, keyword);
      case _feedIndex:
        return _FeedDisplay(categoryToken);
      case _mapIndex:
        return _MapDisplay(categoryToken, keyword);
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
        Icon(Icons.more_vert),
        SizedBox(width: 10),
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
            icon: Icon(Icons.create),
            title: Text('Scribes'),
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

class _GalleryDisplay extends StatefulWidget {

  final String categoryToken;
  final String keywords;

  _GalleryDisplay(this.categoryToken, this.keywords) : super(key: ValueKey('$categoryToken/$keywords'));

  @override
  _GalleryDisplayState createState() => _GalleryDisplayState();
}

class _GalleryDisplayState extends BasePagingState<_GalleryDisplay, MediaInfo> {
  static final spacing = 4.0;

  Future<MediaInfoPage> loadNextPage(PagingParameter parameter) {
    return MediaQueryService.current(context).listMedia(widget.categoryToken, widget.keywords, parameter);
  }

  Widget buildContent(BuildContext context, List<MediaInfo> data) {
    if (data.isEmpty) {
      return Center(child: _buildNoContent(context));
    }

    final orientation = MediaQuery.of(context).orientation;
    return GridView.count(
            crossAxisCount: (orientation == Orientation.portrait) ? 2 : 3,
            childAspectRatio: 16.0 / 9.0,
            mainAxisSpacing: _GalleryDisplayState.spacing,
            crossAxisSpacing: _GalleryDisplayState.spacing,
            padding: EdgeInsets.all(_GalleryDisplayState.spacing),
            children: data.map(_buildGridTile).toList()
    );
  }

  Widget _buildGridTile(MediaInfo media) {
    return _MediaThumbnailTile(media: media, onTapCallback: _onGridTileSelection);
  }

  void _onGridTileSelection(MediaInfo media) async {
    final newValue = await Navigator.of(context).pushNamed<MediaDetail>(AppRoute.RemotePictureDetail, arguments: media);
    if (newValue != null) {
      replaceItem((item) => item.mediaUri == media.mediaUri, newValue);
    }
  }

  Column _buildNoContent(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(Icons.panorama, size: 100, color: Colors.grey),
        Text('No content yet', style: Theme
            .of(context)
            .textTheme
            .headline6),
        Text('Be the first to post some media here.')
      ],
    );
  }
}

typedef MediaSelectionCallback = void Function(MediaInfo);

class _MediaThumbnailTile extends StatelessWidget {
  final MediaInfo media;
  final MediaSelectionCallback onTapCallback;
  final MediaSelectionCallback onDoubleTapCallback;

  _MediaThumbnailTile({@required this.media, this.onTapCallback, this.onDoubleTapCallback}) : super(key: ValueKey(media.mediaUri));

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: GridTile(
          child: Hero(
            tag: media.mediaUri,
            child: Image.network(MediaQueryService.toThumbnailUrl(media.mediaUri),
                fit: BoxFit.cover, cacheHeight: thumbnailHeight, cacheWidth: thumbnailWidth),
          ),
          footer: _buildTileFooter(media)
      ),
      onTap: onTapCallback != null ? () => onTapCallback(media) : null,
      onDoubleTap:  onDoubleTapCallback != null ? () => onDoubleTapCallback(media) : null,
    );
  }

  GridTileBar _buildTileFooter(MediaInfo media) {
    return GridTileBar(
        backgroundColor: Colors.white30,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 4,),
            Text(media.title, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: Colors.black)),
            SizedBox(height: 4,),
            Row(
              children: <Widget>[
                Icon(Icons.remove_red_eye, size: 14, color: Colors.black),
                SizedBox(width: 4,),
                Text(media.hitCount.toString(), style: TextStyle(fontSize: 12, color: Colors.black)),
                Spacer(),
                Icon(Icons.thumb_up, size: 14, color: Colors.black),
                SizedBox(width: 4,),
                Text(media.likeCount.toString(), style: TextStyle(fontSize: 12, color: Colors.black)),
                Spacer(),
                Icon(Icons.thumb_down, size: 14, color: Colors.black),
                SizedBox(width: 4,),
                Text(media.dislikeCount.toString(), style: TextStyle(fontSize: 12, color: Colors.black)),
              ],
            )
          ],
        )
    );
  }
}

class _FeedDisplay extends StatelessWidget {

  final String categoryToken;

  _FeedDisplay(this.categoryToken) : super(key: ValueKey(categoryToken));

  @override
  Widget build(BuildContext context) {
    return Center(child: _buildNoContent(context));
  }

  Column _buildNoContent(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(Icons.create, size: 100, color: Colors.grey),
        Text('No content yet', style: Theme
            .of(context)
            .textTheme
            .headline6),
        Text('Be the first to post some comments here.')
      ],
    );
  }
}

class _MapDisplay extends StatefulWidget {

  final String categoryToken;
  final String keywords;

  _MapDisplay(this.categoryToken, this.keywords) : super(key: ValueKey('$categoryToken/$keywords'));

  @override
  _MapDisplayState createState() => _MapDisplayState();
}

class _MapDisplayState extends State<_MapDisplay> {

  final _listController = ScrollController();
  CameraPosition _lastPostion;
  LatLngBounds _lastBounds;
  List<MediaInfo> _mediaList = [];
  GoogleMapController _mapController;

  Widget _buildInitialContent(BuildContext context, AsyncSnapshot<GeoPosition> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return LoadingCircle();
    } else if (snapshot.hasData) {
      _lastPostion = CameraPosition(zoom: 15.0, target: LatLng(snapshot.data.latitude, snapshot.data.longitude));
      return _buildContent();
    } else {
      _lastPostion = CameraPosition(zoom: 15.0, target: LatLng(0.0, 0.0));
      showSimpleDialog(context, 'No GPS signal', 'Current position not available');
      return _buildContent();
    }
  }

  Widget _buildContent() {
    return Column(
        crossAxisAlignment:CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: _buildMap()),
        _buildThumbnailList(),
      ],
    );
  }

  GoogleMap _buildMap() {
    return GoogleMap(
        markers: _mediaList.map(_toMarker).toSet(),
        onMapCreated: _setMapController,
        minMaxZoomPreference: MinMaxZoomPreference(10.0, 20.0),
        mapType: MapType.normal,
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        compassEnabled: false,
        initialCameraPosition: _lastPostion,
        onCameraMove: _onMapMoving,
        onCameraIdle: _onMapMoved,
    );
  }

  Widget _buildThumbnailList() {
    if (_mediaList.isEmpty) {
      return SizedBox(height: 0);
    }
    return Container(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        controller: _listController,
        itemCount: _mediaList.length,
        itemBuilder: _toThumbnail,
      )
    );
  }

  Widget _toThumbnail(BuildContext context, int index) {
    final media = _mediaList[index];
    return Container(width: 160,
        padding: EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
        color: Colors.black,
        child: _MediaThumbnailTile(media: media, onTapCallback: _onThumbnailTap, onDoubleTapCallback: _onThumbnailSelection,));
  }

  void _onThumbnailTap(MediaInfo media) {
    _mapController.animateCamera(CameraUpdate.newLatLng(LatLng(media.latitude, media.longitude)));
  }

  void _onThumbnailSelection(MediaInfo media) {
    Navigator.of(context).pushNamed(AppRoute.RemotePictureDetail, arguments: media);
  }

  Marker _toMarker(MediaInfo media) {
    return Marker(markerId: MarkerId(media.mediaUri), position: LatLng(media.latitude, media.longitude),
        infoWindow: InfoWindow(title: media.title, onTap: () => _onThumbnailSelection(media)));
  }

  void _setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    if (_lastPostion != null) {
      return _buildContent();
    }
    return FutureBuilder<GeoPosition>(
      future: GeoLocationService.current(context).readPosition(),
      builder: _buildInitialContent);
  }

  static bool _areNear(LatLngBounds a, LatLngBounds b) {
    const tolerance = 0.005;
    return (a.southwest.longitude - b.southwest.longitude).abs() < tolerance &&
        (a.southwest.latitude - b.southwest.latitude).abs() < tolerance &&
        (a.northeast.longitude - b.northeast.longitude).abs() < tolerance &&
        (a.northeast.latitude - b.northeast.latitude).abs() < tolerance;
  }

  void _onMapMoved() async {
    final bounds = await _mapController.getVisibleRegion();
    if (_lastBounds != null && _areNear(_lastBounds, bounds)) {
      return;
    }
    try {
      final result = await MediaQueryService.current(context).listMedia(
          widget.categoryToken, widget.keywords, PagingParameter(pageSize: 50, pageNumber: 0), bounds: bounds);
      setState(() {
        _lastBounds = bounds;
        _mediaList = result.content;
      });
    } catch (e) {
      await showSimpleDialog(context, "Query failed", e.toString());
    }
  }

  void _onMapMoving(CameraPosition position) {
    _lastPostion = position;
  }
}