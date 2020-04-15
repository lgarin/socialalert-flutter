import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:social_alert_app/service/serviceprodiver.dart';

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

  String formatShort() {
    if (locality != null && country != null) {
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

class GeoLocationService extends Service {

  final Geolocator _geolocator = Geolocator();

  final _locationController = StreamController<GeoLocation>();

  static GeoLocationService current(BuildContext context) => ServiceProvider.of(context);

  GeoLocationService(BuildContext context) : super(context);

  Stream<GeoLocation> get locationStream => _locationController.stream;

  @override
  void dispose() {
    _locationController.close();
  }

  Future<bool> _isCurrentPositionNear(Position position, double maxDistanceInMeter) async {
    final current = await _geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final distanceInMeter = await _geolocator.distanceBetween(position.latitude, position.longitude, current.latitude, current.longitude);
    return distanceInMeter < maxDistanceInMeter;
  }

  Future<GeoPosition> readPosition(double precisionInMeter) async {
    final position = await _geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    if (position == null) {
      return null;
    }

    var counter = 0;
    do {
      await Future.delayed(Duration(milliseconds: 500));
    } while (await _isCurrentPositionNear(position, precisionInMeter).then((value) => !value) && ++counter < 6);

    final precisePosition = await _geolocator.getLastKnownPosition(desiredAccuracy: LocationAccuracy.high);
    return GeoPosition(longitude: precisePosition.longitude, latitude: precisePosition.latitude);
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