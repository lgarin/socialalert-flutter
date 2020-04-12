import 'dart:async';
import 'dart:io';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/base.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/mediaquery.dart';
import 'package:social_alert_app/service/profileupdate.dart';

class UserAvatar extends StatelessWidget {
  static const LARGE_RADIUS = 60.0;

  final String imageUri;
  final bool online;
  final double radius;
  final String uploadTaskId;

  UserAvatar({this.imageUri, this.online, this.radius, this.uploadTaskId}) : super(key: ValueKey('$imageUri/$online/$uploadTaskId'));

  @override
  Widget build(BuildContext context) {
    final url = imageUri != null ? MediaQueryService.toAvatarUrl(imageUri, radius < LARGE_RADIUS) : null;
    return Container(
      width: radius,
      height: radius,
      decoration: _buildDecoration(url, context),
      child: uploadTaskId != null ? _buildUploadProgress() : SizedBox(height: 0, width: 0),
    );
  }

  Widget _buildUploadProgress() {
    return Consumer<AvatarUploadProgress>(
      builder: (context, upload, _) => upload != null && uploadTaskId == upload.taskId ? CircularProgressIndicator(value: upload.value) : SizedBox(height: 0, width: 0),
    );
  }

  BoxDecoration _buildDecoration(String url, BuildContext context) {
    return BoxDecoration(
      color: Colors.white,
      image: DecorationImage(
        image: url != null ? NetworkImage(url) : AssetImage('images/unknown_user.png'),
        fit: BoxFit.fill,
      ),
      borderRadius: BorderRadius.all(Radius.circular(radius / 2)),
      //boxShadow: [BoxShadow(color: online ? Theme.of(context).accentColor : Colors.grey, spreadRadius: 1.0, blurRadius: 1.0)],
      border: online != null ? Border.all(color: online ? Theme.of(context).accentColor : Colors.grey, width: 2) : null,
    );
  }
}

class _ProfileTabSelectionModel with ChangeNotifier {
  static const informationIndex = 0;
  static const credentialsIndex = 1;
  static const privacyIndex = 2;

  int _currentDisplayIndex = informationIndex;

  int get currentDisplayIndex => _currentDisplayIndex;
  bool get informationSelected => _currentDisplayIndex == informationIndex;
  bool get credentialsSelected => _currentDisplayIndex == credentialsIndex;
  bool get privacySelected => _currentDisplayIndex == privacyIndex;

  void tabSelected(int index) {
    _currentDisplayIndex = index;
    notifyListeners();
  }
}

enum Gender {
  MALE,
  FEMALE,
  OTHER,
}

class _UserInformationModel extends ChangeNotifier {


  Gender _gender;
  DateTime _birthdate;

  Gender get gender => _gender;
  void setGender(Gender newGender) => _gender = newGender;

  DateTime get birthdate => _birthdate;
  void setBirthdate(DateTime newBirthdate) => _birthdate = newBirthdate;
}

class _InformationForm extends StatefulWidget {
  @override
  _InformationFormState createState() => _InformationFormState();
}

class _InformationFormState extends State<_InformationForm> {
  final _formKey = GlobalKey<FormState>();
  final _informationModel = _UserInformationModel();

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ChangeNotifierProvider.value(
        value: _informationModel,
        child: _buildForm()
      ),
      padding: EdgeInsets.all(20.0),
    );
  }

  Form _buildForm() {
    return Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            _GenderWidget(),
            SizedBox(height: 5),
            _BirthdateWidget(),
          ]
        )
      );
  }
}

class _GenderWidget extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
  _UserInformationModel model = Provider.of(context);
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(10))),
      padding: EdgeInsets.all(10),
      child: DropdownButtonFormField<Gender>(
        onChanged: model.setGender,
        value: model.gender,
        icon: Row(children: <Widget>[Icon(Icons.expand_more), SizedBox(width: 10)]),
        decoration: InputDecoration(
            hintText: 'Select gender',
            icon: Icon(Icons.wc)),
        items: [
          DropdownMenuItem<Gender>(value: Gender.FEMALE,
              child: Text('Female \u{2640}')
          ),
          DropdownMenuItem<Gender>(value: Gender.MALE,
            child: Text('Male \u{2642}')
          ),
          DropdownMenuItem<Gender>(value: Gender.OTHER,
              child: Text('Other')
          ),
        ],
      ),
    );
  }
}

