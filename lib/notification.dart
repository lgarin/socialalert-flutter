import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/base.dart';
import 'package:social_alert_app/service/configuration.dart';
import 'package:social_alert_app/service/dataobjet.dart';
import 'package:social_alert_app/service/eventbus.dart';
import 'package:social_alert_app/service/geolocation.dart';
import 'package:social_alert_app/service/mediaquery.dart';
import 'package:social_alert_app/service/servernotification.dart';

class MediaNotificationPage extends StatefulWidget {

  @override
  _MediaNotificationPageState createState() => _MediaNotificationPageState();
}

class _MediaNotificationPageState extends BasePageState<MediaNotificationPage> {

  _MediaNotificationPageState() : super(AppRoute.MediaNotification);

  void _onSave() {
    EventBus.of(context).fire(_MediaNotificationAction.save);
  }

  @override
  AppBar buildAppBar() {
    return AppBar(
        title: Text('My Notifications'),
        actions: <Widget>[
          IconButton(onPressed: _onSave, icon: Icon(Icons.done), tooltip: 'Save changes',),
          SizedBox(width: 20)
        ]
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return FutureBuilder(
      future: ServerNotification.of(context).getCurrentLiveQuery(),
      builder: _buildContent,
    );
  }

  Widget _buildContent(BuildContext context, AsyncSnapshot<MediaQueryInfo> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return LoadingCircle();
    }
    return SingleChildScrollView(
      child: _MediaNotificationForm(snapshot.data),
    );
  }
}

class _MediaNotificationFormModel extends ChangeNotifier {
  static final _thresholdValues = [1, 5, 10, 50, 100, 500, 1000];

  String _label;
  String _keyword;
  String _selectedCategory;
  double _radius;
  LatLng _center;
  double _thresholdIndex = 3.0;

  final keywordController = TextEditingController();

  _MediaNotificationFormModel.fromInfo(MediaQueryInfo info) :
        _label = info.label,
        _keyword = info.keywords,
        _selectedCategory = info.category,
        _radius = info.location.radius,
        _center = LatLng(info.location.latitude, info.location.longitude),
        _thresholdIndex = _thresholdValues.indexOf(info.hitThreshold).toDouble() ?? 3.0 {
    keywordController.text = _keyword;
  }

  _MediaNotificationFormModel();

  String get label => _label;
  String get keyword => _keyword;
  String get selectedCategory => _selectedCategory;
  double get radius => _radius;
  LatLng get center => _center;
  double get thresholdIndex => _thresholdIndex;
  int get threshold => _thresholdValues[_thresholdIndex.toInt()];
  String get thresholdLabel => threshold.toString();

  void setLabel(String newLabel) => _label = newLabel;

  void setKeyword(String newKeyword) {
    _keyword = newKeyword;
    keywordController.text = newKeyword;
  }

  void setSelectedCategory(String newCategory) {
    _selectedCategory = newCategory;
  }

  void setMapPosition(CameraPosition position) {
    _radius = _toDistance(position.zoom);
    _center = position.target;
    // TODO mark dirty
  }

  double get zoom {
    if (_radius == null) {
      return 13.0;
    }
    return 13.0 - log(_radius / 1000.0) * log2e;
  }

  static double _toDistance(double zoom) {
    // 13 -> 1000m,
    return pow(2, 13.0 - zoom) * 1000.0;
  }

  void updateCircle() {
    notifyListeners();
  }

  void setThresholdIndex(double value) {
    if (value != _thresholdIndex) {
      _thresholdIndex = value;
      notifyListeners();
      // TODO mark dirty
    }
  }

  MediaQueryParameter toUpdateRequest() => MediaQueryParameter(
      label: label,
      category: selectedCategory,
      keywords: keyword,
      hitThreshold: threshold,
      radius: radius,
      latitude: center.latitude,
      longitude: center.longitude,
  );
}

class _MediaNotificationForm extends StatefulWidget {
  final MediaQueryInfo info;

  _MediaNotificationForm(this.info);

  @override
  _MediaNotificationFormState createState() => _MediaNotificationFormState();
}

enum _MediaNotificationAction {
  save,
}

class _MediaNotificationFormState extends State<_MediaNotificationForm> {
  static const backgroundColor = Color.fromARGB(255, 240, 240, 240);

  final _formKey = GlobalKey<FormState>();
  _MediaNotificationFormModel _formModel;
  bool _dirty;
  StreamSubscription<_MediaNotificationAction> _actionSubscription;

  @override
  void initState() {
    super.initState();
    _dirty = false;
    _formModel = widget.info != null ? _MediaNotificationFormModel.fromInfo(widget.info) : _MediaNotificationFormModel();
    _actionSubscription = EventBus.of(context).on<_MediaNotificationAction>().listen((action) {
      if (action == _MediaNotificationAction.save) {
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
      child: ChangeNotifierProvider.value(
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
              _LabelFormField(),
              SizedBox(height: 5),
              _CategoryWidget(_formModel),
              SizedBox(height: 5),
              _KeywordSearchWidget(),
              SizedBox(height: 10),
              _MapWidget(),
              SizedBox(height: 10),
              _ThresholdWidget(),
              SizedBox(height: 10),
              _MediaNotificationSaveButton(onSave: _onSave)
            ]
        )
    );
  }

  void _onSave() async {
    final form = _formKey.currentState;
    if (form != null && form.validate()) {
      form.save();
      try {
        await ServerNotification.of(context).setCurrentLiveQuery(_formModel.toUpdateRequest());
        _dirty = false;
        await Navigator.of(context).maybePop();
        showSuccessSnackBar(context, 'Your live query has been saved');
      } catch (e) {
        showSimpleDialog(context, 'Update failed', e.toString());
      }
    }
  }
}

class _LabelFormField extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    _MediaNotificationFormModel model = Provider.of(context, listen: false);
    return WideRoundedField(
      child: TextFormField(
        initialValue: model.label,
        onSaved: model.setLabel,
        decoration: InputDecoration(
            hintText: 'Label',
            icon: Icon(Icons.label)),
        validator: MultiValidator([
            MaxLengthValidator(50, errorText: "Maximum 50 characters allowed"),
            NonEmptyValidator(errorText: "Label required")
        ])
      ),
    );
  }
}

