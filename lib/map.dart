import 'dart:async';
import 'dart:math';

import 'package:fluster/fluster.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/service/geolocation.dart';
import 'package:social_alert_app/service/mediamodel.dart';
import 'package:social_alert_app/service/mediaquery.dart';
import 'package:social_alert_app/thumbnail.dart';

class MapDisplay extends StatefulWidget {

  final String categoryToken;
  final String keywords;

  MapDisplay(this.categoryToken, this.keywords) : super(key: ValueKey('$categoryToken/$keywords'));

  @override
  _MapDisplayState createState() => _MapDisplayState();
}

abstract class _Cluster<T extends _Cluster<T>> extends Clusterable {

  static const maxDisplayCount = 99;

  _Cluster(BaseCluster cluster, LatLng position) :
      super(
        latitude: position.latitude,
        longitude: position.longitude,
        pointsSize: cluster.pointsSize,
        isCluster: true,
        clusterId: cluster.id,
        markerId: cluster.id.toString()
      );

  _Cluster.single({@required String markerId, @required double latitude, @required double longitude, @required int itemCount}) :
      super(
          latitude: latitude,
          longitude: longitude,
          pointsSize: itemCount,
          isCluster: false,
          markerId: markerId
      );

  void addChild(T child);

  String get text => pointsSize >= maxDisplayCount ? '$maxDisplayCount+' : pointsSize.toString();
}

class _MediaCluster extends _Cluster<_MediaCluster> {

  final List<MediaInfo> _items;

  _MediaCluster(BaseCluster cluster, LatLng position)
      : _items = [],
        super(cluster, position);

  _MediaCluster.single(MediaInfo media)
      : _items = [media],
        super.single(
          latitude: media.latitude,
          longitude: media.longitude,
          markerId: media.mediaUri,
          itemCount: 1
        );

  void addChild(_MediaCluster child) {
    _items.addAll(child._items);
  }

  Iterable<MediaInfo> get items => _items;
  MediaInfo get singleItem => !isCluster ? _items.first : null;
}

class _StatisticCluster extends _Cluster<_StatisticCluster> {

  double _minLat;
  double _maxLat;
  double _minLon;
  double _maxLon;

  _StatisticCluster(BaseCluster cluster, LatLng position) :
        super(cluster, position);

  _StatisticCluster.single(GeoStatistic item) :
        _minLat = item.minLat,
        _maxLat = item.maxLat,
        _minLon = item.minLon,
        _maxLon = item.maxLon,
        super.single(
          latitude: item.centerLat,
          longitude: item.centerLon,
          itemCount: item.count,
          markerId: '${item.minLat}/${item.maxLat}/${item.minLon}/${item.maxLon}'
        );

  void addChild(_StatisticCluster item) {
    if (_minLat == null || _maxLat == null || _minLon == null || _maxLon == null) {
      _minLat = item._minLat;
      _maxLat = item._maxLat;
      _minLon = item._minLon;
      _maxLon = item._maxLon;
    } else {
      _minLat = min(_minLat, item._minLat);
      _maxLat = max(_maxLat, item._maxLat);
      _minLon = min(_minLon, item._minLon);
      _maxLon = max(_maxLon, item._maxLon);
    }
  }

  LatLngBounds get bounds => LatLngBounds(southwest: LatLng(_minLat, _minLon), northeast: LatLng(_maxLat, _maxLon));
}

class _MapDisplayState extends State<MapDisplay> {
  static const thumbnailTileWidth = 160.0;
  static const thumbnailTileHeight = 90.0;
  static const maxThumbnailCount = 100;
  static const thumbnailInset = 2.0;

  static const minZoomLevel = 5.0;
  static const maxZoomLevel = 20.0;
  static const defaultZoomLevel = 15.0;

  static const clusterMarkerRadius = 80.0;

  static CameraPosition _lastPosition;
  final _listController = ScrollController();
  LatLngBounds _lastBounds;
  List<MediaInfo> _fullMediaList = [];
  List<MediaInfo> _mediaList = [];
  GoogleMapController _mapController;
  List<_Cluster> _clusterList = [];
  StreamSubscription<GeoPosition> postionSubscription;

  @override
  void initState() {
    super.initState();
    postionSubscription = GeoLocationService.current(context).positionStream.listen((event) {
      if (_mapController != null) {
        _mapController.animateCamera(CameraUpdate.newLatLng(LatLng(event.latitude, event.longitude)));
      }
    });
    GeoLocationService.current(context).readPosition(100.0);
  }

  @override
  void dispose() {
    postionSubscription.cancel();
    super.dispose();
  }

