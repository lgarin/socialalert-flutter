import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/service/cameradevice.dart';
import 'package:social_alert_app/service/configuration.dart';
import 'package:social_alert_app/service/geolocation.dart';
import 'package:social_alert_app/service/mediaupload.dart';

class CaptureMediaPage extends StatefulWidget {

  @override
  _CaptureMediaPageState createState() => _CaptureMediaPageState();
}

class _CaptureMediaPageState extends State<CaptureMediaPage> {

  final cameraNotifier = ValueNotifier<CameraValue>(null);
  CameraController _cameraController;
  CameraLensDirection _lensDirection = CameraLensDirection.back;
  Future<GeoPosition> _asyncPosition;
  Future<DeviceInfo> _asyncDevice;
  bool _videoMode = false;
  Stopwatch _videoLength;
  Timer _videoMonitor;

  @override
  Widget build(BuildContext context) {
    return FutureProvider<CameraController>(
      initialData: null,
      key: ValueKey('$_lensDirection/$_videoMode'),
      create: _createCameraController,
      catchError: showUnexpectedError,
      child: _buildContent(context),
    );
  }

  Scaffold _buildContent(BuildContext context) {
    final portrait = MediaQuery.of(context).orientation == Orientation.portrait;
    return Scaffold(
      appBar: portrait ? AppBar(title: Text('Synpix')) : null,
      body: Center(child: _CameraPreviewArea()),
      backgroundColor: Colors.black,
      bottomNavigationBar: _CaptureNavigationBar(videoMode: _videoMode, cameraNotifier: cameraNotifier, onCameraSwitch: _onCameraSwitch, onVideoResume: _onVideoStart, onVideoPause: _onVideoPause, onModeSwitch: _onModeSwitch,),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _CaptureButton(videoMode: _videoMode, cameraNotifier: cameraNotifier, onPictureCapture: _onPictureCapture, onVideoStart: _onVideoStart, onVideoStop: _onVideoStop),
    );
  }

  @override
  void initState() {
    super.initState();
    _asyncPosition = GeoLocationService.of(context).readPosition(20.0);
    _asyncDevice = CameraDevice.of(context).info;
  }


  @override
  void dispose() {
    _videoMonitor?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  CameraLensDirection _nextLensDirection(CameraLensDirection currentLensDirection) {
    if (currentLensDirection == CameraLensDirection.back) {
      return CameraLensDirection.front;
    } else {
      return CameraLensDirection.back;
    }
  }

  void _onModeSwitch() async {
    cameraNotifier.value = null;
    _cameraController?.dispose();
    _cameraController = null;
    setState(() {
      _videoMode = !_videoMode;
    });
  }

  void _onCameraSwitch() async {
    cameraNotifier.value = null;
    _cameraController?.dispose();
    _cameraController = null;
    setState(() {
      _lensDirection = _nextLensDirection(_lensDirection);
    });
  }

  void _onPictureCapture() async {
    cameraNotifier.value = null;
    try {
      XFile outputFile = await _cameraController.takePicture();
      final device = await _asyncDevice;
      final position = await _asyncPosition;
      final task = MediaUploadTask(file: File(outputFile.path), type: MediaUploadType.PICTURE, position: position, device: device);
      await MediaUploadService.of(context).saveTask(task);
      Navigator.of(context).pushReplacementNamed(AppRoute.AnnotateMedia, arguments: task);
    } catch (e) {
      print(e);
      showSimpleDialog(context, 'Capture failed', e.toString());
    }
  }

  void _onMaximumVideoLength() async {
    _onVideoStop();
    showWarningSnackBar(context, 'Maximum video length reached');
  }

  void _onVideoStart() async {
    cameraNotifier.value = null;
    try {
      if (_videoLength != null) {
        await _cameraController.resumeVideoRecording();
      } else {
        await _cameraController.startVideoRecording();
        _videoLength = Stopwatch();
      }
      cameraNotifier.value = _cameraController?.value;
      _videoLength.start();
      final remainingMillis = maxVideoDuration.inMilliseconds - _videoLength.elapsedMilliseconds;
      _videoMonitor = Timer(Duration(milliseconds: max(1, remainingMillis)), _onMaximumVideoLength);
    } catch (e) {
      print(e);
      showSimpleDialog(context, 'Capture failed', e.toString());
    }
  }

  void _onVideoStop() async {
    _videoLength = null;
    _videoMonitor.cancel();
    cameraNotifier.value = null;
    try {
      XFile file = await _cameraController.stopVideoRecording();
      cameraNotifier.value = _cameraController?.value;
      final device = await _asyncDevice;
      final position = await _asyncPosition;
      final task = MediaUploadTask(file: File(file.path), type: MediaUploadType.VIDEO, position: position, device: device);
      await MediaUploadService.of(context).saveTask(task);
      Navigator.of(context).pushReplacementNamed(AppRoute.AnnotateMedia, arguments: task);
    } catch (e) {
      print(e);
      showSimpleDialog(context, 'Capture failed', e.toString());
    }
  }

  void _onVideoPause() async {
    _videoLength.stop();
    _videoMonitor.cancel();
    cameraNotifier.value = null;
    try {
      await _cameraController.pauseVideoRecording();
      cameraNotifier.value = _cameraController?.value;
    } catch (e) {
      print(e);
      showSimpleDialog(context, 'Capture failed', e.toString());
    }
  }

  Future<CameraController> _createCameraController(BuildContext context) async {
    _cameraController = await CameraDevice.of(context).findCamera(_lensDirection, _videoMode ? ResolutionPreset.high : ResolutionPreset.max);
    cameraNotifier.value = _cameraController?.value;
    return _cameraController;
  }
}

class _CameraPreviewArea extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    CameraController controller = Provider.of(context);
    if (controller == null) {
      return LoadingCircle();
    }

