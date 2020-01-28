import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class UserProfile with ChangeNotifier {
  String _username;
  String _email;
  String _country;
  ImageProvider _picture;
  DateTime _birthdate;
  String _biography;

  static UserProfile current(BuildContext context) =>
      Provider.of<UserProfile>(context, listen: true);

  UserProfile(
      {String username,
      String email,
      String country,
      String imageUri,
      String birthdate,
      String biography}) {
    _username = username;
    _email = email;
    _country = country;
    _picture = imageUri != null
        ? NetworkImage(imageUri)
        : AssetImage('images/unknown_user.png');
    _birthdate = birthdate != null ? DateTime.parse(birthdate) : null;
    _biography = biography;
  }

  String get biography => _biography;

  DateTime get birthdate => _birthdate;

  ImageProvider get picture => _picture;

  String get country => _country;

  String get email => _email;

  String get username => _username;
}
