import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/base.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/commentquery.dart';
import 'package:social_alert_app/service/configuration.dart';
import 'package:social_alert_app/service/eventbus.dart';
import 'package:social_alert_app/service/dataobjet.dart';
import 'package:social_alert_app/service/mediaquery.dart';
import 'package:social_alert_app/service/profileupdate.dart';
import 'package:social_alert_app/thumbnail.dart';
import 'package:timeago_flutter/timeago_flutter.dart';

class ProfileAvatar extends StatelessWidget {
  static const LARGE_RADIUS = 60.0;

  final String imageUri;
  final bool online;
  final double radius;
  final String uploadTaskId;
  final GestureTapCallback tapCallback;

  ProfileAvatar({this.imageUri, this.online, @required this.radius, this.uploadTaskId, this.tapCallback});

  @override
  Widget build(BuildContext context) {
    final url = imageUri != null ? MediaQueryService.toAvatarUrl(imageUri, radius < LARGE_RADIUS) : null;
    return GestureDetector(
      onTap: tapCallback,
      child: Container(
        width: radius,
        height: radius,
        decoration: _buildDecoration(url, context),
        child: uploadTaskId != null ? _buildUploadProgress() : SizedBox(height: 0, width: 0),
      )
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
  static const galleryIndex = 1;
  static const feedIndex = 2;

  int _currentDisplayIndex = informationIndex;

  int get currentDisplayIndex => _currentDisplayIndex;
  bool get informationSelected => _currentDisplayIndex == informationIndex;
  bool get gallerySelected => _currentDisplayIndex == galleryIndex;
  bool get feedSelected => _currentDisplayIndex == feedIndex;

  void tabSelected(int index) {
    _currentDisplayIndex = index;
    notifyListeners();
  }
}

class _ProfileFormModel {
  Gender _gender;
  Country _country;
  String _biography;
  int _birthdateDay;
  int _birthdateMonth;
  int _birthdateYear;

  _ProfileFormModel(UserProfile profile) {
    _country = profile.country != null ? Country(profile.country, null) : null;
    _biography = profile.biography;
    final birthdate = profile.birthdate != null ? DateTime.parse(profile.birthdate) : null;
    _birthdateDay = birthdate?.day;
    _birthdateMonth = birthdate?.month;
    _birthdateYear = birthdate?.year;
    _gender = fromGenderName(profile.gender);
  }

  int get birthdateDay => _birthdateDay;
  void setBithdateDay(int value) => _birthdateDay = value;
  int get birthdateMonth => _birthdateMonth;
  void setBithdateMonth(int value) => _birthdateMonth = value;
  int get birthdateYear => _birthdateYear;
  void setBithdateYear(int value) => _birthdateYear = value;

  String validateBirthdateYear(int value) {
    if (value != null) {
      if (value < 1900 || value > 2100) {
        return 'Invalid year';
      }
    }
    if (value == null) {
      if (_birthdateDay != null || _birthdateMonth != null) {
        return 'Select year';
      }
    }
    return null;
  }

  String validateBirthdateMonth(int value) {
    if (value != null) {
      if (value < 1 || value > 12) {
        return 'Invalid month';
      }
    }
    if (value == null) {
      if (_birthdateDay != null || _birthdateYear != null) {
        return 'Select month';
      }
    }
    return null;
  }

  String validateBirthdateDay(int value) {
    if (value != null) {
      if (value < 1 || value > 31) {
        return 'Invalid date';
      }
      if (_birthdateYear != null && _birthdateMonth != null) {
        final date = DateTime(_birthdateYear, _birthdateMonth, value);
        if (date.day != value) {
          return 'Invalid date';
        }
      }
    }
    if (value == null) {
      if (_birthdateMonth != null || _birthdateYear != null) {
        return 'Select date';
      }
    }
    return null;
  }

  Gender get gender => _gender;
  void setGender(Gender newGender) => _gender = newGender;

  Country get country => _country;
  void setCountry(Country newCountry) => _country = newCountry;

  String get biography => _biography;
  void setBiography(String newBiography) => _biography = newBiography;

  ProfileUpdateRequest toUpdateRequest() => ProfileUpdateRequest(biography: biography, birthdate: DateTime.utc(birthdateYear, birthdateMonth, birthdateDay), country: country, gender: gender);
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
            _GenderFormField(),
            SizedBox(height: 5),
            _BirthdateFormField(),
            SizedBox(height: 5),
            _CountryFormField(),
            SizedBox(height: 5),
            _BiographyFormField(),
            SizedBox(height: 10),
            _ProfileSaveButton(onSave: _onSave)
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
        showSuccessSnackBar(context, 'Your profile has been updated');
      } catch (e) {
        showSimpleDialog(context, 'Update failed', e.toString());
      }
    }
  }
}

