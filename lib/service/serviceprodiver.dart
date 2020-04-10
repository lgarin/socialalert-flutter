
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

abstract class Service {
  final BuildContext context;

  Service(this.context);

  T lookup<T>() => Provider.of<T>(context, listen: false);

  void dispose();
}

class ServiceProvider<T extends Service> extends Provider<T> {

  static T of<T>(BuildContext context) => Provider.of<T>(context, listen:  false);

  static void _disposeService(BuildContext context, Service service) {
    service.dispose();
  }

  ServiceProvider({@required Create<T> create, bool lazy = true}) : super(create: create, lazy: lazy, dispose: _disposeService);
}