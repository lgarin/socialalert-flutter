import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/authentication.dart';
import 'package:social_alert_app/menu.dart';
import 'package:social_alert_app/profile.dart';

class HomePage extends StatefulWidget {

  final LoginResponse login;

  HomePage(LoginResponse login) : login = login;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentDisplayIndex = 0;

  void _takePicture(BuildContext context) async {
    final image = await ImagePicker.pickImage(source: ImageSource.camera);
    if (image != null) {
      await Navigator.of(context).pushNamed("annotate", arguments: image);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UserProfile>(
        create: (_) => UserProfile(
          username: widget.login.username,
          email: widget.login.email,
          imageUri: widget.login.imageUri,
          country: widget.login.country,
          birthdate: widget.login.birthdate,
          biography: widget.login.biography
        ),
        child: Scaffold(
          appBar: _buildAppBar(),
          drawer: Menu(),
          body: Center(child: _createCurrentDisplay()),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          floatingActionButton: _buildCaptureButton(context),
          bottomNavigationBar: _buildNavBar()
        )
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text("Snypix"),
      actions: <Widget>[
        Icon(Icons.place),
        SizedBox(width: 10),
        Icon(Icons.search),
        SizedBox(width: 10),
        Icon(Icons.more_vert)
      ],
    );
  }

  FloatingActionButton _buildCaptureButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _takePicture(context),
      tooltip: 'Take picture',
      backgroundColor: Theme.of(context).primaryColor,
      child: Icon(Icons.add_a_photo, color: Colors.white,),
    );
  }

  BottomNavigationBar _buildNavBar() {
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
            .title),
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
            .title),
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
            .title),
        Text('Invite some friends to follow them here.')
      ],
    );
  }
}