class _GenderFormField extends StatelessWidget {

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
              child: _GenderWidget(Gender.FEMALE)
          ),
          DropdownMenuItem<Gender>(value: Gender.MALE,
            child: _GenderWidget(Gender.MALE)
          ),
          DropdownMenuItem<Gender>(value: Gender.OTHER,
            child: _GenderWidget(Gender.OTHER)
          ),
        ],
      ),
    );
  }
}

class _BirthdateFormField extends StatelessWidget {
  static final _monthFormatter = DateFormat('MMM');
  static final _maxYear = DateTime.now().year;
  static final _minYear = _maxYear - 100;
  static final _monthNames = [for (int i = 1; i <= 12; i++) _monthFormatter.format(DateTime(2000, i, 1))];

  @override
  Widget build(BuildContext context) {
    _ProfileFormModel model = Provider.of(context);
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(10))),
      padding: EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Flexible(child: _buildDayDropdown(model)),
          SizedBox(width: 10),
          Flexible(child: _buildMonthDropdown(model)),
          SizedBox(width: 10),
          Flexible(child: _buildYearDropdown(model)),
        ],
      )
    );
  }

  DropdownMenuItem<int> _buildDropdownMenuItem(int value, String text) {
    return DropdownMenuItem(
      value: value,
      child: Text(text),
    );
  }

  DropdownButtonFormField<int> _buildYearDropdown(_ProfileFormModel model) {
    return DropdownButtonFormField(
          onChanged: model.setBithdateYear,
          value: model.birthdateYear,
          hint: Text('Year'),
          icon: Row(children: <Widget>[Icon(Icons.expand_more), SizedBox(width: 10)]),
          items: [for(var i=_minYear; i<_maxYear; i+=1) _buildDropdownMenuItem(i, i.toString())],
          validator: model.validateBirthdateYear,
        );
  }

  DropdownButtonFormField<int> _buildMonthDropdown(_ProfileFormModel model) {
    return DropdownButtonFormField(
            onChanged: model.setBithdateMonth,
            value: model.birthdateMonth,
            hint: Text('Month'),
            icon: Row(children: <Widget>[Icon(Icons.expand_more), SizedBox(width: 10)]),
            items: [for(var i=1; i<=12; i+=1) _buildDropdownMenuItem(i, _monthNames[i-1])],
            validator: model.validateBirthdateMonth,
          );
  }

  DropdownButtonFormField<int> _buildDayDropdown(_ProfileFormModel model) {
    return DropdownButtonFormField(
          onChanged: model.setBithdateDay,
          value: model.birthdateDay,
          decoration: InputDecoration(icon: Icon(Icons.cake)),
          hint: Text('Day'),
          icon: Row(children: <Widget>[Icon(Icons.expand_more), SizedBox(width: 10)]),
          items: [for(var i=1; i<=31; i+=1) _buildDropdownMenuItem(i, i.toString())],
          validator: model.validateBirthdateDay,
        );
  }
}

class _CountryFormField extends StatelessWidget {

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
      items: _buildItemList(context, snapshot.data, true),
      selectedItemBuilder: (context) => _buildItemList(context, snapshot.data, false),
      isExpanded: true,
    );
  }

  List<DropdownMenuItem<Country>> _buildItemList(BuildContext context, List<Country> countryList, bool expandName) {
    return countryList.map((country) => _buildItem(country, expandName)).toList(growable: false);
  }

  DropdownMenuItem<Country> _buildItem(Country country, bool expandName) => DropdownMenuItem(
      key: ValueKey(country.code),
      value: country,
      child: _CountryWidget(country, expandName: expandName)
  );
}

class _BiographyFormField extends StatelessWidget {

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

class _ProfileSaveButton extends StatelessWidget {
  _ProfileSaveButton({@required this.onSave});

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
          IconButton(onPressed: _choosePicture, icon: Icon(Icons.account_circle), tooltip: 'Change avatar',),
          IconButton(onPressed: _onSave, icon: Icon(Icons.done), tooltip: 'Save changes',),
          SizedBox(width: 20)
        ]
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return ListView(
      children: <Widget>[
        ProfileHeader(tapCallback: _choosePicture, uploadTaskId: _uploadTaskId, tapTooltip: 'Change avatar',),
        _ProfileForm(),
      ],
    );
  }
}

