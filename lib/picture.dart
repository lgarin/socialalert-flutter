import 'dart:io';
import 'package:exifdart/exifdart.dart';
import 'package:exifdart/exifdart_io.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/service/geolocation.dart';
import 'package:social_alert_app/service/mediaupload.dart';

class LocalPicturePreview extends StatelessWidget {
  final Widget child;
  final File image;
  final Color backgroundColor;
  final bool fullScreen;
  final VoidCallback fullScreenSwitch;
  final int childHeight;

  LocalPicturePreview({Key key, this.child, this.image, this.backgroundColor, this.fullScreen, this.fullScreenSwitch, this.childHeight}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    if (fullScreen) {
      return _buildImageContainer(context);
    }

    return ListView(
      children: <Widget>[
        _buildImageContainer(context),
        Transform.translate(
            offset: Offset(0, -20),
            child: _buildChildContainer(context)
        )
      ],
    );
  }

  Container _buildChildContainer(BuildContext context) {
    return Container(
      height: childHeight.ceilToDouble(),
      decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))
      ),
      padding: EdgeInsets.only(left: 20, right: 20, top: 20),
      child: child,
    );
  }

  Container _buildImageContainer(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
        color: Colors.black,
        child: GestureDetector(
            onTap: fullScreenSwitch,
            child: Hero(tag: image.path, child: fullScreen ?
              Image.file(image, fit: BoxFit.contain, height: screenHeight) :
              Image.file(image, fit: BoxFit.cover, height: childHeight != null ? screenHeight - childHeight : screenHeight / 3)
            )
        )
    );
  }
}

class LocalPictureInfoPage extends StatefulWidget {

  final MediaUploadTask upload;

  LocalPictureInfoPage(this.upload);

  @override
  _LocalPictureInfoPageState createState() => _LocalPictureInfoPageState();
}

class _ExifData {
  static final oneMega = 1000 * 1000;
  static final numberFormat = new NumberFormat('0.0');
  final int mediaHeight;
  final int mediaWidth;
  final String cameraMaker;
  final String cameraModel;

  _ExifData({this.mediaHeight, this.mediaWidth, this.cameraMaker, this.cameraModel});

  String get format => numberFormat.format(mediaHeight * mediaWidth / oneMega) + 'MP - $mediaWidth x $mediaHeight';

  String get camera => cameraMaker + " " + cameraModel;
}

class _LocalPictureInfoPageState extends State<LocalPictureInfoPage> {
  static const backgroundColor = Color.fromARGB(255, 240, 240, 240);
  bool _fullImage = false;

  void _switchFullImage() {
    setState(() {
      _fullImage = !_fullImage;
    });
  }

  Future<_ExifData> _buildExifData(BuildContext context) async {
    Map<String, dynamic> tags = await readExif(FileReader(widget.upload.file));
    return _ExifData(
      mediaHeight: tags['ImageHeight'] as int,
      mediaWidth: tags['ImageWidth'] as int,
      cameraMaker: tags['Make'] as String,
      cameraModel: tags['Model'] as String,
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
              image: widget.upload.file,
              fullScreen: _fullImage,
              fullScreenSwitch: _switchFullImage,
              childHeight: 460,
              child: Consumer<_ExifData>(
                builder: (context, exifData, _) => _buildInfoPanel(context, exifData)
              )
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(title: Text(widget.upload.title ?? 'New Snype', overflow: TextOverflow.ellipsis));
  }
  
  Widget _buildInfoPanel(BuildContext context, _ExifData exifData) {
    return PictureInfoPanel(timestamp: widget.upload.timestamp,
      location: widget.upload.hasPosition ? widget.upload.location : null,
      format: exifData?.format,
      camera: exifData?.camera,
    );
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
    if (format != null && camera != null) {
      children.addAll([
        SizedBox(height: 10),
        Row(children: <Widget>[
          Icon(Icons.image),
          SizedBox(width: 5),
          Text(format)
        ]),
        SizedBox(height: 5),
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
          initialCameraPosition: CameraPosition(zoom: 15.0, target: position)
    );
  }
}