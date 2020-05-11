import 'dart:io';
import 'package:exifdart/exifdart.dart';
import 'package:exifdart/exifdart_io.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/service/cameradevice.dart';
import 'package:social_alert_app/service/geolocation.dart';
import 'package:social_alert_app/service/mediaupload.dart';

class LocalImage {
  final File file;
  final String title;

  LocalImage({this.file, this.title});

  String get path => file.path;
}

class _LocalPictureDisplay extends StatelessWidget {

  _LocalPictureDisplay({@required this.image, this.preview = false});

  final LocalImage image;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context);
    final constraints = preview ?
      BoxConstraints.tightFor(height: screen.size.height / 2) :
      BoxConstraints.expand(height: screen.size.height);
    return Container(
        color: Colors.black,
        constraints: constraints,
        child: _buildImage(context)
    );
  }

  Widget _buildImage(BuildContext context) {

    return ClipRect(child: PhotoView(
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * (preview ? 2.0 : 8.0),
      initialScale: preview ? PhotoViewComputedScale.covered : PhotoViewComputedScale.contained,
      scaleStateCycle: preview ? (c) => c : defaultScaleStateCycle,
      tightMode: preview,
      onTapUp: preview ? _onTap : null,
      imageProvider: FileImage(image.file),
      heroAttributes: PhotoViewHeroAttributes(tag: image.path),
    ));
  }

  void _onTap(BuildContext context, TapUpDetails details, PhotoViewControllerValue controllerValue) {
    Navigator.of(context).pushNamed(AppRoute.LocalPictureDisplay, arguments: image);
  }
}

class LocalPicturePreview extends StatelessWidget {
  final Widget child;
  final LocalImage image;
  final Color backgroundColor;

  LocalPicturePreview({Key key, @required this.child, @required this.image, this.backgroundColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        _LocalPictureDisplay(image: image, preview: true),
        Transform.translate(
            offset: Offset(0, -20),
            child: _buildChildContainer(context)
        )
      ],
    );
  }

  Container _buildChildContainer(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))
      ),
      padding: EdgeInsets.only(left: 20, right: 20, top: 20),
      child: child,
    );
  }
}

class LocalPictureInfoPage extends StatelessWidget {
  static const defaultTitle = 'New Snype';
  static const backgroundColor = Color.fromARGB(255, 240, 240, 240);
  final MediaUploadTask upload;

  LocalPictureInfoPage(this.upload);

  LocalImage _buildLocalMedia() => LocalImage(file: upload.file, title: upload.title ?? defaultTitle);

  Future<_ExifData> _buildExifData(BuildContext context) async {
    Map<String, dynamic> tags = await readExif(FileReader(upload.file));
    final device = await CameraDeviceService.current(context).device;
    return _ExifData(
      mediaHeight: tags['ImageHeight'] ?? tags['ExifImageHeight'] ?? tags['PixelYDimension'] as int,
      mediaWidth: tags['ImageWidth'] ?? tags['ExifImageWidth'] ?? tags['PixelXDimension'] as int,
      cameraMaker: tags['Make'] as String ?? device.maker,
      cameraModel: tags['Model'] as String ?? device.model,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureProvider(
        create: _buildExifData,
        child: Scaffold(
            backgroundColor: backgroundColor,
            appBar: _buildAppBar(context),
            body: _buildPicturePreview()
        )
    );
  }

  Widget _buildPicturePreview() {
    return LocalPicturePreview(
        backgroundColor: backgroundColor,
        image: _buildLocalMedia(),
        child: Consumer<_ExifData>(
            builder: (context, exifData, _) => _buildInfoPanel(context, exifData)
        )
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(title: Text(upload.title ?? defaultTitle, overflow: TextOverflow.ellipsis));
  }

  Widget _buildInfoPanel(BuildContext context, _ExifData exifData) {
    return PictureInfoPanel(timestamp: upload.timestamp,
      location: upload.hasPosition ? upload.location : null,
      format: exifData?.format,
      camera: upload.camera ?? exifData?.camera,
    );
  }
}

class _ExifData {
  static final oneMega = 1000 * 1000;
  static final numberFormat = new NumberFormat('0.0');
  final int mediaHeight;
  final int mediaWidth;
  final String cameraMaker;
  final String cameraModel;

  _ExifData({this.mediaHeight, this.mediaWidth, this.cameraMaker, this.cameraModel});

  String get format  {
    if (mediaHeight == null || mediaWidth == null) {
      return null;
    }
    return numberFormat.format(mediaHeight * mediaWidth / oneMega) + 'MP - $mediaWidth x $mediaHeight';
  }

  String get camera {
    if (cameraMaker == null || cameraModel == null) {
      return null;
    }
    return cameraMaker + " " + cameraModel;
  }
}

class PictureInfoPanel extends StatelessWidget {

  final DateTime timestamp;
  final GeoLocation location;
  final String format;
  final String camera;

  const PictureInfoPanel({Key key, this.timestamp, this.location, this.format, this.camera}) : super(key: key);

  Widget build(BuildContext context) {
    final children = List<Widget>();
    children.add(
      Row(children: <Widget>[
        Icon(Icons.access_time),
        SizedBox(width: 5),
        Text(DateFormat('EEE, d MMM yyyy - HH:mm').format(timestamp))
      ]),
    );
    if (location != null) {
      children.addAll([
        SizedBox(height: 10),
        Row(children: <Widget>[
          Icon(Icons.map),
          SizedBox(width: 5),
          Text('Location')
        ]),
        SizedBox(height: 5),
        _buildMarkerAndMap(context),
        SizedBox(height: 5),
        Row(children: <Widget>[
          Icon(Icons.place),
          SizedBox(width: 5),
          Text(location.format())
        ])
      ]);
    }
    if (format != null) {
      children.addAll([
        SizedBox(height: 10),
        Row(children: <Widget>[
          Icon(Icons.image),
          SizedBox(width: 5),
          Text(format)
        ])
      ]);
    }
    if (camera != null) {
      children.addAll([
        SizedBox(height: 10),
        Row(children: <Widget>[
          Icon(Icons.camera),
          SizedBox(width: 5),
          Text(camera)
        ])
      ]);
    }
    return Column(children: children);
  }

  Container _buildMarkerAndMap(BuildContext context) {

    return Container(height: 200,
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey)),
        child: FutureBuilder<Set<Marker>>(
          future: _buildMarkers(context),
          builder: _buildMap,
          initialData: {},
        )
    );
  }

  Future<Set<Marker>> _buildMarkers(BuildContext context) async {
    final position = LatLng(location.latitude, location.longitude);
    final icon = await drawMapLocationMarker(40.0);
    return {Marker(icon: icon, markerId: MarkerId(''), position: position)};
  }

  GoogleMap _buildMap(BuildContext context, AsyncSnapshot<Set<Marker>> snapshot) {
    final position = LatLng(location.latitude, location.longitude);
    return GoogleMap(
          mapType: MapType.normal,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          compassEnabled: false,
          markers: snapshot.requireData,
          initialCameraPosition: CameraPosition(zoom: 15.0, target: position),
          zoomGesturesEnabled: false,
          rotateGesturesEnabled: false,
          scrollGesturesEnabled: false,
          tiltGesturesEnabled: false,
    );
  }
}

class LocalImageDisplayPage extends StatelessWidget {

  final LocalImage image;

  LocalImageDisplayPage(this.image);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(image.title, overflow: TextOverflow.ellipsis)),
        body: _LocalPictureDisplay(image: image)
    );
  }
}