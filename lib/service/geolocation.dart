import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

class GeoLocation {
  final double latitude;
  final double longitude;
  final String country;
  final String locality;
  final String address;

  GeoLocation({@required this.latitude, @required this.longitude, this.country, this.locality, this.address});

  GeoLocation.fromPlacemark(Placemark placemark) :
        latitude = placemark.position.latitude,
        longitude = placemark.position.longitude,
        country = placemark.isoCountryCode,
        locality = placemark.locality,
        address = placemark.name;

  String format() {
    if (address != null && locality != null && country != null) {
      return '$address, $locality ($country)';
    } else if (locality != null && country != null) {
      return '$locality ($country)';
    } else if (latitude != null && longitude != null) {
      return '$latitude, $longitude';
    } else {
      return '';
    }
  }
}

class GeoLocationService {
  static GeoLocationService current(BuildContext context) =>
      Provider.of<GeoLocationService>(context, listen: false);

  final Geolocator _geolocator = Geolocator();

  final _locationController = StreamController<GeoLocation>();

  Stream<GeoLocation> get locationStream => _locationController.stream;

  void dispose() {
    _locationController.close();
  }

  Future<GeoLocation> readLocation() async {
    final position = await _geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    if (position == null) {
      return null;
    }
    final placemarks = await _geolocator.placemarkFromCoordinates(
          position.latitude, position.longitude) ?? [];
    final placemark = placemarks.length > 0 ? placemarks.first : Placemark(position: position);
    final location = GeoLocation.fromPlacemark(placemark);
    _locationController.add(location);
    return location;
  }

  Future<GeoLocation> tryReadLocation() async {
    try {
      return await readLocation();
    } catch (e) {
      return null;
    }
  }
}