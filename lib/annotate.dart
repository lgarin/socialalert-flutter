import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/session.dart';
import 'package:social_alert_app/upload.dart';
import 'helper.dart';

class CaptureModel {
  final DateTime timestamp;
  final File media;
  final Position position;
  final String country;
  final String locality;
  final String address;
  final title = TextEditingController();
  final description = TextEditingController();
  String selectedCategory;
  bool autovalidate = false;

  CaptureModel({this.media, this.position, this.country, this.locality, this.address})
      : timestamp = DateTime.now();

  String get titleInput => title.text.trim();

  String get descriptionInput => description.text;

  bool hasTitleInput() => titleInput != '';

  bool hasPosition() => position != null;
}

typedef PublishCallBack = void Function(CaptureModel);

class AnnotatePage extends StatefulWidget {

  final File media;

  AnnotatePage(this.media);

  @override
  _AnnotatePageState createState() => _AnnotatePageState();
}

class _AnnotatePageState extends State<AnnotatePage> {
  static const backgroundColor = Color.fromARGB(255, 240, 240, 240);
  final _formKey = GlobalKey<FormState>();
  bool _fullImage = false;

  @override
  Widget build(BuildContext context) {
    return FutureProvider<CaptureModel>(
        create: _createModel,
        lazy: false,
        child: Scaffold(
          backgroundColor: backgroundColor,
          appBar: _buildAppBar(context),
          body: _buildBody(context)
        )
    );
  }

  void _switchFullImage() {
    setState(() {
      _fullImage = !_fullImage;
    });
  }

  Widget _buildBody(BuildContext context) {
    if (_fullImage) {
      return buildImageContainer();
    }

    return ListView(
          children: <Widget>[
            buildImageContainer(),
            Transform.translate(
                offset: Offset(0, -20),
                child: buildMetadataContainer()
            )
          ],
        );
  }

  Container buildMetadataContainer() {
    return Container(
      decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))
      ),
      padding: EdgeInsets.only(left: 20, right: 20, top: 20),
      child: _MetadataForm(formKey: _formKey, onPublish: _onPublish),
    );
  }

  Container buildImageContainer() {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
        color: Colors.black,
        child: GestureDetector(
            onTap: _switchFullImage,
            child: _fullImage ?
              Image.file(widget.media, fit: BoxFit.contain, height: screenHeight) :
              Image.file(widget.media, fit: BoxFit.fitHeight, height: screenHeight / 3)
        )
    );
  }

  AppBar _buildAppBar(BuildContext context) {


    return AppBar(
      title: Text("Describe your Snype"),
        actions: <Widget>[
          _PublishIconButton(onPublish: _onPublish),
          SizedBox(width: 10),
          Icon(Icons.more_vert) // TODO show detail
        ]
    );
  }

  void _onPublish(CaptureModel model) async {
    final form = _formKey.currentState;
    if (form.validate()) {
      final upload = UploadTask(
        timestamp: model.timestamp,
        title: model.titleInput,
        path:  model.media.path,
        category: model.selectedCategory,
        description: model.descriptionInput,
        latitude: model.position?.latitude,
        longitude: model.position?.longitude,
        address: model.address,
        locality: model.locality,
        country: model.country,
      );

      print(upload.toJson());

      final accessToken = await UserSession.current(context).accessToken;
      final id = await UploadService().uploadImage(title: model.titleInput, accessToken: accessToken, file: model.media);
      // TODO start claim
    } else {
      setState(() {
        model.autovalidate = true;
      });
    }
  }

  Future<CaptureModel> _createModel(BuildContext context) async {
    final currentPlace = await UserSession.current(context).currentPlace;
    return CaptureModel(media: widget.media,
        position: currentPlace?.position,
        country: currentPlace?.isoCountryCode,
        locality: currentPlace?.locality,
        address: currentPlace?.name);
  }
}

class _PublishIconButton extends StatelessWidget {
  final PublishCallBack onPublish;

  _PublishIconButton({Key key, this.onPublish}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    VoidCallback onPressed;

    final model = Provider.of<CaptureModel>(context);
    if (model != null) {
      onPressed = () => onPublish(model);
    }

    return IconButton(icon: Icon(Icons.cloud_upload), onPressed: onPressed);
  }
}

class _MetadataForm extends StatelessWidget {

  _MetadataForm({
    Key key,
    @required this.formKey,
    @required this.onPublish,
  }) : super(key: key);

  final GlobalKey<FormState> formKey;
  final PublishCallBack onPublish;

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<CaptureModel>(context);
    if (model == null) {
      return LoadingCircle();
    }
    return Form(
        key: formKey,
        autovalidate: model.autovalidate,
        child: Column(
          children: <Widget>[
            _TitleWidget(model: model),
            SizedBox(height: 10),
            _CategoryWidget(model: model),
            SizedBox(height: 10),
            _DescriptionWidget(model: model),
            SizedBox(height: 10),
            _PublishButton(model: model, onPublish: onPublish)
          ],
        ));
  }
}

class _TitleWidget extends StatelessWidget {
  static const label = 'Title';

  _TitleWidget({
    Key key,
    @required this.model,
  }) : super(key: key);

  final CaptureModel model;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(10))),
      padding: EdgeInsets.all(10),
      child: TextFormField(
        autofocus: !model.hasTitleInput(),
        controller: model.title,
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
            hintText: label,
            icon: Icon(Icons.title)),
        validator: NonEmptyValidator(errorText: "$label required"),
      ),
    );
  }
}

class _DescriptionWidget extends StatelessWidget {
  static const label = 'Description';

  _DescriptionWidget({
    Key key,
    @required this.model,
  }) : super(key: key);

  final CaptureModel model;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(10))),
      padding: EdgeInsets.all(10),
      child: TextFormField(
        controller: model.description,
        maxLines: 5,
        keyboardType: TextInputType.multiline,
        decoration: InputDecoration(
            hintText: label,
            icon: Icon(Icons.description)),
      ),
    );
  }
}

class _CategoryWidget extends StatefulWidget {

  final CaptureModel model;

  _CategoryWidget({Key key, this.model}) : super(key: key);

  @override
  __CategoryWidgetState createState() => __CategoryWidgetState();
}

class __CategoryWidgetState extends State<_CategoryWidget> {
  static const categoryLabels = ['News', 'People', 'Travel', 'Fun', 'Nature', 'Sport', 'Awesome', 'Selfie'];
  static const categoryTokens = categoryLabels;
  int _selectedIndex;

  void _onSelected(int index) {
    setState(() {
      _selectedIndex = index;
      widget.model.selectedCategory = index == null ? '' : categoryTokens[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
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

class _PublishButton extends StatelessWidget {
  static const label = 'Publish';

  _PublishButton({
    Key key,
    @required this.model,
    @required this.onPublish
  }) : super(key: key);

  final PublishCallBack onPublish;
  final CaptureModel model;

  @override
  Widget build(BuildContext context) {

    return SizedBox(width: double.infinity,
        height: 40,
        child:
        RaisedButton(
          child: Text(
              label, style: Theme.of(context).textTheme.button),
          onPressed: () => onPublish(model),
          color: Theme.of(context).buttonColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                  Radius.circular(20))),
        )
    );
  }
}