class ProfileViewerPage extends StatefulWidget {
  final UserProfile profileOverride;

  ProfileViewerPage(this.profileOverride);

  @override
  _ProfileViewerPageState createState() => _ProfileViewerPageState(profileOverride);
}

class _ProfileViewerPageState extends _BaseProfilePageState<ProfileViewerPage> {

  final _tabSelectionModel = _ProfileTabSelectionModel();
  final _scrollController = ScrollController();
  UserProfile profileOverride;

  _ProfileViewerPageState(this.profileOverride) : super(AppRoute.ProfileViewer);

  @override
  void initState() {
    super.initState();
    _tabSelectionModel.addListener(() => WidgetsBinding.instance.addPostFrameCallback((_) => _scrollController.jumpTo(_scrollController.position.maxScrollExtent)));
  }

  @override
  AppBar buildAppBar() {
    if (profileOverride != null) {
      return _buildProfileAppBar(profileOverride);
    }
    return _buildOwnAppBar();
  }

  AppBar _buildOwnAppBar() {
    return AppBar(title: Text('My profile'),
    actions: <Widget>[
      IconButton(onPressed: _choosePicture, icon: Icon(Icons.account_circle), tooltip: 'Change avatar'),
      IconButton(onPressed: _editProfile, icon: Icon(Icons.assignment_ind), tooltip: 'Edit profile'),
      SizedBox(width: 20),
    ]
  );
  }

  AppBar _buildProfileAppBar(UserProfile profile) {
    return AppBar(title: Text(profile.username, overflow: TextOverflow.ellipsis),
        actions: <Widget>[
          IconButton(
              onPressed: _changeNetwork,
              icon: Icon(profile.followed ? Icons.speaker_notes_off : Icons.speaker_notes),
              tooltip: profile.followed ? 'Unfollow' : 'Follow',
          ),
          SizedBox(width: 20),
        ]
    );
  }

  void _followUser() async {
    try {
      final newProfile = await ProfileUpdateService.current(context).followUser(profileOverride.userId);
      super.showSuccessSnackBar('User "${profileOverride.username}" has been added to your network');
      setState(() {
        profileOverride = newProfile;
      });
    } catch (e) {
      showSimpleDialog(context, 'Update failure', e.toString());
    }
  }

  void _unfollowUser() async {
    try {
      final newProfile = await ProfileUpdateService.current(context).unfollowUser(profileOverride.userId);
      super.showWarningSnackBar('User "${profileOverride.username}" has been removed from your network');
      setState(() {
        profileOverride = newProfile;
      });
    } catch (e) {
      showSimpleDialog(context, 'Update failure', e.toString());
    }
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

  Widget _buildProfileOverrideProvider({Widget child}) {
    if (profileOverride != null) {
      return Provider.value(value: profileOverride, child: child);
    }
    return child;
  }

  @override
  Widget buildBody(BuildContext context) {
    return WillPopScope(
      onWillPop: _onPageExit,
      child: ListView(
        controller: _scrollController,
        children: <Widget>[
          _buildProfileHeader(),
          _buildBottomPanel(context),
        ],
      )
    );
  }

  Future<bool> _onPageExit() {
    Navigator.pop(context, profileOverride);
    return Future.value(false);
  }

  void _changeNetwork() async {
    final message = 'Do you want to ${profileOverride.followed ? "stop" : "start"} following this user?';
    if (await showConfirmDialog(context, 'Update network', message)) {
      profileOverride.followed ? _unfollowUser() : _followUser();
    }
  }

  Widget _buildProfileHeader() {
    return _buildProfileOverrideProvider(
          child: ProfileHeader(
            tapCallback: profileOverride == null ? _choosePicture : _changeNetwork,
            tapTooltip: profileOverride == null ? 'Change avatar' : (profileOverride.followed ? 'Unfollow' : 'Follow'),
            uploadTaskId: _uploadTaskId
          )
      );
  }

  Widget _buildBottomPanel(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _tabSelectionModel,
      child: _buildProfileOverrideProvider(child: _ProfileTabPanel()),
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
            title: Text('About'),
          ),
          new BottomNavigationBarItem(
            icon: Icon(Icons.panorama),
            title: Text('Snypes'),
          ),
          new BottomNavigationBarItem(
            icon: Icon(Icons.create),
            title: Text('Scribes'),
          )
        ]
    );
  }
}

