import 'dart:ui';

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

class _MediaCluster extends Clusterable {

  final List<MediaInfo> _items;

  _MediaCluster({int clusterId, double latitude, double longitude}) : _items = [], super(
    latitude: latitude,
    longitude: longitude,
    isCluster: true,
    clusterId: clusterId,
    markerId: clusterId.toString()
  );

  _MediaCluster.single(MediaInfo media) : _items = [media], super(
    latitude: media.latitude,
    longitude: media.longitude,
    isCluster: false,
    markerId: media.mediaUri
  );

  void addMedia(MediaInfo media) {
    if (isCluster) {
      _items.add(media);
    }
  }

  int get size => _items.length;

  Iterable<MediaInfo> get items => _items.reversed;
  MediaInfo get singleItem => !isCluster ? _items.first : null;
}

class _MapDisplayState extends State<MapDisplay> {
  static const thumbnailTileWidth = 160.0;
  static const thumbnailTileHeight = 90.0;
  static const maxThumbnailCount = 100;

  static const minZoomLevel = 10.0;
  static const maxZoomLevel = 20.0;
  static const defaultZoomLevel = 15.0;

  static const clusterMarkerRadius = 80.0;

  static CameraPosition _lastPosition;
  final _listController = ScrollController();
  LatLngBounds _lastBounds;
  List<MediaInfo> _mediaList = [];
  GoogleMapController _mapController;
  List<_MediaCluster> _clusterList = [];

  Widget _buildInitialContent(BuildContext context, AsyncSnapshot<GeoPosition> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return LoadingCircle();
    } else if (snapshot.hasData) {
      _lastPosition = CameraPosition(zoom: defaultZoomLevel, target: LatLng(snapshot.data.latitude, snapshot.data.longitude));
      return _buildContent();
    } else {
      _lastPosition = CameraPosition(zoom: defaultZoomLevel, target: LatLng(0.0, 0.0));
      showSimpleDialog(context, 'No GPS signal', 'Current position not available');
      return _buildContent();
    }
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment:CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: _buildMarkersAndMap()),
        _buildThumbnailList(),
      ],
    );
  }

  Widget _buildMarkersAndMap() {
    return FutureBuilder<Iterable<Marker>>(
      future: Future.wait(_clusterList.map(_toClusterMarker)),
      initialData: {},
      builder: _buildMap,
    );
  }

  Widget _buildMap(BuildContext context, AsyncSnapshot<Iterable<Marker>> snapshot) {
    return GoogleMap(
      markers: snapshot.data.toSet(),
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

  Widget _buildThumbnailList() {
    if (_mediaList.isEmpty) {
      return SizedBox(height: 0);
    }
    return Container(
        height: thumbnailTileHeight,
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

    return Container(width: thumbnailTileWidth,
        padding: EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
        color: Colors.grey.shade800,
        child: MediaThumbnailTile(media: media, onTapCallback: _onThumbnailTap, onDoubleTapCallback: _onThumbnailSelection,));
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
      _mediaList.remove(media);
      _mediaList.insert(0, media);
      _listController.jumpTo(0.0);
    });
  }

  void _onClusterSelection(_MediaCluster cluster) {
    setState(() {
      for (final media in cluster.items) {
        _mediaList.remove(media);
        _mediaList.insert(0, media);
      }
      _listController.jumpTo(0.0);
    });
  }

  Marker _toMediaMarker(MediaInfo media) {
    return Marker(markerId: MarkerId(media.mediaUri),
        position: LatLng(media.latitude, media.longitude),
        onTap: () => _onMarkerSelection(media),
        infoWindow: InfoWindow(title: media.title, onTap: () => _onThumbnailSelection(media)));
  }

  Future<Marker> _toClusterMarker(_MediaCluster cluster) async {
    if (!cluster.isCluster) {
      return _toMediaMarker(cluster.items.first);
    }
    return Marker(markerId: MarkerId(cluster.markerId),
      position: LatLng(cluster.latitude, cluster.longitude),
      icon: await _getClusterMarker(cluster.size, Colors.redAccent, Colors.white, clusterMarkerRadius / 2),
      onTap: () => _onClusterSelection(cluster));
  }

  void _setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    if (_lastPosition != null) {
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
    } else if (bounds.northeast == LatLng(0.0, 0.0) && bounds.southwest == LatLng(0.0, 0.0)) {
      // is it a bug?
      return;
    }

    final zoomLevel = await _mapController.getZoomLevel();
    try {
      final result = await _queryMatchingMedia(bounds);
      final clusters = _buildClusters(result.content, bounds, zoomLevel);

      setState(() {
        _clusterList = clusters;
        _lastBounds = bounds;
        _mediaList = result.content;
      });
    } catch (e) {
      print(e);
      await showSimpleDialog(context, "Query failed", e.toString());
    }
  }

  Future<MediaInfoPage> _queryMatchingMedia(LatLngBounds bounds) async {
    return await MediaQueryService.current(context).listMedia(
        widget.categoryToken, widget.keywords, PagingParameter(pageSize: maxThumbnailCount, pageNumber: 0), bounds: bounds);
  }

  List<_MediaCluster> _buildClusters(List<MediaInfo> items, LatLngBounds bounds, double zoomLevel) {
    if (items.isEmpty) {
      return [];
    }

    final clusterBuilder = Fluster<_MediaCluster>(
        minZoom: minZoomLevel.floor(),
        maxZoom: maxZoomLevel.ceil(),
        radius: (MediaQuery.of(context).devicePixelRatio * clusterMarkerRadius).toInt(),
        extent: 2048,
        nodeSize: 64,
        points: items.map((e) => _MediaCluster.single(e)).toList(growable: false),
        createCluster: (BaseCluster cluster, double longitude, double latitude) {
          return _MediaCluster(
              clusterId: cluster.id,
              latitude: latitude,
              longitude: longitude);
        });
    final result = clusterBuilder.clusters([bounds.southwest.longitude, bounds.southwest.latitude, bounds.northeast.longitude, bounds.northeast.latitude], zoomLevel.round());
    for (final cluster in result.where((element) => element.isCluster)) {
      for (final child in clusterBuilder.points(cluster.clusterId)) {
        cluster.addMedia(child.singleItem);
      }
    }
    return result;
  }

  void _onMapMoving(CameraPosition position) {
    _lastPosition = position;
  }

  static Future<BitmapDescriptor> _getClusterMarker(int clusterSize, Color clusterColor, Color textColor, double radius) async {
    final pictureRecorder = PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint();

    final textSpan = TextSpan(text: clusterSize.toString(),
      style: TextStyle(fontSize: radius - 5, fontWeight: FontWeight.bold, color: textColor),
    );
    final textPainter = TextPainter(textDirection: TextDirection.ltr, text: textSpan);

    canvas.drawCircle(Offset(radius, radius), radius, paint..color = clusterColor);
    textPainter.layout();
    textPainter.paint(canvas,
      Offset(radius - textPainter.width / 2, radius - textPainter.height / 2),
    );

    final image = await pictureRecorder.endRecording().toImage(
      radius.toInt() * 2,
      radius.toInt() * 2,
    );

    final data = await image.toByteData(format: ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data.buffer.asUint8List());
  }

}
