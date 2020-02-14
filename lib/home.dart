import 'package:flutter/material.dart';
import 'package:social_alert_app/base.dart';
import 'package:social_alert_app/main.dart';

class HomePage extends StatefulWidget {

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends BasePageState<HomePage> {
  int _currentDisplayIndex = 0;

  _HomePageState() : super(AppRoute.Home);

  void _tabSelected(int index) {
    setState(() {
      _currentDisplayIndex = index;
    });
  }

  Widget _createCurrentDisplay() {
    switch (_currentDisplayIndex) {
      case 0:
        return _GalleryDisplay();
      case 1:
        return _FeedDisplay();
      case 2:
        return _NetworkDisplay();
      default:
        return null;
    }
  }

  BottomNavigationBar buildNavBar(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _currentDisplayIndex,
        onTap: _tabSelected,
        items: <BottomNavigationBarItem>[
          new BottomNavigationBarItem(
            icon: Icon(Icons.panorama),
            title: Text('Snypes'),
          ),
          new BottomNavigationBarItem(
            icon: Icon(Icons.create),
            title: Text('Scribes'),
          ),
          new BottomNavigationBarItem(
              icon: Icon(Icons.people),
              title: Text('Network')
          )
        ]
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return Center(child: _createCurrentDisplay());
  }
}

class _GalleryDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(Icons.panorama, size: 100, color: Colors.grey),
        Text('No content yet', style: Theme
            .of(context)
            .textTheme
            .headline6),
        Text('Be the first to post some media here.')
      ],
    );
  }
}

class _FeedDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(Icons.create, size: 100, color: Colors.grey),
        Text('No content yet', style: Theme
            .of(context)
            .textTheme
            .headline6),
        Text('Be the first to post some comments here.')
      ],
    );
  }
}

class _NetworkDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(Icons.people, size: 100, color: Colors.grey),
        Text('No relationship yet', style: Theme
            .of(context)
            .textTheme
            .headline6),
        Text('Invite some friends to follow them here.')
      ],
    );
  }
}