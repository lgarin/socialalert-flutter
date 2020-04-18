import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

class NoAnimationMaterialPageRoute<T> extends MaterialPageRoute<T> {
  NoAnimationMaterialPageRoute({
    @required WidgetBuilder builder,
    RouteSettings settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) : super(
      builder: builder,
      maintainState: maintainState,
      settings: settings,
      fullscreenDialog: fullscreenDialog);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return child;
  }
}