  Widget _buildInitialContent(BuildContext context, AsyncSnapshot<GeoPosition> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return LoadingCircle();
    } else if (snapshot.hasData) {
      _lastPosition = CameraPosition(zoom: defaultZoomLevel, target: LatLng(snapshot.data.latitude, snapshot.data.longitude));
      return _buildContent();
    } else {
      _lastPosition = CameraPosition(zoom: minZoomLevel, target: LatLng(46.8182, 8.2275));
      return _buildContent();
    }
  }

  Widget _buildContent() {
    final landscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final children = <Widget>[
      Expanded(child: _buildMarkersAndMap()),
      _buildThumbnailList(landscape),
    ];

    if (landscape) {
      return Row(children: children);
    } else {
      return Column(children: children);
    }
  }

  Widget _buildMarkersAndMap() {
    return FutureBuilder<Iterable<Marker>>(
      future: Future.wait(_clusterList.map(_toClusterMarker)),
      initialData: [],
      builder: _buildMap,
    );
  }

  Widget _buildMap(BuildContext context, AsyncSnapshot<Iterable<Marker>> snapshot) {
    return GoogleMap(
      markers: snapshot.requireData.toSet(),
      onMapCreated: _setMapController,
      minMaxZoomPreference: MinMaxZoomPreference(minZoomLevel, maxZoomLevel),
      mapType: MapType.normal,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      compassEnabled: false,
      initialCameraPosition: _lastPosition,
      onCameraMove: _onMapMoving,
      onCameraIdle: _onMapMoved,
    );
  }

  Widget _buildThumbnailList(bool landscape) {
    if (_mediaList.isEmpty) {
      return SizedBox(height: 0, width: 0);
    }
    return Container(
        height: !landscape ? thumbnailTileHeight : null,
        width: landscape ? thumbnailTileWidth : null,
        child: ListView.builder(
          scrollDirection: landscape ? Axis.vertical : Axis.horizontal,
          controller: _listController,
          itemCount: _mediaList.length,
          itemBuilder: _toThumbnail,
        )
    );
  }

  Widget _toThumbnail(BuildContext context, int index) {
    final media = _mediaList[index];
    final landscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Container(width: thumbnailTileWidth, height: thumbnailTileHeight,
        padding: EdgeInsets.symmetric(horizontal: thumbnailInset * (landscape ? 2 : 1), vertical: thumbnailInset * (landscape ? 1 : 2)),
        color: Colors.grey.shade800,
        child: MediaThumbnailTile(media: media, onTapCallback: _onThumbnailTap, onLongPressCallback: _onThumbnailSelection,));
  }

  void _onThumbnailTap(MediaInfo media) {
    _mapController.animateCamera(CameraUpdate.newLatLng(LatLng(media.latitude, media.longitude)));
    if (_clusterList.any((element) => element.markerId == media.mediaUri)) {
      _mapController.showMarkerInfoWindow(MarkerId(media.mediaUri));
    }
  }

  void _onThumbnailSelection(MediaInfo media) {
    Navigator.of(context).pushNamed(AppRoute.RemotePictureDetail, arguments: media);
  }

  void _onMarkerSelection(MediaInfo media) {
    setState(() {
      _mediaList = [media];
      _listController.jumpTo(0.0);
    });
  }

  void _onClusterSelection(_MediaCluster cluster) {
    setState(() {
      _mediaList = cluster.items.toList(growable: false);
      _listController.jumpTo(0.0);
    });
  }

  void _onStatisticSelection(_StatisticCluster cluster) async {
    final result = await _queryMatchingMedia(cluster.bounds);
    setState(() {
      _mediaList = result.content;
      _listController.jumpTo(0.0);
    });
  }

  Future<Marker> _toMediaSingleMarker(MediaInfo media) async {
    return Marker(markerId: MarkerId(media.mediaUri),
        position: LatLng(media.latitude, media.longitude),
        icon: await drawMapLocationMarker(clusterMarkerRadius / 2),
        consumeTapEvents: true,
        onTap: () => _onMarkerSelection(media),
        infoWindow: InfoWindow(title: media.title, onTap: () => _onThumbnailSelection(media)));
  }

  Future<Marker> _toMediaClusterMarker(_MediaCluster cluster) async {
    return Marker(markerId: MarkerId(cluster.markerId),
        position: LatLng(cluster.latitude, cluster.longitude),
        icon: await drawMapClusterMarker(cluster.text, clusterMarkerRadius / 2),
        consumeTapEvents: true,
        onTap: () => _onClusterSelection(cluster));
  }

  Future<Marker> _toStatisticClusterMarker(_StatisticCluster cluster) async {
    return Marker(markerId: MarkerId(cluster.markerId),
        position: LatLng(cluster.latitude, cluster.longitude),
        icon: await drawMapClusterMarker(cluster.text, clusterMarkerRadius / 2),
        consumeTapEvents: true,
        onTap: () => _onStatisticSelection(cluster));
  }

  Future<Marker> _toClusterMarker(_Cluster cluster) async {
    if (cluster is _MediaCluster) {
      return cluster.isCluster ? _toMediaClusterMarker(cluster) : _toMediaSingleMarker(cluster.items.first);
    } else if (cluster is _StatisticCluster) {
      return _toStatisticClusterMarker(cluster);
    } else {
      throw 'Unsupported cluster type';
    }
  }

  void _setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<GeoPosition> _readLastKnownPosition() async {
    final position = await GeoLocationService.current(context).readLastKnownPosition();
    if (position == null) {
      await showSimpleDialog(context, 'No GPS signal', 'Current position not available');
    }
    return position;
  }

  @override
  Widget build(BuildContext context) {
    if (_lastPosition != null) {
      return _buildContent();
    }
    return FutureBuilder<GeoPosition>(
        future: _readLastKnownPosition(),
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
      setState(() {
        _mediaList = _fullMediaList;
      });
      return;
    } else if (bounds.northeast == LatLng(0.0, 0.0) && bounds.southwest == LatLng(0.0, 0.0)) {
      // is it a bug?
      setState(() {
        _mediaList = _fullMediaList;
      });
      return;
    }

    final zoomLevel = await _mapController.getZoomLevel();
    try {
      final result = await _queryMatchingMedia(bounds);
      List<Clusterable> clusters;
      if (result.nextPage != null) {
        final statistic = await MediaQueryService.current(context).mapMediaCount(widget.categoryToken, widget.keywords, bounds);
        clusters = _buildStatisticClusters(statistic, bounds, zoomLevel);
      } else {
        clusters = _buildMediaClusters(result.content, bounds, zoomLevel);
      }

      setState(() {
        _fullMediaList = result.content;
        _clusterList = clusters;
        _lastBounds = bounds;
        _mediaList = result.content;
      });
    } catch (e) {
      print(e);
      await showSimpleDialog(context, "Query failed", e.toString());
    }
  }

  Future<MediaInfoPage> _queryMatchingMedia(LatLngBounds bounds) {
    return MediaQueryService.current(context).listMedia(
        widget.categoryToken, widget.keywords, PagingParameter(pageSize: maxThumbnailCount, pageNumber: 0), bounds: bounds);
  }

  List<T> _addClusterChildren<T extends _Cluster<T>>(Fluster<T> clusterBuilder, LatLngBounds bounds, double zoomLevel) {
    final boundingBox = [bounds.southwest.longitude, bounds.southwest.latitude, bounds.northeast.longitude, bounds.northeast.latitude];
    final result = clusterBuilder.clusters(boundingBox, zoomLevel.round());
    for (final cluster in result.where((element) => element.isCluster)) {
      for (final child in clusterBuilder.points(cluster.clusterId)) {
        cluster.addChild(child);
      }
    }
    return result;
  }

  Fluster<T> _createClusterBuilder<T extends _Cluster<T>, E>(
      Iterable<E> items,
      T Function(E) singleFactory,
      T Function(BaseCluster, LatLng) clusterFactory) {
    return Fluster<T>(
        minZoom: minZoomLevel.floor(),
        maxZoom: maxZoomLevel.ceil(),
        radius: (MediaQuery.of(context).devicePixelRatio * clusterMarkerRadius).toInt(),
        extent: 2048,
        nodeSize: 64,
        points: items.map(singleFactory).toList(growable: false),
        createCluster: (BaseCluster cluster, double lon, double lat) => clusterFactory(cluster, LatLng(lat, lon))
    );
  }

  List<_MediaCluster> _buildMediaClusters(List<MediaInfo> items, LatLngBounds bounds, double zoomLevel) {
    if (items.isEmpty) {
      return [];
    }

    final builder = _createClusterBuilder(items,
      (e) => _MediaCluster.single(e),
      (cluster, position) => _MediaCluster(cluster, position)
    );
    return _addClusterChildren(builder, bounds, zoomLevel);
  }

  List<_StatisticCluster> _buildStatisticClusters(List<GeoStatistic> items, LatLngBounds bounds, double zoomLevel) {
    if (items.isEmpty) {
      return [];
    }

    final builder = _createClusterBuilder(items,
      (e) => _StatisticCluster.single(e),
      (cluster, position) => _StatisticCluster(cluster, position)
    );
    return _addClusterChildren(builder, bounds, zoomLevel);
  }

  void _onMapMoving(CameraPosition position) {
    _lastPosition = position;
  }
}
