import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:social_alert_app/base.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/service/configuration.dart';
import 'package:social_alert_app/service/geolocation.dart';
import 'package:social_alert_app/service/mediaquery.dart';

class HomePage extends StatefulWidget {

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends BasePageState<HomePage> with SingleTickerProviderStateMixin {
  int _currentDisplayIndex = 0;
  static final extendedCategoryLabels = ['All']..addAll(categoryLabels);
  static final extendedCategoryTokens = <String>[null]..addAll(categoryTokens);

  bool _searching = false;

  TabController _categoryController;

  _HomePageState() : super(AppRoute.Home);

  void _tabSelected(int index) {
    setState(() {
      _currentDisplayIndex = index;
    });
  }

  void initState() {
    super.initState();
    _categoryController = TabController(length: extendedCategoryLabels.length, vsync: this);
  }

  Widget _createCurrentDisplay(String categoryToken) {
    switch (_currentDisplayIndex) {
      case 0:
        return _GalleryDisplay(categoryToken);
      case 1:
        return _FeedDisplay(categoryToken);
      case 2:
        return _MapDisplay(categoryToken);
      default:
        return null;
    }
  }


  Tab _buildTab(String category) => Tab(child: Text(category));

  void _switchSearching() {
    setState(() {
      _searching = !_searching;
    });
  }

  void _beginSearch(String keyword) {
    _switchSearching();
    if (keyword.isNotEmpty) {
      print(keyword);
    }
  }

  AppBar buildAppBar({PreferredSizeWidget bottom}) {
    return AppBar(
      title: _searching ? TextField(
        onSubmitted: _beginSearch,
        autofocus: true,
        textInputAction: TextInputAction.search,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
            filled: false,
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
            hintText: "Enter keyword here",
            prefixIcon: Icon(Icons.search, color: Colors.white)),
      ) : Text('Snypix'),
      actions: <Widget>[
        IconButton(
          icon: Icon(_searching ? Icons.cancel : Icons.search),
          onPressed: _switchSearching,
        ),
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
      children: extendedCategoryTokens.map(_createCurrentDisplay).toList(),
    );
  }
}

class _GalleryDisplay extends StatefulWidget {

  final String categoryToken;

  _GalleryDisplay(this.categoryToken) : super(key: ValueKey(categoryToken));

  @override
  __GalleryDisplayState createState() => __GalleryDisplayState();
}

class __GalleryDisplayState extends State<_GalleryDisplay> {
  static final pageSize = 50;
  static final spacing = 4.0;

  List<MediaInfo> _data;
  PagingParameter _nextPage = PagingParameter(pageSize: pageSize, pageNumber: 0);
  RefreshController _refreshController = RefreshController(initialRefresh: true);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<QueryResultMediaInfo> _loadNextPage() {
    return MediaQueryService.current(context).listMedia(widget.categoryToken, _nextPage);
  }

  void _onRefresh() async{
    try {
      _nextPage = PagingParameter(pageSize: pageSize, pageNumber: 0);
      final result = await _loadNextPage();
      _data = null;
      _setData(result);
      _refreshController.refreshCompleted();
      if (_nextPage == null) {
        _refreshController.loadNoData();
      } else {
        _refreshController.loadComplete();
      }
    } catch (e) {
      _refreshController.refreshFailed();
      await showSimpleDialog(context, "Refresh failed", e.toString());
    }
    _refreshWidget();
  }

  void _onLoading() async {
    try {
      final result = await _loadNextPage();
      _setData(result);
      if (_nextPage == null) {
        _refreshController.loadNoData();
      } else {
        _refreshController.loadComplete();
      }
    } catch (e) {
      _refreshController.loadFailed();
      await showSimpleDialog(context, "Load failed", e.toString());
    }
    _refreshWidget();
  }

  List<MediaInfo> _createNewList(List<MediaInfo> a, List<MediaInfo> b) {
    final result = List<MediaInfo>(a.length + b.length);
    List.copyRange(result, 0, a);
    List.copyRange(result, a.length, b);
    return result;
  }

  void _setData(QueryResultMediaInfo result) {
    if (_data == null) {
      _data = result.content;
    } else {
      _data = _createNewList(_data, result.content);
    }
    _nextPage = result.nextPage;
  }

  void _refreshWidget() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
        enablePullDown: true,
        enablePullUp: true,
        controller: _refreshController,
        onLoading: _onLoading,
        onRefresh: _onRefresh,
        header: WaterDropMaterialHeader(),
        footer: CustomFooter(
            loadStyle: LoadStyle.ShowWhenLoading,
            builder: _buildGalleryFooter
        ),
        child: _buildGalleryContent(context));
  }

  Widget _buildGalleryFooter(BuildContext context, LoadStatus mode) {
    if (mode == LoadStatus.loading) {
      return Align(
          alignment: Alignment.bottomCenter,
          child: RefreshProgressIndicator(
            backgroundColor: Theme.of(context).primaryColor,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ));
    }
    return SizedBox(height: 0, width: 0,);
  }

  Widget _buildGalleryContent(BuildContext context) {
    if (_data == null) {
      return SizedBox(height: 0, width: 0,);
    }
    if (_data.isEmpty) {
      return Center(child: _buildNoContent(context));
    }

    final orientation = MediaQuery.of(context).orientation;
    return GridView.count(
            crossAxisCount: (orientation == Orientation.portrait) ? 2 : 3,
            childAspectRatio: 16.0 / 9.0,
            mainAxisSpacing: __GalleryDisplayState.spacing,
            crossAxisSpacing: __GalleryDisplayState.spacing,
            padding: EdgeInsets.all(__GalleryDisplayState.spacing),
            children: _data.map(_buildGridTile).toList()
    );
  }

  Widget _buildGridTile(MediaInfo media) {
    return GestureDetector(
        child: GridTile(
          child: Hero(
              tag: media.mediaUri,
              child: Image.network(MediaQueryService.toThumbnailUrl(media), fit: BoxFit.cover),
            ),
          footer: _buildTileFooter(media)
        ),
    );
  }

  GridTileBar _buildTileFooter(MediaInfo media) {
    return GridTileBar(
      backgroundColor: Colors.white54,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 4,),
            Text(media.title, style: TextStyle(fontSize: 14, color: Colors.black)),
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

class _MapDisplay extends StatelessWidget {

  final String categoryToken;

  _MapDisplay(this.categoryToken) : super(key: ValueKey(categoryToken));

  Widget _buildAsyncMap(BuildContext context, AsyncSnapshot<GeoPosition> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return LoadingCircle();
    } else if (snapshot.hasData) {
      return GoogleMap(
          mapType: MapType.normal,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          initialCameraPosition: CameraPosition(zoom: 15.0, target: LatLng(snapshot.data.latitude, snapshot.data.longitude)));
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GeoPosition>(
      future: GeoLocationService.current(context).readPosition(),
      builder: _buildAsyncMap);
  }
}