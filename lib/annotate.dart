import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/local.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/feeling.dart';
import 'package:social_alert_app/service/authentication.dart';
import 'package:social_alert_app/service/configuration.dart';
import 'package:social_alert_app/service/eventbus.dart';
import 'package:social_alert_app/service/mediaquery.dart';
import 'package:social_alert_app/service/mediaupload.dart';

class _CaptureModel {
  final DateTime timestamp;
  final tags = Set<String>();
  String _title;
  final currentTag = TextEditingController();
  String selectedCategory;
  Feeling feeling;
  bool autovalidate = false;

  _CaptureModel()
      : timestamp = DateTime.now();

  bool hasTitleInput() => _title != null && _title.isNotEmpty;

  String get title => _title;
  void setTitle(String newTitle) => _title = newTitle;
}

class AnnotateMediaPage extends StatelessWidget {
  static const defaultTitle = 'New Snype';
  static const backgroundColor = Color.fromARGB(255, 240, 240, 240);
  final MediaUploadTask upload;

  AnnotateMediaPage(this.upload);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: _buildAppBar(context),
        body: _buildBody()
    );
  }

  Widget _buildBody() {
    return MediaPresentationPanel(
          backgroundColor: backgroundColor,
          media: upload.isVideo
            ? LocalVideoDisplay(file: upload.file, title: defaultTitle, preview: true)
            : LocalPictureDisplay(file: upload.file, title: defaultTitle, preview: true),
          info: _MetadataForm(upload)
      );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
        title: Text("Describe your Snype"),
        actions: <Widget>[
          _PublishIconButton(),
          _AppBarPopupMenu(upload),
        ]
    );
  }
}

enum _MediaAction {
  PUBLISH,
  DELETE,
  INFO
}

class _AppBarPopupMenu extends StatelessWidget {

  final MediaUploadTask upload;

  _AppBarPopupMenu(this.upload);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_MediaAction>(
      itemBuilder: _buildPopupMenuItems,
      onSelected: (action) => EventBus.of(context).fire(action),
    );
  }
  List<PopupMenuEntry<_MediaAction>> _buildPopupMenuItems(BuildContext context) {
    return [
      PopupMenuItem(value: _MediaAction.DELETE,
          enabled: upload.canBeDeleted,
          child: ListTile(title: Text('Delete'), leading: Icon(Icons.delete))),
      PopupMenuItem(value: _MediaAction.INFO,
          child: ListTile(title: Text('Info'), leading: Icon(Icons.info)))
    ];
  }
}

class _PublishIconButton extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final userProfile = Provider.of<UserProfile>(context, listen: false);
    return IconButton(
        icon: Icon(userProfile.anonym ? Icons.save_alt : Icons.cloud_upload),
        tooltip: userProfile.anonym ? 'Save' : 'Publish',
        onPressed: () => EventBus.of(context).fire(_MediaAction.PUBLISH)
    );
  }
}

class _MetadataForm extends StatefulWidget {

  final MediaUploadTask upload;

  _MetadataForm(this.upload);

  @override
  _MetadataFormState createState() => _MetadataFormState();
}

class _MetadataFormState extends State<_MetadataForm> {

  final _CaptureModel _model = _CaptureModel();
  final _formKey = GlobalKey<FormState>();

  StreamSubscription<_MediaAction> _actionSubscription;

