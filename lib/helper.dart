import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:social_alert_app/service/pagemanager.dart';

T showUnexpectedError<T>(BuildContext context, Object error) {
  showSimpleDialog(context, 'Unexpected error', error);
  return null;
}

Future showSimpleDialog(BuildContext context, String title, String message) {
  return showDialog(
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          FlatButton(
              child: Text('Dismiss'),
              onPressed: () {
                Navigator.of(context).pop();
              })
        ],
      );
    },
    context: context,
  );
}

Future<bool> showConfirmDialog(BuildContext context, String title, String message, {String confirmText = 'Confirm', String cancelText = 'Cancel'}) {
  return showDialog<bool>(
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          FlatButton(
              child: Text(confirmText),
              onPressed: () {
                Navigator.of(context).pop(true);
              }),
          FlatButton(
            child: Text(cancelText),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          )
        ],
      );
    },
    context: context);
}

void _showSnackBar(BuildContext context, String message, Color color, SnackBarAction action) {
  var scaffoldState = PageManager.of(context).currentPageState;
  if (scaffoldState != null) {
    scaffoldState.showSnackBar(SnackBar(content: Text(message, style: TextStyle(color: color)), action: action));
  }
}

void showSuccessSnackBar(BuildContext context, String message, {SnackBarAction action}) {
  _showSnackBar(context, message, Colors.green, action);
}

void showWarningSnackBar(BuildContext context, String message, {SnackBarAction action}) {
  _showSnackBar(context, message, Colors.orange, action);
}

void showErrorSnackBar(BuildContext context, String message, {SnackBarAction action}) {
  _showSnackBar(context, message, Colors.red, action);
}

class LoadingCircle extends StatelessWidget {
  final double progressValue;

  const LoadingCircle({Key key, this.progressValue}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        child: CircularProgressIndicator(value: progressValue),
        alignment: Alignment(0.0, 0.0),
      ),
    );
  }
}

class NonEmptyValidator extends TextFieldValidator {
  NonEmptyValidator({@required String errorText}) : super(errorText);

  @override
  bool get ignoreEmptyValues => false;

  @override
  bool isValid(String value) {
    return value.trim().isNotEmpty;
  }
}

final _markerColor = Color.fromARGB(255, 231, 40, 102);

Future<BitmapDescriptor> drawMapClusterMarker(String text, double radius) async {
  final pictureRecorder = PictureRecorder();
  final canvas = Canvas(pictureRecorder);
  final paint = Paint();

  final textSpan = TextSpan(text: text,
    style: TextStyle(fontSize: radius - 5, fontWeight: FontWeight.bold, color: Colors.white),
  );
  final textPainter = TextPainter(textDirection: TextDirection.ltr, text: textSpan);

  canvas.drawCircle(Offset(radius, radius), radius, paint..color = _markerColor);
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

Future<BitmapDescriptor> drawMapLocationMarker(double radius) async {
  final pictureRecorder = PictureRecorder();
  final canvas = Canvas(pictureRecorder);
  final paint = Paint();
  final path = Path();

  paint.color = _markerColor;
  paint.style = PaintingStyle.fill;
  path.moveTo(radius, 2 * radius);
  path.arcTo(Rect.fromLTWH(0.25 * radius, 0, 1.5 * radius, 1.5 * radius), pi - 0.5, pi + 1, false);
  path.close();
  canvas.drawPath(path, paint);

  canvas.drawCircle(Offset(radius, radius / 1.5), 0.25 * radius, paint..color = Colors.white);

  final image = await pictureRecorder.endRecording().toImage(
    radius.toInt() * 2,
    radius.toInt() * 2,
  );

  final data = await image.toByteData(format: ImageByteFormat.png);
  return BitmapDescriptor.fromBytes(data.buffer.asUint8List());
}

void scrollToEnd(ScrollController controller) {
  WidgetsBinding.instance.addPostFrameCallback((_) => controller.jumpTo(controller.position.maxScrollExtent));
}

class WideRoundedButton extends StatelessWidget {

  static const radius = 20.0;

  final String text;
  final VoidCallback onPressed;
  final Color color;

  WideRoundedButton({Key key, @required this.text, this.onPressed, this.color}) : super(key: key);

  Widget build(BuildContext context) {
    return SizedBox(
        width: double.infinity,
        height: 2 * radius,
        child: RaisedButton(
          child: Text(text, style: Theme
              .of(context)
              .textTheme
              .button),
          onPressed: onPressed,
          color: color ?? Theme.of(context).buttonColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(radius))
          ),
        )
    );
  }
}

class WideRoundedField extends StatelessWidget {

  static const radius = 10.0;

  final Widget child;

  WideRoundedField({Key key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(radius))),
        padding: EdgeInsets.all(radius),
        child: child,
    );
  }
}
