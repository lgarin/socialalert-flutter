import 'dart:math';
import 'dart:ui';

import 'package:charts_flutter/flutter.dart' as chart;
import 'package:flutter/material.dart' hide FormFieldValidator;
import 'package:form_field_validator/form_field_validator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/service/dataobject.dart';

T showUnexpectedError<T>(BuildContext context, Object error) {
  showSimpleDialog(context, 'Unexpected error', error.toString());
  return null;
}

Future<T> showSimpleDialog<T>(BuildContext context, String title, String message) {
  return showDialog(
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
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
          TextButton(
              child: Text(confirmText),
              onPressed: () {
                Navigator.of(context).pop(true);
              }),
          TextButton(
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
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message, style: TextStyle(color: color)), action: action));
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

// TODO check if this class can be replaced by RequiredValidator
class NonEmptyValidator extends TextFieldValidator {
  NonEmptyValidator({@required String errorText}) : super(errorText);

  @override
  bool get ignoreEmptyValues => false;

  @override
  bool isValid(String value) {
    return value.trim().isNotEmpty;
  }
}

const _markerColor = Color.fromARGB(255, 231, 40, 102);

Future<BitmapDescriptor> drawMapClusterMarker(String text, double radius, {Color markerColor}) async {
  final pictureRecorder = PictureRecorder();
  final canvas = Canvas(pictureRecorder);
  final paint = Paint();

  final textSpan = TextSpan(text: text,
    style: TextStyle(fontSize: radius - 5, fontWeight: FontWeight.bold, color: Colors.white),
  );
  final textPainter = TextPainter(textDirection: TextDirection.ltr, text: textSpan);

  paint.color = markerColor ?? _markerColor;
  canvas.drawCircle(Offset(radius, radius), radius, paint);
  textPainter.layout();
  textPainter.paint(canvas, Offset(radius - textPainter.width / 2, radius - textPainter.height / 2));

  final image = await pictureRecorder.endRecording().toImage(radius.toInt() * 2, radius.toInt() * 2);
  final data = await image.toByteData(format: ImageByteFormat.png);
  return BitmapDescriptor.fromBytes(data.buffer.asUint8List());
}

Future<BitmapDescriptor> drawMapLocationMarker(double radius, {Color markerColor}) async {
  final pictureRecorder = PictureRecorder();
  final canvas = Canvas(pictureRecorder);
  final paint = Paint();
  final path = Path();

  paint.color = markerColor ?? _markerColor;
  paint.style = PaintingStyle.fill;
  path.moveTo(radius, 2 * radius);
  path.arcTo(Rect.fromLTWH(0.25 * radius, 0, 1.5 * radius, 1.5 * radius), pi - 0.5, pi + 1, false);
  path.close();
  canvas.drawPath(path, paint);

  canvas.drawCircle(Offset(radius, radius / 1.5), 0.25 * radius, paint..color = Colors.white);

  final image = await pictureRecorder.endRecording().toImage(radius.toInt() * 2, radius.toInt() * 2);
  final data = await image.toByteData(format: ImageByteFormat.png);
  return BitmapDescriptor.fromBytes(data.buffer.asUint8List());
}

void scrollToEnd(ScrollController controller) {
  WidgetsBinding.instance.addPostFrameCallback((_) => controller.jumpTo(controller.position.maxScrollExtent));
}

class WideRoundedButton extends StatelessWidget {

  static const radius = 20.0;
  static const _shape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(radius)));

  final String text;
  final VoidCallback onPressed;
  final Color color;

  WideRoundedButton({Key key, @required this.text, this.onPressed, this.color}) : super(key: key);

  Widget build(BuildContext context) {
    return SizedBox(
        width: double.infinity,
        height: 2 * radius,
        child: ElevatedButton(
          child: Text(text, style: Theme.of(context).textTheme.button),
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(shape: _shape, primary: color),
          ),
    );
  }
}

class WideRoundedField extends StatelessWidget {

  static const radius = 10.0;

  final Widget child;
  final EdgeInsetsGeometry padding;

  WideRoundedField({Key key, this.padding, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(radius))),
        padding: padding == null ? EdgeInsets.all(radius) : padding,
        child: child,
    );
  }
}