class _ProfileTabPanel extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final tabSelectionModel = Provider.of<_ProfileTabSelectionModel>(context);
    final profile = Provider.of<UserProfile>(context);
    if (tabSelectionModel.informationSelected) {
      return _ProfileInformationPanel(profile);
    } else if (tabSelectionModel.gallerySelected) {
      return _ProfileGalleryPanel(profile.userId);
    } else if (tabSelectionModel.feedSelected) {
      return _UserCommentList(profile.userId);
    } else {
      return null;
    }
  }
}

class _ProfileInformationPanel extends StatelessWidget {
  static final birthdateFormat = DateFormat('d MMM yyyy');

  final UserProfile _profile;

  _ProfileInformationPanel(this._profile);

  @override
  Widget build(BuildContext context) {

    return FutureBuilder(
      future: findCountry(context),
      builder: _buildContent,
    );
  }

  Future<Country> findCountry(BuildContext context) {
    if (_profile.country == null) {
      return null;
    }
    return ProfileUpdateService.current(context).findCountry(_profile.country);
  }

  Widget _buildContent(BuildContext context, AsyncSnapshot<Country> countrySnapshot) {
    if (countrySnapshot.connectionState == ConnectionState.waiting) {
      return LoadingCircle();
    }

    return Column(
      children: <Widget>[
        ListTile(leading: Icon(Icons.wc),
            title: Text('Gender'),
            subtitle: _profile.gender != null ? _buildGender() : null,
            dense: true),
        Divider(height: 5.0),
        ListTile(leading: Icon(Icons.cake),
            title: Text('Birthdate'),
            subtitle: _profile.birthdate != null ? _buildBirthdate() : null,
            dense: true),
        Divider(height: 5.0),
        ListTile(leading: Icon(Icons.flag),
            title: Text('Country'),
            subtitle: countrySnapshot.hasData ? _buildCountry(countrySnapshot.data) : null,
            dense: true),
        Divider(height: 5.0),
        ListTile(leading: Icon(Icons.assignment),
            title: Text('Biography'),
            subtitle: _profile.biography != null ? _buildBiography() : null,
            dense: true),
      ],
    );
  }

  Text _buildBiography() => Text(_profile.biography, style: TextStyle(fontSize: 16), maxLines: 50);

  Widget _buildBirthdate() {
    final birthdate = DateTime.parse(_profile.birthdate);
    return Text(birthdateFormat.format(birthdate), style: TextStyle(fontSize: 16));
  }

  Widget _buildGender() {
    final gender = fromGenderName(_profile.gender);
    return _GenderWidget(gender, fontSize: 16.0);
  }

  Widget _buildCountry(Country country) {
    return _CountryWidget(country, fontSize: 16.0);
  }
}

class _GenderWidget extends StatelessWidget {
  _GenderWidget(this.gender, {this.fontSize});

  final Gender gender;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    if (gender == Gender.FEMALE) {
      return Row(children: <Widget>[
        Text('Female', style: TextStyle(fontSize: fontSize)),
        SizedBox(width: 5),
        Text('\u{2640}', style: TextStyle(fontSize: fontSize, color: Colors.purple, fontWeight: FontWeight.bold, textBaseline: TextBaseline.ideographic)),
      ]);
    } else if (gender == Gender.MALE) {
      return Row(children: <Widget>[
        Text('Male', style: TextStyle(fontSize: fontSize)),
        SizedBox(width: 5),
        Text('\u{2642}', style: TextStyle(fontSize: fontSize, color: Colors.blue, fontWeight: FontWeight.bold, textBaseline: TextBaseline.ideographic)),
      ]);
    } else {
      return Text('Other', style: TextStyle(fontSize: fontSize));
    }
  }
}

class _CountryWidget extends StatelessWidget {
  _CountryWidget(this.country, {this.fontSize, this.expandName = false});

  final double fontSize;
  final Country country;
  final bool expandName;

  @override
  Widget build(BuildContext context) {
    return Row(children: <Widget>[
      _buildCountryName(),
      SizedBox(width: 5,),
      _CountryFlagWidget(country.code),
    ]);
  }

  Widget _buildCountryName() {
    final text = Text(country.name, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: fontSize));
    if (expandName) {
      return Expanded(child: text);
    }
    return Flexible(child: text);
  }
}

class _CountryFlagWidget extends StatelessWidget {
  _CountryFlagWidget(this.countryCode) : super(key: ValueKey(countryCode));

