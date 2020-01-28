import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/authentication.dart';
import 'package:social_alert_app/menu.dart';
import 'package:social_alert_app/profile.dart';

class HomePage extends StatefulWidget {

  final LoginResponse _login;

  HomePage(LoginResponse login) : _login = login;

  @override
  _HomePageState createState() => _HomePageState(_login);
}

class _HomePageState extends State<HomePage> {
  int _counter = 0;
  int _currentNavIndex = 0;
  final LoginResponse _login;

  _HomePageState(LoginResponse login) : _login = login;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _tabSelected(int index) {
    setState(() {
      _currentNavIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UserProfile>(
        create: (_) => UserProfile(
          username: _login.username,
          email: _login.email,
          imageUri: _login.imageUri,
          country: _login.country,
          birthdate: _login.birthdate,
          biography: _login.biography
        ),
        child: Scaffold(
          appBar: _buildAppBar(),
          drawer: Menu(),
          body: Center(
            child: CounterDisplay(counter: _counter),
          ),
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
        Icon(Icons.search),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
        ),
        Icon(Icons.more_vert)
      ],
    );
  }

  FloatingActionButton _buildCaptureButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: _incrementCounter,
      tooltip: 'Take picture',
      backgroundColor: Theme.of(context).primaryColor,
      child: Icon(Icons.add_a_photo, color: Colors.white,),
    );
  }

  BottomNavigationBar _buildNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentNavIndex,
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

class CounterDisplay extends StatelessWidget {
  const CounterDisplay({
    Key key,
    @required int counter,
  }) : _counter = counter, super(key: key);

  final int _counter;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          'You have pushed the button this many times:',
        ),
        Text(
          '$_counter',
          style: Theme.of(context).textTheme.display1,
        ),
      ],
    );
  }
}
