import 'dart:async';
import 'dart:io';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/base.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/eventbus.dart';
import 'package:social_alert_app/service/mediaquery.dart';
import 'package:social_alert_app/service/profileupdate.dart';

class ProfileAvatar extends StatelessWidget {
  static const LARGE_RADIUS = 60.0;

  final String imageUri;
  final bool online;
  final double radius;
  final String uploadTaskId;

  ProfileAvatar({this.imageUri, this.online, @required this.radius, this.uploadTaskId}) : super(key: ValueKey('$imageUri/$online/$uploadTaskId'));

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

class _ProfileFormModel {
  Gender _gender;
  DateTime _birthdate;
  Country _country;
  String _biography;

  _ProfileFormModel(UserProfile profile) {
    _country = Country(profile.country, null);
    _biography = profile.biography;
    _birthdate = profile.birthdate != null ? DateTime.parse(profile.birthdate) : null;
    _gender = fromGenderName(profile.gender);
  }

  Gender get gender => _gender;
  void setGender(Gender newGender) => _gender = newGender;

  DateTime get birthdate => _birthdate;
  void setBirthdate(DateTime newBirthdate) => _birthdate = newBirthdate;

  Country get country => _country;
  void setCountry(Country newCountry) => _country = newCountry;

  String get biography => _biography;
  void setBiography(String newBiography) => _biography = newBiography;

  ProfileUpdateRequest toUpdateRequest() => ProfileUpdateRequest(biography: biography, birthdate: birthdate, country: country, gender: gender);
}

class _ProfileForm extends StatefulWidget {
  @override
  _ProfileFormState createState() => _ProfileFormState();
}

enum _ProfileAction {
  save,
}

class _ProfileFormState extends State<_ProfileForm> {
  static const backgroundColor = Color.fromARGB(255, 240, 240, 240);

  final _formKey = GlobalKey<FormState>();
  _ProfileFormModel _formModel;
  bool _dirty;
  StreamSubscription<_ProfileAction> _actionSubscription;

  @override
  void initState() {
    super.initState();
    _dirty = false;
    _formModel = _ProfileFormModel(Provider.of(context, listen: false));
    _actionSubscription = EventBus.current(context).on<_ProfileAction>().listen((action) {
      if (action == _ProfileAction.save) {
        _onSave();
      }
    });
  }

  @override
  void dispose() {
    _actionSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Provider.value(
        value: _formModel,
        child: _buildForm(context),
      ),
      padding: EdgeInsets.all(20.0),
    );
  }

  Future<bool> _allowPop() async {
    if (!_dirty) {
      return true;
    }
    return await showConfirmDialog(context, 'Unsaved changes', 'Do you want to leave without saving your changes?', confirmText: 'Yes', cancelText: 'No');
  }

  Form _buildForm(BuildContext context) {
    return Form(
        key: _formKey,
        onChanged: () => _dirty = true,
        onWillPop: _allowPop,
        child: Column(
          children: <Widget>[
            _GenderWidget(),
            SizedBox(height: 5),
            _BirthdateWidget(),
            SizedBox(height: 5),
            _CountryWidget(),
            SizedBox(height: 5),
            _BiographyWidget(),
            SizedBox(height: 10),
            _SaveButton(onSave: _onSave)
          ]
        )
      );
  }

  void _onSave() async {
    final form = _formKey.currentState;
    if (form != null && form.validate()) {
      form.save();
      try {
        await ProfileUpdateService.current(context).updateProfile(_formModel.toUpdateRequest());
        _dirty = false;
        Navigator.of(context).pop();
      } catch (e) {
        showSimpleDialog(context, 'Update failed', e.toString());
      }
    }
  }
}

class _GenderWidget extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
  _ProfileFormModel model = Provider.of(context);
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
    _ProfileFormModel model = Provider.of(context);
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