  final String countryCode;

  @override
  Widget build(BuildContext context) {
    return Image.asset('images/flags/${countryCode.toLowerCase()}.png', width: 25, height: 15, fit: BoxFit.contain);
  }
}

class _ProfileGalleryPanel extends StatefulWidget {

  final String userId;

  _ProfileGalleryPanel(this.userId) : super(key: ValueKey(userId));

  @override
  _ProfileGalleryPanelState createState() => _ProfileGalleryPanelState();
}

class _ProfileGalleryPanelState extends BasePagingState<_ProfileGalleryPanel, MediaInfo> {
  static final spacing = 4.0;

  Future<MediaInfoPage> loadNextPage(PagingParameter parameter) {
    return MediaQueryService.current(context).listUserMedia(widget.userId, parameter);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height - ProfileHeader.height;
    return SizedBox(height: height, child: super.build(context));
  }

  Widget buildContent(BuildContext context, List<MediaInfo> data) {
    if (data.isEmpty) {
      return Center(child: _buildNoContent(context));
    }

    final portrait = MediaQuery.of(context).orientation == Orientation.portrait;
    return GridView.count(
        crossAxisCount: portrait ? 2 : 3,
        childAspectRatio: 16.0 / 9.0,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        padding: EdgeInsets.all(spacing),
        children: data.map(_buildGridTile).toList()
    );
  }

  Widget _buildGridTile(MediaInfo media) {
    return MediaThumbnailTile(media: media, onTapCallback: _onGridTileSelection);
  }

  void _onGridTileSelection(MediaInfo media) async {
    final newValue = await Navigator.of(context).pushNamed<MediaDetail>(AppRoute.RemotePictureDetail, arguments: media);
    if (newValue != null) {
      replaceItem((item) => item.mediaUri == media.mediaUri, newValue);
    }
  }

  Column _buildNoContent(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(Icons.panorama, size: 100, color: Colors.grey),
        Text('No content yet', style: Theme
            .of(context)
            .textTheme
            .headline6),
        Text('Post a Snype and it will appear here.')
      ],
    );
  }
}

class _UserCommentList extends StatefulWidget {

  final String userId;

  _UserCommentList(this.userId) : super(key: ValueKey(userId));

  @override
  _UserCommentListState createState() => _UserCommentListState();
}

class _UserCommentListState extends BasePagingState<_UserCommentList, MediaCommentInfo> {

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height - ProfileHeader.height;
    return SizedBox(height: height, child: super.build(context));
  }

  @override
  Widget buildContent(BuildContext context, List<MediaCommentInfo> data) {
    if (data.isEmpty) {
      return _buildNoContent(context);
    }

    return ListView(
      children: ListTile.divideTiles(
        context: context,
        tiles: data.map(_buildTile).toList(),
      ).toList(),
    );
  }

  ListTile _buildTile(MediaCommentInfo commentInfo) {
    return ListTile(
      key: ValueKey(commentInfo.id),
      leading: _buildThumbnail(commentInfo),
      title: _buildTitle(commentInfo),
      subtitle: _buildContent(commentInfo),
    );
  }

  Widget _buildThumbnail(MediaCommentInfo commentInfo) {
    return GestureDetector(
      child: Image.network(MediaQueryService.toThumbnailUrl(commentInfo.media.mediaUri),
              fit: BoxFit.cover, cacheHeight: thumbnailHeight, cacheWidth: thumbnailWidth, width: 80, height: 45
      ),
      onTap: () => _onThumbnailSelection(commentInfo.media),
    );
  }

  void _onThumbnailSelection(MediaInfo media) async {
    print(media.mediaUri);
    await Navigator.of(context).pushNamed<MediaDetail>(AppRoute.RemotePictureDetail, arguments: media);
  }

  Widget _buildContent(MediaCommentInfo commentInfo) {
    return Row(
        children: <Widget>[
          Expanded(child: Text(commentInfo.comment, softWrap: true)),
          _buildStatistic(commentInfo)
        ]
    );
  }

  Row _buildTitle(MediaCommentInfo commentInfo) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(commentInfo.media.title, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.subtitle1,)),
        Timeago(date: commentInfo.creation,
          builder: (_, value) => Text(value, style: Theme.of(context).textTheme.caption.copyWith(fontStyle: FontStyle.italic)),
        )
      ],
    );
  }

  Column _buildStatistic(MediaCommentInfo commentInfo) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Row(children: <Widget>[
            Icon(Icons.thumb_up, size: 14),
            SizedBox(width: 4,),
            Text(commentInfo.likeCount.toString(), style: TextStyle(fontSize: 12)),
          ]),
          SizedBox(height: 4),
          Row(children: <Widget>[
            Icon(Icons.thumb_down, size: 14),
            SizedBox(width: 4,),
            Text(commentInfo.dislikeCount.toString(), style: TextStyle(fontSize: 12)),
          ]),
        ]);
  }

  @override
  Future<ResultPage<MediaCommentInfo>> loadNextPage(PagingParameter parameter) {
    return CommentQueryService.current(context).listUserComments(widget.userId, parameter);
  }

  Column _buildNoContent(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(Icons.edit, size: 100, color: Colors.grey),
        Text('No content yet', style: Theme
            .of(context)
            .textTheme
            .headline6),
        Text('Post a Scribe and it will appear here.')
      ],
    );
  }
}

