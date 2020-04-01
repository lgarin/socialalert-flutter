import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

class GeoPosition {
  final double latitude;
  final double longitude;

  GeoPosition({@required this.latitude, @required this.longitude});
}

class GeoLocation extends GeoPosition {
  final String country;
  final String locality;
  final String address;

  GeoLocation({@required double latitude, @required double longitude, this.country, this.locality, this.address}) :
        super(latitude: latitude, longitude: longitude);

  GeoLocation.fromPlacemark(Placemark placemark) :
        country = placemark.isoCountryCode,
        locality = placemark.locality,
        address = [placemark.subLocality, placemark.thoroughfare, placemark.subThoroughfare].where((e) => e.isNotEmpty).join(' '),
        super(latitude: placemark.position.latitude, longitude: placemark.position.longitude);

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

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'formattedAddress': address,
    'locality': locality,
    'country': country,
  };
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

  Future<GeoPosition> readPosition() async {
    final position = await _geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    if (position == null) {
      return null;
    }
    return GeoPosition(longitude: position.longitude, latitude: position.latitude);
  }

  Future<GeoLocation> readLocation({@required double latitude, @required double longitude}) async {
    if (latitude == null || longitude == null) {
      return null;
    }
    final placemarks = await _geolocator.placemarkFromCoordinates(latitude, longitude) ?? [];
    final placemark = placemarks.length > 0 ? placemarks.first : Placemark(position: Position(latitude: latitude, longitude: longitude));
    final location = GeoLocation.fromPlacemark(placemark);
    _locationController.add(location);
    return location;
  }
}