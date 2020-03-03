import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

  AppBar buildAppBar({PreferredSizeWidget bottom}) {
    return AppBar(
      title: Text('Snypix'),
      actions: <Widget>[
        Icon(Icons.search),
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
      children: extendedCategoryTokens.map(_createCurrentDisplay).toList(growable: false),
    );
  }
}

class _GalleryDisplay extends StatelessWidget {
  static final pageSize = 50;
  static final spacing = 4.0;

  final String categoryToken;

  _GalleryDisplay(this.categoryToken) : super(key: ValueKey(categoryToken));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QueryResultMediaInfo>(
      future: MediaQueryService.current(context).listMedia(pageSize, categoryToken),
      builder: (context, snapshot) => snapshot.hasData ?
          _buildGalleryContent(context, snapshot.data) :
          LoadingCircle(),
    );
  }

  Widget _buildGalleryContent(BuildContext context, QueryResultMediaInfo result) {
    if (result.content.isEmpty) {
      return Center(child: _buildNoContent(context));
    }
    final orientation = MediaQuery.of(context).orientation;
    return GridView.count(
        crossAxisCount: (orientation == Orientation.portrait) ? 2 : 3,
        childAspectRatio: 16.0 / 9.0,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        padding: EdgeInsets.all(spacing),
        children: result.content.map(_buildGridTile).toList());

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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GeoPosition>(
      future: GeoLocationService.current(context).readPosition(),
      builder: (context, snapshot) => snapshot.hasData ?
        GoogleMap(
            mapType: MapType.normal,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            initialCameraPosition: CameraPosition(zoom: 15.0, target: LatLng(snapshot.data.latitude, snapshot.data.longitude)))
        : LoadingCircle());
  }
}