class CheckboxFormField extends FormField<bool> {
  CheckboxFormField({
    Widget title,
    Widget secondary,
    ListTileControlAffinity controlAffinity = ListTileControlAffinity.trailing,
    FormFieldSetter<bool> onSaved,
    FormFieldValidator<bool> validator,
    bool initialValue = false,
    AutovalidateMode autovalidateMode,
  }) : super(
            onSaved: onSaved,
            validator: validator,
            initialValue: initialValue,
            autovalidateMode: autovalidateMode,
            builder: (FormFieldState<bool> state) {
              final subtitle = state.hasError
                  ? Text(state.errorText, style: TextStyle(color: Theme.of(state.context).errorColor))
                  : null;
              return CheckboxListTile(
                dense: true,
                secondary: secondary,
                title: title,
                value: state.value,
                onChanged: state.didChange,
                subtitle: subtitle,
                controlAffinity: controlAffinity,
              );
            });
}

class StatisticPeriodWidget extends StatelessWidget {
  static final List<Period> periods = [Period.WEEK, Period.MONTH, Period.YEAR];
  static final List<String> fullTexts = ['Week', 'Month', 'Year'];
  final Period currentPeriod;
  final void Function(Period) onChanged;

  StatisticPeriodWidget({this.currentPeriod, this.onChanged}) : super(key: ValueKey(currentPeriod));

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.only(left: 10, right: 10, top: 10),
        child: ToggleButtons(
          children: periods.map(_buildText).toList(growable: false),
          isSelected: periods.map(_isSelected).toList(growable: false),
          selectedColor: Colors.white,
          fillColor: Theme.of(context).primaryColor,
          onPressed: (index) => onChanged(periods[index]),
          borderRadius: BorderRadius.circular(20),
          borderWidth: 2,
          selectedBorderColor: Theme.of(context).primaryColor,
        )
    );
  }

  bool _isSelected(Period value) => currentPeriod == value;

  Widget _buildText(Period value) {
    final index = periods.indexOf(value);
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: 15),
        child: Text(fullTexts[index])
    );
  }
}

class StatisticChart<S extends Enum> extends StatelessWidget {
  static final itemMargin = EdgeInsets.only(left: 10, right: 10, top: 10);
  static final itemPadding = EdgeInsets.all(5);
  static final chartTextStyle = chart.TextStyleSpec(fontSize: 14);
  static final chartSmallTickStyle = chart.LineStyleSpec(color: chart.MaterialPalette.black);

  final StatisticService service;
  final String objectId;
  final S source;
  final String title;
  final Period period;

  StatisticChart({@required this.service, @required this.objectId, @required this.source, @required this.title, @required this.period}) : super(key: ValueKey('$objectId/$source/$period'));

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.6,
      child: Card(
          margin: itemMargin,
          child: Padding(
            padding: itemPadding,
            child: _buildCardContent(context),
          )
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    return Column(
        children: [
          Text(title),
          Expanded(child: _buildDataLoader(context))
        ]);
  }

  Widget _buildDataLoader(BuildContext context) {
    return FutureProvider<chart.Series>(
        initialData: null,
        create: _buildSeries,
        ///catchError: showUnexpectedError,
        child: Consumer<chart.Series>(
            builder: _buildBarChart
        )
    );
  }

  Future<chart.Series> _buildSeries(BuildContext context) async {
    final data = await service.histogram(source, objectId, period);
    return chart.Series<CountByPeriod, DateTime>(id: key.toString(), displayName: title, data: data,
        domainFn: (CountByPeriod item, _) => item.period,
        measureFn: (CountByPeriod item, _) => item.count);
  }

  Column _buildNoData(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(Icons.show_chart, size: 100, color: Colors.grey),
        Text('No data yet', style: Theme
            .of(context)
            .textTheme
            .headline6),
      ],
    );
  }

  Widget _buildBarChart(BuildContext context, chart.Series value, Widget child) {
    if (value == null) {
      return LoadingCircle();
    }
    if (value.data.isEmpty) {
      return _buildNoData(context);
    }
    return chart.TimeSeriesChart(
      [value],
      animate: true,
      defaultRenderer: chart.LineRendererConfig(includeArea: true),
      defaultInteractions: false,
      domainAxis: chart.DateTimeAxisSpec(
          renderSpec: chart.SmallTickRendererSpec(
              labelStyle: chartTextStyle,
              lineStyle: chartSmallTickStyle)),
      primaryMeasureAxis: chart.NumericAxisSpec(
          renderSpec: chart.GridlineRendererSpec(
              labelStyle: chartTextStyle)),
    );
  }
}