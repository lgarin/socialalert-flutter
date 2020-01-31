import 'package:geolocator/geolocator.dart';

class GeolocationService {
  final Geolocator geolocator = Geolocator();

  Future<Placemark> get currentPlace async {
    final position = await geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    if (position == null) {
      return null;
    }
    final placemarks = await geolocator.placemarkFromCoordinates(
          position.latitude, position.longitude) ?? [];
    return placemarks.length > 0 ? placemarks.first : Placemark(position: position);
  }
}