  @override
  void initState() {
    super.initState();
    _model.setTitle(widget.upload.title);
    _model.tags.addAll(widget.upload.tags);
    _model.selectedCategory = widget.upload.category;
    _actionSubscription = EventBus.of(context).on<_MediaAction>().listen((action) {
      if (action == _MediaAction.PUBLISH) {
        _onPublish();
      } else if (action == _MediaAction.DELETE) {
        _onDelete();
      } else if (action == _MediaAction.INFO) {
        _onInfo();
      }
    });

    widget.upload.file.length().then((value) {
      if (value > MediaUploadTask.maximumFileSize) {
        showWarningSnackBar(context, 'Maximum video size reached');
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
    return Form(
        onWillPop: _allowPop,
        key: _formKey,
        autovalidateMode: _model.autovalidate ? AutovalidateMode.always : AutovalidateMode.onUserInteraction,
        child: Column(
          children: <Widget>[
            _FeelingWidget(_model),
            SizedBox(height: 10),
            _TitleWidget(_model),
            SizedBox(height: 10),
            _CategoryWidget(_model),
            SizedBox(height: 10),
            _TagsWidget(_model),
            SizedBox(height: 10),
            _PublishButton()
          ],
        ));
  }

  Future<bool> _allowPop() async {
    final form = _formKey.currentState;
    if (form != null && !widget.upload.isDeleted) {
      form.save();
      widget.upload.save(
        title: _model.title,
        category: _model.selectedCategory,
        tags: List.from(_model.tags),
      );
      await MediaUploadService.of(context).saveTask(widget.upload);
    }
    return true;
  }

  void _onPublish() async {
    final form = _formKey.currentState;
    if (form != null && form.validate()) {
      form.save();
      widget.upload.annotate(
        title: _model.title,
        category: _model.selectedCategory,
        tags: List.from(_model.tags),
        feeling: _model.feeling?.value,
      );
      try {
        final userProfile = Provider.of<UserProfile>(context, listen: false);
        await MediaUploadService.of(context).saveTask(widget.upload);
        if (!userProfile.anonym) {
          MediaUploadService.of(context).restartTask(widget.upload);
        }
        Navigator.of(context).pop();
      } catch (e) {
        showSimpleDialog(context, "Upload failed", e.toString());
      }
    } else {
      setState(() {
        _model.autovalidate = true;
      });
    }
  }

  void _onDelete() async {
    final confirmed = await showConfirmDialog(context, 'Delete Snype', 'Do you really want to delete this upload?');
    if (confirmed) {
      _onConfirmUploadDeletion();
    }
  }

  void _onInfo() {
    EventBus.of(context).fire(VideoAction.PAUSE);
    Navigator.of(context).pushNamed(AppRoute.LocalMediaInfo, arguments: widget.upload);
  }

  void _onConfirmUploadDeletion() async {
    try {
      await MediaUploadService.of(context).deleteTask(widget.upload);
      Navigator.of(context).maybePop();
    } catch (e) {
      showSimpleDialog(context, 'Cannot delete Snype', e.toString());
    }
  }
}

class _TitleWidget extends StatelessWidget {
  static const label = 'Title';

  _TitleWidget(this.model);

  final _CaptureModel model;

  @override
  Widget build(BuildContext context) {
    return WideRoundedField(
      child: TextFormField(
        autofocus: !model.hasTitleInput(),
        initialValue: model.title,
        onSaved: model.setTitle,
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
            hintText: label,
            icon: Icon(Icons.title)),
        validator: MultiValidator([NonEmptyValidator(errorText: "$label required"), MaxLengthValidator(40, errorText: "Maximum 40 characters allowed")]),
      ),
    );
  }
}

class _FeelingWidget extends StatefulWidget {

  _FeelingWidget(this.model);

  final _CaptureModel model;

  @override
  _FeelingWidgetState createState() => _FeelingWidgetState();
}

class _FeelingWidgetState extends State<_FeelingWidget> {

  void _onSelected(int index) {
    setState(() {
      widget.model.feeling = Feeling.allDescending[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      children: Feeling.allDescending.map(_buildIcon).toList(growable: false),
      isSelected: Feeling.allDescending.map(_isSelected).toList(growable: false),
      selectedColor: Colors.white,
      fillColor: Theme.of(context).primaryColor,
      onPressed: _onSelected,
      borderRadius: BorderRadius.circular(20),
      borderWidth: 2,
      selectedBorderColor: Theme.of(context).primaryColor,
    );
  }

  bool _isSelected(Feeling feeling) => widget.model.feeling == feeling;

  Widget _buildIcon(Feeling feeling) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Icon(feeling.icon, size: _isSelected(feeling) ? 40 : 30),
    );
  }
}

class _TagsWidget extends StatelessWidget {
  static const label = 'Tags';
  static const maxTags = 4;

  _TagsWidget(this.model);

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
    final children = <Widget>[];
    for (String tag in tags) {
      children.add(_buildTag(state, tag));
    }
    if (tags.length < maxTags) {
      children.add(_buildInput(state));
    }
    return WideRoundedField(
        child:Wrap(children: children, spacing: 5, runSpacing: 5,)
    );
  }

  Widget _buildInput(FormFieldState<Set<String>> state) {
    return TypeAheadFormField(
          autovalidateMode: AutovalidateMode.always,
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
    return MediaQueryService.of(context).suggestTags(pattern, 5);
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

  @override
  Widget build(BuildContext context) {
    final userProfile = Provider.of<UserProfile>(context, listen: false);
    return WideRoundedButton(
        text: userProfile.anonym ? 'Save' : 'Publish',
        onPressed: () => EventBus.of(context).fire(_MediaAction.PUBLISH)
    );
  }
}