class _BirthdateWidget extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    _UserInformationModel model = Provider.of(context);
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(10))),
      padding: EdgeInsets.all(10),
      child: DateTimeField(
        format: DateFormat('d MMM yyyy'),
        onSaved: model.setBirthdate,
        onFieldSubmitted: model.setBirthdate,
        initialValue: model.birthdate,
        decoration: InputDecoration(
            hintText: 'Select birthdate',
            icon: Icon(Icons.cake)),
        onShowPicker: (context, currentValue) {
          return showDatePicker(
              context: context,
              initialDatePickerMode: DatePickerMode.year,
              firstDate: DateTime(1900),
              initialDate: currentValue ?? DateTime.now(),
              lastDate: DateTime(2100));
        },
      ),
    );
  }
}

class ProfileEditorPage extends StatefulWidget {
  @override
  _ProfileEditorPageState createState() => _ProfileEditorPageState();
}

class _ProfileEditorPageState extends BasePageState<ProfileEditorPage> {

  _ProfileEditorPageState() : super(AppRoute.ProfileEditor);

  StreamSubscription<AvatarUploadProgress> uploadProgressSubscription;
  String _uploadTaskId;
  final _tabSelectionModel = _ProfileTabSelectionModel();

  @override
  void initState() {
    super.initState();
    uploadProgressSubscription = ProfileUpdateService.current(context).uploadProgressStream.listen((event) {
      if (event.taskId == _uploadTaskId && event.terminal) {
        if (event.error != null) {
          showSimpleDialog(context, 'Avatar upload failed', event.error);
        }
        setState(() {
          _uploadTaskId = null;
        });
      }
    });
  }

  @override
  void dispose() {
    uploadProgressSubscription.cancel();
    super.dispose();
  }

  void _onSave() {

  }

  @override
  AppBar buildAppBar() {
    return AppBar(title: Text('Edit profile'),
        actions: <Widget>[
          IconButton(onPressed: _choosePicture, icon: Icon(Icons.account_circle)),
          IconButton(onPressed: _onSave, icon: Icon(Icons.done))
        ]
    );
  }

  @override
  Widget buildNavBar(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _tabSelectionModel,
      child: _ProfileBottomNavigationBar(),
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return ListView(
      children: <Widget>[
        UserHeader(tapCallback: _choosePicture, uploadTaskId: _uploadTaskId),
        _buildBottomPanel(context),
      ],
    );
  }

  Widget _buildBottomPanel(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _tabSelectionModel,
      child: _ProfileTabPanel(),
    );
  }

  void _choosePicture() async {
    final image = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _beginUpload(image);
    }
  }

  Future _beginUpload(File image) async {
    try {
      final taskId = await ProfileUpdateService.current(context).beginAvatarUpload('Avatar', image);
      setState(() {
        _uploadTaskId = taskId;
      });
    } catch (e) {
      showSimpleDialog(context, 'Avatar upload failed', e.toString());
    }
  }
}

class _ProfileBottomNavigationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tabSelectionModel = Provider.of<_ProfileTabSelectionModel>(context);
    return BottomNavigationBar(
        currentIndex: tabSelectionModel.currentDisplayIndex,
        onTap: tabSelectionModel.tabSelected,
        items: <BottomNavigationBarItem>[
          new BottomNavigationBarItem(
            icon: Icon(Icons.person),
            title: Text('Personal info'),
          ),
          new BottomNavigationBarItem(
            icon: Icon(Icons.panorama),
            title: Text('My Snypes'),
          ),
          new BottomNavigationBarItem(
            icon: Icon(Icons.create),
            title: Text('My Scribes'),
          )
        ]
    );
  }
}

