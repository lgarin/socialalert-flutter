import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/picture.dart';
import 'package:social_alert_app/service/configuration.dart';
import 'package:social_alert_app/service/geolocation.dart';
import 'package:social_alert_app/service/upload.dart';
import 'helper.dart';

class _CaptureModel {
  final DateTime timestamp;
  final File media;
  final title = TextEditingController();
  final description = TextEditingController();
  String selectedCategory;
  bool autovalidate = false;

  _CaptureModel(this.media)
      : timestamp = DateTime.now();

  String get titleInput => title.text.trim();

  String get descriptionInput => description.text.isEmpty ? null : description.text;

  bool hasTitleInput() => titleInput != '';
}

class AnnotatePage extends StatefulWidget {

  final UploadTask _upload;

  AnnotatePage(this._upload);

  @override
  _AnnotatePageState createState() => _AnnotatePageState(_upload);
}

enum _PopupAction {
  DELETE,
  INFO
}

class _AnnotatePageState extends State<AnnotatePage> {
  static const backgroundColor = Color.fromARGB(255, 240, 240, 240);
  final _formKey = GlobalKey<FormState>();
  final UploadTask _upload;
  final _CaptureModel _model;
  bool _fullImage = false;

  _AnnotatePageState(this._upload) : _model = _CaptureModel(_upload.file);

  void _switchFullImage() {
    setState(() {
      _fullImage = !_fullImage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureProvider<GeoLocation>(
        create: _readLocation,
        lazy: false,
        child: Scaffold(
          backgroundColor: backgroundColor,
          appBar: _buildAppBar(context),
          body: LocalPicturePreview(
              backgroundColor: backgroundColor,
              image: _upload.file,
              fullScreen: _fullImage,
              fullScreenSwitch: _switchFullImage,
              child: _MetadataForm(model: _model, formKey: _formKey, onPublish: _onPublish),
              childHeight: 475)
        )
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text("Describe your Snype"),
        actions: <Widget>[
          _PublishIconButton(onPublish: _onPublish),
          PopupMenuButton<_PopupAction>(
            itemBuilder: _buildPopupMenuItems,
            onSelected: _onPopupMenuItemSelection,
          ),
        ]
    );
  }

  List<PopupMenuEntry<_PopupAction>> _buildPopupMenuItems(BuildContext context) {
    return [
      PopupMenuItem(value: _PopupAction.DELETE,
        enabled: _upload.canBeDeleted(),
        child: ListTile(title: Text('Delete'), leading: Icon(Icons.delete))),
      PopupMenuItem(value: _PopupAction.INFO,
        child: ListTile(title: Text('Info'), leading: Icon(Icons.info)))
    ];
  }

  void _onPopupMenuItemSelection(_PopupAction selectedItem) {
    if (selectedItem == _PopupAction.DELETE) {
      showConfirmDialog(context, 'Delete Snype', 'Do you really want to delete this upload?', _onConfirmUploadDeletion);
    } else if (selectedItem == _PopupAction.INFO) {
      Navigator.of(context).pushNamed(AppRoute.PictureInfo, arguments: _upload);
    }
  }

  void _onConfirmUploadDeletion() {
    UploadService.current(context).deleteTask(_upload);
    Navigator.pop(context);
  }

  void _onPublish() async {
    final form = _formKey.currentState;
    if (form != null && form.validate()) {
      _upload.annotate(
        title: _model.titleInput,
        category: _model.selectedCategory,
        description: _model.descriptionInput,
      );
      try {
        await UploadService.current(context).manageTask(_upload);
        Navigator.pop(context);
      } catch (e) {
        showSimpleDialog(context, "Upload failed", e.toString());
      }
    } else {
      setState(() {
        _model.autovalidate = true;
        _fullImage = false;
      });
    }
  }

  Future<GeoLocation> _readLocation(BuildContext context) async {
    final location = await GeoLocationService.current(context).tryReadLocation(_upload.position);
    if (location == null) {
      return GeoLocation(longitude: _upload.longitude, latitude: _upload.latitude);
    }
    return location;
  }
}

class _PublishIconButton extends StatelessWidget {
  final VoidCallback onPublish;

  _PublishIconButton({Key key, this.onPublish}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    GeoLocation location = Provider.of(context);
    return IconButton(
        icon: Icon(Icons.cloud_upload),
        onPressed: location != null ? onPublish : null
    );
  }
}

class _MetadataForm extends StatelessWidget {

  _MetadataForm({
    Key key,
    @required this.model,
    @required this.formKey,
    @required this.onPublish,
  }) : super(key: key);

  final _CaptureModel model;
  final GlobalKey<FormState> formKey;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
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
            _PublishButton(onPublish: onPublish)
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

  final _CaptureModel model;

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

  final _CaptureModel model;

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

  final _CaptureModel model;

  _CategoryWidget({Key key, this.model}) : super(key: key);

  @override
  __CategoryWidgetState createState() => __CategoryWidgetState();
}

class __CategoryWidgetState extends State<_CategoryWidget> {
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
    @required this.onPublish
  }) : super(key: key);

  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    GeoLocation location = Provider.of(context);
    return SizedBox(width: double.infinity,
        height: 40,
        child:
        RaisedButton(
          child: Text(
              label, style: Theme.of(context).textTheme.button),
          onPressed: location != null ? onPublish : null,
          color: Theme.of(context).buttonColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                  Radius.circular(20))),
        )
    );
  }
}