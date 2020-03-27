
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

class _MapDisplayState extends State<MapDisplay> {
  static const thumbnailTileWidth = 160.0;
  static const thumbnailTileHeight = 90.0;
  static const maxThumbnailCount = 100;

  static const minZoomLevel = 10.0;
  static const maxZoomLevel = 20.0;
  static const defaultZoomLevel = 15.0;

  static CameraPosition _lastPosition;
  final _listController = ScrollController();
  LatLngBounds _lastBounds;
  List<MediaInfo> _mediaList = [];
  GoogleMapController _mapController;

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
        Expanded(child: _buildMap()),
        _buildThumbnailList(),
      ],
    );
  }

  GoogleMap _buildMap() {
    return GoogleMap(
      markers: _mediaList.map(_toMarker).toSet(),
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
    _mapController.showMarkerInfoWindow(MarkerId(media.mediaUri));
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

  Marker _toMarker(MediaInfo media) {
    return Marker(markerId: MarkerId(media.mediaUri),
        position: LatLng(media.latitude, media.longitude),
        onTap: () => _onMarkerSelection(media),
        infoWindow: InfoWindow(title: media.title, onTap: () => _onThumbnailSelection(media)));
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
    }
    try {
      final result = await MediaQueryService.current(context).listMedia(
          widget.categoryToken, widget.keywords, PagingParameter(pageSize: maxThumbnailCount, pageNumber: 0), bounds: bounds);
      if (result.nextPage != null) {
        // TODO
        print('switch to statistic mode');
      }
      setState(() {
        _lastBounds = bounds;
        _mediaList = result.content;
      });
    } catch (e) {
      await showSimpleDialog(context, "Query failed", e.toString());
    }
  }

  void _onMapMoving(CameraPosition position) {
    _lastPosition = position;
  }
}