class ProfileHeader extends StatelessWidget {
  static const height = 220.0;

  final GestureTapCallback tapCallback;
  final String tapTooltip;
  final String uploadTaskId;

  ProfileHeader({this.tapCallback, this.uploadTaskId, this.tapTooltip});

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<UserProfile>(context);

    return Container(
        height: height,
        color: Theme.of(context).primaryColorDark.withOpacity(0.9),
        child: profile != null ? _buildPanel(context, profile) : LoadingCircle()
    );
  }

  Widget _wrapWithTooltip(Widget child, String tooltip) {
    if (tooltip != null) {
      return Tooltip(message: tooltip, child: child);
    }
    return child;
  }

  Widget _buildPanel(BuildContext context, UserProfile profile) {
    if (profile.followed) {
      return Stack(
        children: <Widget>[
          _buildLinkInfo(context, profile),
          _buildBody(context, profile),
        ],
      );
    }
    return _buildBody(context, profile);
  }

  Widget _buildLinkInfo(BuildContext context, UserProfile profile) {
    final textStyle = Theme.of(context).textTheme.caption.copyWith(fontStyle: FontStyle.italic, color: Colors.white);
    return Container(
        padding: EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Timeago(
              date: profile.followedSince,
              builder: (_, value) => Text('Followed since ' + value, style: textStyle),
            ),
          ],
        )
    );
  }

  Widget _buildBody(BuildContext context, UserProfile profile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _wrapWithTooltip(_buildProfileColumn(context, profile), tapTooltip),
        SizedBox(width: 20),
        _wrapWithTooltip(_buildStatisticColumn(context, profile), 'Show statistics'),
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
    return UsernameCountry(
        username: profile.username,
        country: profile.country,
        textStyle: Theme.of(context).textTheme.subtitle2
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
        child: ProfileAvatar(radius: 120.0, imageUri: profile.imageUri, uploadTaskId: uploadTaskId, tapCallback: tapCallback)
    );
  }
}

class UsernameCountry extends StatelessWidget {
  final String username;
  final String country;
  final TextStyle textStyle;

  const UsernameCountry({
    Key key,
    this.username,
    this.country,
    this.textStyle
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (country == null) {
      return Text(username, style: textStyle);
    }
    return Row(
      children: <Widget>[
        Text(username, style: textStyle),
        SizedBox(width: 4),
        _CountryFlagWidget(country)
      ],
    );
  }
}

class HorizontalUserStatistic extends StatelessWidget {
  HorizontalUserStatistic({
    Key key,
    @required this.statistic,
  }) : super(key: key);

  final UserStatistic statistic;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(Icons.people, size: 14, color: Colors.black),
        SizedBox(width: 4,),
        Text(statistic.followerCount.toString(), style: TextStyle(fontSize: 12, color: Colors.black)),
        Spacer(),
        Icon(Icons.thumb_up, size: 14, color: Colors.black),
        SizedBox(width: 4,),
        Text(statistic.likeCount.toString(), style: TextStyle(fontSize: 12, color: Colors.black)),
        Spacer(),
        Icon(Icons.panorama, size: 14, color: Colors.black),
        SizedBox(width: 4,),
        Text(statistic.mediaCount.toString(), style: TextStyle(fontSize: 12, color: Colors.black)),
        Spacer(),
        Icon(Icons.create, size: 14, color: Colors.black),
        SizedBox(width: 4,),
        Text(statistic.commentCount.toString(), style: TextStyle(fontSize: 12, color: Colors.black)),
      ],
    );
  }
}