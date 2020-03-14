
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String imageUri;
  final bool online;
  final double radius;

  UserAvatar({this.imageUri, this.online, this.radius}) : super(key: ValueKey(imageUri));

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        color: Theme.of(context).accentColor,
        image: DecorationImage(
          image: imageUri != null ? NetworkImage(imageUri) : AssetImage('images/unknown_user.png'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.all(Radius.circular(radius / 2)),
        border: Border.all(color: online ? Colors.white : Colors.grey, width: 4.0),
      ),
    );
  }


}