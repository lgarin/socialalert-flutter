import 'dart:io';
import 'package:exifdart/exifdart.dart';
import 'package:exifdart/exifdart_io.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/service/upload.dart';

class PicturePreview extends StatelessWidget {
  final Widget child;
  final File image;
  final Color backgroundColor;
  final bool fullScreen;
  final VoidCallback fullScreenSwitch;

  PicturePreview({Key key, this.child, this.image, this.backgroundColor, this.fullScreen, this.fullScreenSwitch}) : super(key: key);

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
            child: fullScreen ?
            Image.file(image, fit: BoxFit.contain, height: screenHeight) :
            Image.file(image, fit: BoxFit.cover, height: screenHeight / 3)
        )
    );
  }
}

class PictureInfoPage extends StatefulWidget {

  final UploadTask upload;

  PictureInfoPage(this.upload);

  @override
  _PictureInfoPageState createState() => _PictureInfoPageState();
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

class _PictureInfoPageState extends State<PictureInfoPage> {
  static const backgroundColor = Color.fromARGB(255, 240, 240, 240);
  bool _fullImage = false;

  void _switchFullImage() {
    setState(() {
      _fullImage = !_fullImage;
    });
  }

  Future<_ExifData> _buildExifData(BuildContext context) async {
    Map<String, dynamic> tags = await readExif(FileReader(widget.upload.file));
    print(tags);
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
    return PicturePreview(
              backgroundColor: backgroundColor,
              image: widget.upload.file,
              fullScreen: _fullImage,
              fullScreenSwitch: _switchFullImage,
              child: Consumer<_ExifData>(
                builder: (context, exifData, _) => _buildInfoPanel(context, exifData)
              )
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(title: Text(widget.upload.title ?? 'New Snype'));
  }
  
  Widget _buildInfoPanel(BuildContext context, _ExifData exifData) {
    final children = List<Widget>();
    children.add(
      Row(children: <Widget>[
        Icon(Icons.access_time),
        SizedBox(width: 5),
        Text(DateFormat('EEE, d MMM yyyy - HH:mm').format(widget.upload.timestamp))
      ]),
    );
    if (widget.upload.hasPosition) {
      children.addAll([
        SizedBox(height: 10),
        Row(children: <Widget>[
          Icon(Icons.map),
          SizedBox(width: 5),
          Text('Location')
        ]),
        SizedBox(height: 5),
        _buildMap(),
        SizedBox(height: 5),
        Row(children: <Widget>[
          Icon(Icons.place),
          SizedBox(width: 5),
          Text(widget.upload.location.format())
        ])
      ]);
    }
    if (exifData != null) {
      children.addAll([
        SizedBox(height: 10),
        Row(children: <Widget>[
          Icon(Icons.image),
          SizedBox(width: 5),
          Text(exifData.format)
        ]),
        SizedBox(height: 5),
        Row(children: <Widget>[
          Icon(Icons.camera),
          SizedBox(width: 5),
          Text(exifData.camera)
        ])
      ]);
    }
    return Column(children: children);
  }

  Container _buildMap() {
    return Container(height: 150,
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey)),
          child: GoogleMap(
            mapType: MapType.normal,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            markers: {Marker(markerId: MarkerId(widget.upload.id), position: LatLng(widget.upload.latitude, widget.upload.longitude))},
            initialCameraPosition: CameraPosition(zoom: 15.0, target: LatLng(widget.upload.latitude, widget.upload.longitude)))
      );
  }
}