    return CameraPreview(controller);
  }
}

class _CaptureButton extends StatelessWidget {
  final bool videoMode;
  final VoidCallback onPictureCapture;
  final VoidCallback onVideoStart;
  final VoidCallback onVideoStop;
  final ValueNotifier<CameraValue> cameraNotifier;

  _CaptureButton({@required this.videoMode, @required this.cameraNotifier, @required this.onPictureCapture, @required this.onVideoStart, @required this.onVideoStop});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: cameraNotifier,
      builder: _buildContent,
    );
  }

  Widget _buildContent(BuildContext context, CameraValue camera, Widget child) {
    final recording = camera != null && camera.isRecordingVideo;
    return SizedBox(
      width: 80,
      height: 80,
      child:  FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        tooltip: _defineTooltip(recording),
        child: Icon(_defineIcon(recording), size: 50),
        onPressed: camera == null ? null : _defineTrigger(recording),
      )
    );
  }

  String _defineTooltip(bool recording) {
    if (recording) {
      return 'Stop video';
    } else if (videoMode) {
      return 'Start video';
    } else {
      return 'Take picture';
    }
  }

  IconData _defineIcon(bool recording) {
    if (recording) {
      return Icons.stop;
    } else if (videoMode) {
      return Icons.fiber_manual_record;
    } else {
      return Icons.camera;
    }
  }

  VoidCallback _defineTrigger(bool recording) {
    if (recording) {
      return onVideoStop;
    } else if (videoMode) {
      return onVideoStart;
    } else {
      return onPictureCapture;
    }
  }
}

class _CaptureNavigationBar extends StatelessWidget {
  static final buttonColor = Color.fromARGB(255, 231, 40, 102);
  static final spacing = 15.0;
  final bool videoMode;
  final VoidCallback onModeSwitch;
  final VoidCallback onVideoPause;
  final VoidCallback onVideoResume;
  final VoidCallback onCameraSwitch;
  final ValueNotifier<CameraValue> cameraNotifier;

  _CaptureNavigationBar({@required this.videoMode, @required this.cameraNotifier, @required this.onModeSwitch, @required this.onVideoPause, @required this.onVideoResume, @required this.onCameraSwitch});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: cameraNotifier,
      builder: _buildContent,
    );
  }

  Widget _buildContent(BuildContext context, CameraValue camera, Widget child) {
    return BottomAppBar(
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Padding(padding: EdgeInsets.all(spacing), child: _buildSwitchCameraButton(context, camera)),
          Padding(padding: EdgeInsets.all(spacing), child: _buildVideoButton(context, camera)),
        ],
      ),
    );
  }

  Widget _buildSwitchCameraButton(BuildContext context, CameraValue camera) {
    final recording = camera?.isRecordingVideo ?? false;
    return _buildRoundButton(
        icon: Icon(Icons.switch_camera),
        fillColor:  recording ? Colors.grey : Colors.white,
        onPressed: camera == null ? null : (recording ? null : onCameraSwitch),
        tooltip: 'Switch camera'
    );
  }

  Widget _buildVideoButton(BuildContext context, CameraValue camera) {
    if (camera?.isRecordingPaused ?? false) {
      return _buildResumeVideoButton();
    } else if (camera?.isRecordingVideo ?? false) {
      return _buildPauseVideoButton();
    } else if (videoMode) {
      return _buildPictureModeButton(camera != null);
    } else {
      return _buildVideoModeButton(camera != null);
    }
  }

  Widget _buildPictureModeButton(bool enabled) {
    return _buildRoundButton(
      icon: Icon(Icons.camera_alt),
      tooltip: 'Take a picture',
      fillColor: buttonColor,
      onPressed: enabled ? onModeSwitch : null,
    );
  }

  Widget _buildVideoModeButton(bool enabled) {
    return _buildRoundButton(
      icon: Icon(Icons.videocam),
      tooltip: 'Make a video',
      fillColor: buttonColor,
      onPressed: enabled ? onModeSwitch : null,
    );
  }

  Widget _buildPauseVideoButton() {
    return _buildRoundButton(
      icon:Icon(Icons.pause),
      tooltip: 'Pause recording',
      fillColor: buttonColor,
      onPressed: onVideoPause,
    );
  }

  Widget _buildResumeVideoButton() {
    return _buildRoundButton(
      icon:Icon(Icons.fiber_manual_record),
      tooltip: 'Resume recording',
      fillColor: buttonColor,
      onPressed: onVideoResume,
    );
  }

  Widget _buildRoundButton({Icon icon, Color fillColor, VoidCallback onPressed, String tooltip}) {
    return Tooltip(
      message: tooltip,
      child: RawMaterialButton(
        child: icon,
        padding: EdgeInsets.all(spacing),
        shape: CircleBorder(),
        fillColor: fillColor,
        onPressed: onPressed
      )
    );
  }
}
