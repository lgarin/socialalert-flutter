import 'dart:io';
import 'package:flutter/material.dart';
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

class _PictureInfoPageState extends State<PictureInfoPage> {
  static const backgroundColor = Color.fromARGB(255, 240, 240, 240);
  bool _fullImage = false;

  void _switchFullImage() {
    setState(() {
      _fullImage = !_fullImage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            backgroundColor: backgroundColor,
            appBar: _buildAppBar(context),
            body: PicturePreview(
                backgroundColor: backgroundColor,
                image: widget.upload.file,
                fullScreen: _fullImage,
                fullScreenSwitch: _switchFullImage,
                child: Container(height: 400,))
        );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
        title: Text(widget.upload.title ?? 'New Snype'),
    );
  }
}