class _ProfileTabPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tabSelectionModel = Provider.of<_ProfileTabSelectionModel>(context);
    if (tabSelectionModel.informationSelected) {
      return _InformationForm();
    } else {
      return SizedBox(height: 0, width: 0);
    }
  }
}

class UserHeader extends StatelessWidget {
  final GestureTapCallback tapCallback;
  final String uploadTaskId;

  UserHeader({this.tapCallback, this.uploadTaskId});

  Widget build(BuildContext context) {
    final profile = Provider.of<UserProfile>(context);
    return Container(
        height: 220,
        color: Theme.of(context).primaryColorDark.withOpacity(0.9),
        child: profile != null ? _buildBody(context, profile) : LoadingCircle()
    );
  }

  Widget _buildBody(BuildContext context, UserProfile profile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _buildProfileColumn(context, profile),
        SizedBox(width: 20),
        _buildStatisticColumn(context, profile),
      ],
    );
  }

  GestureDetector _buildProfileColumn(BuildContext context, UserProfile profile) {
    return GestureDetector(
      onTap: tapCallback,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 30),
            _buildAvatar(context, profile),
            SizedBox(height: 10),
            _buildUsername(context, profile),
            _buildEmail(context, profile)
          ]),
    );
  }

  GestureDetector _buildStatisticColumn(BuildContext context, UserProfile profile) {
    return GestureDetector(
      onTap: null,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 40),
            Row(children: <Widget>[
              Icon(Icons.people, size: 14, color: Colors.white),
              SizedBox(width: 4),
              Text(profile.statistic.followerCount.toString(), style: TextStyle(fontSize: 12, color: Colors.white)),
            ]),
            SizedBox(height: 4),
            Row(children: <Widget>[
              Icon(Icons.thumb_up, size: 14, color: Colors.white),
              SizedBox(width: 4,),
              Text(profile.statistic.likeCount.toString(), style: TextStyle(fontSize: 12, color: Colors.white)),
            ]),
            SizedBox(height: 4),
            Row(children: <Widget>[
              Icon(Icons.thumb_down, size: 14, color: Colors.white),
              SizedBox(width: 4,),
              Text(profile.statistic.dislikeCount.toString(), style: TextStyle(fontSize: 12, color: Colors.white)),
            ]),
            SizedBox(height: 4),
            Row(children: <Widget>[
              Icon(Icons.remove_red_eye, size: 14, color: Colors.white),
              SizedBox(width: 4),
              Text(profile.statistic.hitCount.toString(), style: TextStyle(fontSize: 12, color: Colors.white)),
            ]),
            SizedBox(height: 4),
            Row(children: <Widget>[
              Icon(Icons.panorama, size: 14, color: Colors.white),
              SizedBox(width: 4),
              Text(profile.statistic.mediaCount.toString(), style: TextStyle(fontSize: 12, color: Colors.white)),
            ]),
            SizedBox(height: 4),
            Row(children: <Widget>[
              Icon(Icons.mode_comment, size: 14, color: Colors.white),
              SizedBox(width: 4),
              Text(profile.statistic.commentCount.toString(), style: TextStyle(fontSize: 12, color: Colors.white)),
            ])
          ]),
    );
  }

  Widget _buildUsername(BuildContext context, UserProfile profile) {
    final username = Text(profile.username, style: Theme.of(context).textTheme.subtitle2);
    if (profile.country == null) {
      return username;
    }
    return Row(
      children: <Widget>[
        username,
        SizedBox(width: 4),
        Image.asset('images/flags/${profile.country.toLowerCase()}.png', width: 20, height: 15,)
      ],
    );
  }

  Text _buildEmail(BuildContext context, UserProfile profile) {
    return Text(
        profile.email,
        style: TextStyle(color: Colors.white, fontSize: 12)
    );
  }

  Widget _buildAvatar(BuildContext context, UserProfile profile) {
    return Hero(tag: profile.userId,
        child: UserAvatar(radius: 120.0, imageUri: profile.imageUri, online: null, uploadTaskId: uploadTaskId)
    );
  }
}
