import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/picture.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/configuration.dart';
import 'package:social_alert_app/service/mediaquery.dart';
import 'package:social_alert_app/service/mediaupload.dart';

class _CaptureModel {
  final DateTime timestamp;
  final tags = Set<String>();
  final title = TextEditingController();
  final currentTag = TextEditingController();
  String selectedCategory;
  bool autovalidate = false;

  _CaptureModel()
      : timestamp = DateTime.now();

  String get titleInput => title.text.trim();

  bool hasTitleInput() => titleInput != '';
}

class AnnotatePicturePage extends StatefulWidget {

  final MediaUploadTask _upload;

  AnnotatePicturePage(this._upload);

  @override
  _AnnotatePicturePageState createState() => _AnnotatePicturePageState(_upload);
}

enum _PopupAction {
  DELETE,
  INFO
}

class _AnnotatePicturePageState extends State<AnnotatePicturePage> {
  static const backgroundColor = Color.fromARGB(255, 240, 240, 240);
  final _formKey = GlobalKey<FormState>();
  final MediaUploadTask _upload;
  final _model = _CaptureModel();
  bool _fullImage = false;

  _AnnotatePicturePageState(this._upload);

  void _switchFullImage() {
    setState(() {
      _fullImage = !_fullImage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          backgroundColor: backgroundColor,
          appBar: _buildAppBar(context),
          body: LocalPicturePreview(
              backgroundColor: backgroundColor,
              image: _upload.file,
              fullScreen: _fullImage,
              fullScreenSwitch: _switchFullImage,
              child: _MetadataForm(model: _model, formKey: _formKey, onPublish: _onPublish),
              childHeight: 440)
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

  void _onPopupMenuItemSelection(_PopupAction selectedItem) async {
    if (selectedItem == _PopupAction.DELETE) {
      final confirmed = await showConfirmDialog(context, 'Delete Snype', 'Do you really want to delete this upload?');
      if (confirmed) {
        _onConfirmUploadDeletion();
      }
    } else if (selectedItem == _PopupAction.INFO) {
      Navigator.of(context).pushNamed(AppRoute.LocalPictureInfo, arguments: _upload);
    }
  }

  void _onConfirmUploadDeletion() {
    MediaUploadService.current(context).deleteTask(_upload);
    Navigator.pop(context);
  }

  void _onPublish() async {
    final form = _formKey.currentState;
    if (form != null && form.validate()) {
      _upload.annotate(
        title: _model.titleInput,
        category: _model.selectedCategory,
        tags: List.from(_model.tags),
      );
      try {
        final userProfile = Provider.of<UserProfile>(context, listen: false);
        await MediaUploadService.current(context).saveTask(_upload);
        if (!userProfile.anonym) {
          MediaUploadService.current(context).restartTask(_upload);
        }
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
}

class _PublishIconButton extends StatelessWidget {
  final VoidCallback onPublish;

  _PublishIconButton({Key key, this.onPublish}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProfile = Provider.of<UserProfile>(context, listen: false);
    return IconButton(
        icon: Icon(userProfile.anonym ? Icons.save_alt : Icons.cloud_upload),
        tooltip: userProfile.anonym ? 'Save' : 'Publish',
        onPressed: onPublish
    );
  }
}

class _MetadataForm extends StatelessWidget {

  _MetadataForm({
    Key key,
    @required this.model,
    @required this.formKey,
    @required this.onPublish
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
            _TagsWidget(model: model),
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
        validator: MultiValidator([NonEmptyValidator(errorText: "$label required"), MaxLengthValidator(40, errorText: "Maximum 40 characters allowed")]),
      ),
    );
  }
}

class _TagsWidget extends StatelessWidget {
  static const label = 'Tags';
  static const maxTags = 4;

  _TagsWidget({@required this.model});

  final _CaptureModel model;

  @override
  Widget build(BuildContext context) {
    return FormField<Set<String>>(
      initialValue: model.tags,
      builder: _buildTags,
    );
  }

  Widget _buildTags(FormFieldState<Set<String>> state) {
    final tags = state.value;
    final children = List<Widget>();
    for (String tag in tags) {
      children.add(_buildTag(state, tag));
    }
    if (tags.length < maxTags) {
      children.add(_buildInput(state));
    }
    return Container(
        width: double.infinity,
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(10))),
        padding: EdgeInsets.all(10),
        child:Wrap(children: children, spacing: 5, runSpacing: 5,)
    );
  }

  Widget _buildInput(FormFieldState<Set<String>> state) {
    return TypeAheadFormField(
          autovalidate: true,
          direction: AxisDirection.up,
          suggestionsBoxDecoration: SuggestionsBoxDecoration(borderRadius: BorderRadius.all(Radius.circular(5))),
          textFieldConfiguration: TextFieldConfiguration(
            controller: model.currentTag,
            autofocus: model.hasTitleInput(),
            textInputAction: TextInputAction.next,
            onSubmitted: (value) => _onNewTag(state, value),
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
                icon: Icon(Icons.more),
                hintText: label)
          ),
          validator: MaxLengthValidator(30, errorText: "Maximum 30 characters allowed"),
          itemBuilder: (context, suggestion) => ListTile(title: Text(suggestion)),
          errorBuilder: (context, error) => null,
          noItemsFoundBuilder: (context) => null,
          loadingBuilder: (context) => null,
          suggestionsCallback: (pattern) => _fetchSuggestions(state.context, pattern),
          hideOnError: true,
          hideOnEmpty: true,
          hideOnLoading: true,
          onSuggestionSelected: (suggestion) => _onNewTag(state, suggestion),
          debounceDuration: Duration(milliseconds: 500),
    );
  }

  Future<List<String>> _fetchSuggestions(BuildContext context, String pattern) {
    return MediaQueryService.current(context).suggestTags(pattern, 5);
  }

  void _onNewTag(FormFieldState<Set<String>> state, String newTag) {
    if (newTag.isNotEmpty) {
      model.tags.add(newTag);
      model.currentTag.text = '';
      state.didChange(model.tags);
    }
  }

  Widget _buildTag(FormFieldState<Set<String>> state, String tag) {
    return InputChip(
      key: ValueKey(tag),
      label: Text(tag),
      onDeleted: () => _onDeleteTag(state, tag),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _onDeleteTag(FormFieldState<Set<String>> state, String tag) {
    model.tags.remove(tag);
    state.didChange(model.tags);
  }
}

class _CategoryWidget extends StatefulWidget {

  final _CaptureModel model;

  _CategoryWidget({Key key, this.model}) : super(key: key);

  @override
  _CategoryWidgetState createState() => _CategoryWidgetState();
}

class _CategoryWidgetState extends State<_CategoryWidget> {
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

class _PublishButton extends StatelessWidget {
  _PublishButton({
    Key key,
    @required this.onPublish
  }) : super(key: key);

  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    final userProfile = Provider.of<UserProfile>(context, listen: false);
    return SizedBox(width: double.infinity,
        height: 40,
        child:
        RaisedButton(
          child: Text(userProfile.anonym ? 'Save' : 'Publish',
              style: Theme.of(context).textTheme.button),
          onPressed: onPublish,
          color: Theme.of(context).buttonColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                  Radius.circular(20))),
        )
    );
  }
}