class _CategoryWidget extends StatefulWidget {

  final _MediaNotificationFormModel model;

  _CategoryWidget(this.model);

  @override
  _CategoryWidgetState createState() => _CategoryWidgetState();
}

class _CategoryWidgetState extends State<_CategoryWidget> {
  int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = categoryTokens.indexOf(widget.model.selectedCategory);
    if (_selectedIndex < 0) {
      _selectedIndex = null;
    }
  }

  void _onSelected(int index) {
    setState(() {
      _selectedIndex = index;
      widget.model.setSelectedCategory(index == null ? '' : categoryTokens[index]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
        spacing: 5,
        children: List.generate(categoryLabels.length,
                (index) => ChoiceChip(
              key: ValueKey<String>(categoryTokens[index]),
              label: Text(categoryLabels[index]),
              selected: _selectedIndex == index,
              onSelected: (selected) => _onSelected(selected ? index : null),
              labelStyle: TextStyle(color: Colors.white),
              selectedColor: Theme.of(context).primaryColor,
            )
        )
    );
  }
}

class _KeywordSearchWidget extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return WideRoundedField(child: _buildInput(context));
  }

  TypeAheadField<String> _buildInput(BuildContext context) {
    _MediaNotificationFormModel model = Provider.of(context, listen: false);
    return TypeAheadField<String>(
      direction: AxisDirection.up,
      suggestionsBoxDecoration: SuggestionsBoxDecoration(borderRadius: BorderRadius.all(Radius.circular(5))),
      textFieldConfiguration: TextFieldConfiguration(
          controller: model.keywordController,
          onSubmitted: model.setKeyword, // TODO seems to be a bug with type inference
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            filled: false,
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
            hintText: "Keyword",
            icon: Icon(Icons.search),
          )
      ),
      itemBuilder: (context, suggestion) => ListTile(title: Text(suggestion)),
      errorBuilder: (context, error) => null,
      noItemsFoundBuilder: (context) => null,
      loadingBuilder: (context) => null,
      suggestionsCallback: (pattern) => _fetchSuggestions(context, pattern),
      hideOnError: true,
      hideOnEmpty: true,
      hideOnLoading: true,
      onSuggestionSelected: model.setKeyword,
      debounceDuration: Duration(milliseconds: 500),
    );
  }

  Future<List<String>> _fetchSuggestions(BuildContext context, String pattern) {
    return MediaQueryService.of(context).suggestTags(pattern, 5);
  }
}

class _MapWidget extends StatelessWidget {
  static const minZoomLevel = 5.0;
  static const maxZoomLevel = 20.0;
  static const defaultZoomLevel = 15.0;

  Future<GeoPosition> _readLastKnownPosition(BuildContext context) async {
    final position = await GeoLocationService.of(context).readLastKnownPosition();
    if (position == null) {
      await showSimpleDialog(context, 'No GPS signal', 'Current position not available');
    }
    return position;
  }

  Widget _buildContent(BuildContext context, AsyncSnapshot<GeoPosition> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return LoadingCircle();
    } else if (snapshot.hasData) {
      final position = CameraPosition(zoom: defaultZoomLevel, target: LatLng(snapshot.data.latitude, snapshot.data.longitude));
      return _buildMap(context, position);
    } else {
      final position = CameraPosition(zoom: minZoomLevel, target: LatLng(46.8182, 8.2275));
      return _buildMap(context, position);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(height: 250,
      decoration: BoxDecoration(
      border: Border.all(color: Colors.grey)),
      child: FutureBuilder(
          future: _readLastKnownPosition(context),
          builder: _buildContent
        )
    );
  }

  Widget _buildMap(BuildContext context, CameraPosition position) {
    _MediaNotificationFormModel model = Provider.of(context);
    if (model.radius == null) {
      model.setMapPosition(position);
    } else {
      position = CameraPosition(target: model.center, zoom: model.zoom);
    }
    return GoogleMap(
          mapType: MapType.normal,
          minMaxZoomPreference: MinMaxZoomPreference(minZoomLevel, maxZoomLevel),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          compassEnabled: false,
          initialCameraPosition: position,
          circles: {Circle(circleId: CircleId("center"), center: model.center, radius: model.radius, strokeColor: Colors.red)},
          onCameraMove: model.setMapPosition,
          onCameraIdle: model.updateCircle,
        );
  }
}

class _ThresholdWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    _MediaNotificationFormModel model = Provider.of(context);
    return WideRoundedField(child: Slider(
      value: model.thresholdIndex,
      min: 0, max: 6, divisions: 6,
      label: model.thresholdLabel,
      onChanged: model.setThresholdIndex)
    );
  }

}

class _MediaNotificationSaveButton extends StatelessWidget {
  _MediaNotificationSaveButton({@required this.onSave});

  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return WideRoundedButton(
      text: 'Save',
      onPressed: onSave,
    );
  }
}