class _CountryWidget extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(10))),
        padding: EdgeInsets.all(10),
        child: FutureBuilder(
          future: ProfileUpdateService.current(context).readValidCountries(),
          builder: _buildInput,
          initialData: <Country>[],
        )
    );
  }

  Widget _buildInput(BuildContext context, AsyncSnapshot<List<Country>> snapshot) {
    _ProfileFormModel model = Provider.of(context);
    return DropdownButtonFormField<Country>(
      onChanged: model.setCountry,
      value: model.country,
      icon: Row(children: <Widget>[Icon(Icons.expand_more), SizedBox(width: 10)]),
      decoration: InputDecoration(
          hintText: 'Select country',
          icon: Icon(Icons.flag)),
      items: _buildItemList(context, snapshot.data),
      selectedItemBuilder: (context) => _buildItemList(context, snapshot.data),
      isExpanded: true,
    );
  }

  List<DropdownMenuItem<Country>> _buildItemList(BuildContext context, List<Country> countryList) {
    return countryList.map(_buildItem).toList(growable: false);
  }

  DropdownMenuItem<Country> _buildItem(Country country) => DropdownMenuItem(
      key: ValueKey(country.code),
      value: country,
      child: Row(children: <Widget>[
          Expanded(child:Text(country.name, overflow: TextOverflow.ellipsis,)),
          SizedBox(width: 5,),
          Image.asset('images/flags/${country.code.toLowerCase()}.png', width: 25, height: 15, fit: BoxFit.contain,),
      ])

  );
}

class _BiographyWidget extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    _ProfileFormModel model = Provider.of(context);
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(10))),
      padding: EdgeInsets.all(10),
      child: TextFormField(
        initialValue: model.biography,
        keyboardType: TextInputType.multiline,
        onSaved: model.setBiography,
        maxLines: 10,
        minLines: 5,
        decoration: InputDecoration(
            hintText: 'Biography',
            icon: Icon(Icons.assignment)),
        validator: MaxLengthValidator(4000, errorText: "Maximum 4000 characters allowed"),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  _SaveButton({@required this.onSave});

  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: double.infinity,
        height: 40,
        child:
        RaisedButton(
          child: Text('Save',
              style: Theme.of(context).textTheme.button),
          onPressed: onSave,
          color: Theme.of(context).buttonColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                  Radius.circular(20))),
        )
    );
  }
}

class ProfileEditorPage extends StatefulWidget {
  @override
  _ProfileEditorPageState createState() => _ProfileEditorPageState();
}

abstract class _BaseProfilePageState<T extends StatefulWidget> extends BasePageState<T> {
  _BaseProfilePageState(String pageName) : super(pageName);

  StreamSubscription<AvatarUploadProgress> uploadProgressSubscription;
  String _uploadTaskId;

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

class _ProfileEditorPageState extends _BaseProfilePageState<ProfileEditorPage> {

  _ProfileEditorPageState() : super(AppRoute.ProfileEditor);

  void _onSave() {
    EventBus.current(context).fire(_ProfileAction.save);
  }

  @override
  AppBar buildAppBar() {
    return AppBar(title: Text('Edit profile'),
        actions: <Widget>[
          IconButton(onPressed: _choosePicture, icon: Icon(Icons.account_circle)),
          IconButton(onPressed: _onSave, icon: Icon(Icons.done)),
          SizedBox(width: 20)
        ]
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return ListView(
      children: <Widget>[
        ProfileHeader(tapCallback: _choosePicture, uploadTaskId: _uploadTaskId),
        _ProfileForm(),
      ],
    );
  }
}

class ProfileViewerPage extends StatefulWidget {
  @override
  _ProfileViewerPageState createState() => _ProfileViewerPageState();
}

class _ProfileViewerPageState extends _BaseProfilePageState<ProfileViewerPage> {

  final _tabSelectionModel = _ProfileTabSelectionModel();

  _ProfileViewerPageState() : super(AppRoute.ProfileViewer);

