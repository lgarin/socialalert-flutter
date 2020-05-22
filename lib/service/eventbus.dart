import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:social_alert_app/service/serviceprodiver.dart';

class EventBus extends Service {
  final _streamController = StreamController.broadcast();

  EventBus(BuildContext context) : super(context);

  static EventBus of(BuildContext context) => ServiceProvider.of(context);

  Stream<T> on<T>() {
    if (T == dynamic) {
      return _streamController.stream;
    } else {
      return _streamController.stream.where((event) => event is T).cast<T>();
    }
  }

  void fire(event) {
    _streamController.add(event);
  }

  @override
  void dispose() {
    _streamController.close();
  }
}