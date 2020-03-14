import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';

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

Future showConfirmDialog(BuildContext context, String title, String message, VoidCallback onConfirm) {
  return showDialog(
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          FlatButton(
              child: Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              }),
          FlatButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
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