  @override
  AppBar buildAppBar() {
    return AppBar(title: Text("My profile"),
      actions: <Widget>[
        IconButton(onPressed: _choosePicture, icon: Icon(Icons.account_circle)),
        IconButton(onPressed: _editProfile, icon: Icon(Icons.assignment_ind)),
        SizedBox(width: 20),
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

  void _editProfile() {
    Navigator.of(context).pushNamed(AppRoute.ProfileEditor);
  }

  @override
  Widget buildBody(BuildContext context) {
    return ListView(
      children: <Widget>[
        ProfileHeader(tapCallback: _choosePicture, uploadTaskId: _uploadTaskId),
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
            title: Text('My info'),
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
      return _ProfileInformationPanel();
    }
    return SizedBox(height: 0, width: 0);
  }
}

class _ProfileInformationPanel extends StatelessWidget {
  static final birthdateFormat = DateFormat('d MMM yyyy');
  
  @override
  Widget build(BuildContext context) {

    return FutureBuilder(
      future: findCountry(context),
      builder: _buildContent,
    );
  }

  Future<Country> findCountry(BuildContext context) {
    final profile = Provider.of<UserProfile>(context, listen: false);
    if (profile.country == null) {
      return null;
    }
    return ProfileUpdateService.current(context).findCountry(profile.country);
  }

  Widget _buildContent(BuildContext context, AsyncSnapshot<Country> countrySnapshot) {
    if (countrySnapshot.connectionState == ConnectionState.waiting) {
      return LoadingCircle();
    }

    final profile = Provider.of<UserProfile>(context);
    return Column(
      children: <Widget>[
        ListTile(leading: Icon(Icons.wc), title: Text('Gender'), subtitle: profile.gender != null ? _buildGender(fromGenderName(profile.gender)) : null, dense: true),
        Divider(height: 5.0),
        ListTile(leading: Icon(Icons.cake), title: Text('Birthdate'), subtitle: profile.birthdate != null ? _buildBirthdate(DateTime.parse(profile.birthdate)) : null, dense: true),
        Divider(height: 5.0),
        ListTile(leading: Icon(Icons.flag), title: Text('Country'), subtitle: countrySnapshot.hasData ? _buildCountry(countrySnapshot.data) : null, dense: true),
        Divider(height: 5.0),
        ListTile(leading: Icon(Icons.assignment), title: Text('Biography'), subtitle: profile.biography != null ? Text(profile.biography, style: TextStyle(fontSize: 16), maxLines: 50) : null, dense: true),
      ],
    );
  }

  Widget _buildBirthdate(DateTime birthdate) {
    return Text(birthdateFormat.format(birthdate), style: TextStyle(fontSize: 16));
  }

  Widget _buildGender(Gender gender) {
    if (gender == Gender.FEMALE) {
      return Row(children: <Widget>[
        Text('Female', style: TextStyle(fontSize: 16)),
        SizedBox(width: 5),
        Text('\u{2640}', style: TextStyle(fontSize: 16, color: Colors.purple, fontWeight: FontWeight.bold, textBaseline: TextBaseline.ideographic)),
      ]);
    } else if (gender == Gender.MALE) {
      return Row(children: <Widget>[
        Text('Male', style: TextStyle(fontSize: 16)),
        SizedBox(width: 5),
        Text('\u{2642}', style: TextStyle(fontSize: 16, color: Colors.blue, fontWeight: FontWeight.bold, textBaseline: TextBaseline.ideographic)),
      ]);
    } else {
      return Text('Other', style: TextStyle(fontSize: 16));
    }
  }

  Widget _buildCountry(Country country) {
    return Row(children: <Widget>[
      Text(country.name, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16)),
      SizedBox(width: 5,),
      Image.asset('images/flags/${country.code.toLowerCase()}.png', width: 25, height: 15, fit: BoxFit.contain,),
    ]);
  }
}

class ProfileHeader extends StatelessWidget {
  final GestureTapCallback tapCallback;
  final String uploadTaskId;

  ProfileHeader({this.tapCallback, this.uploadTaskId});

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
        child: ProfileAvatar(radius: 120.0, imageUri: profile.imageUri, online: null, uploadTaskId: uploadTaskId)
    );
  }
}
