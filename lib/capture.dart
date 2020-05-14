
import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:social_alert_app/helper.dart';
import 'package:social_alert_app/main.dart';
import 'package:social_alert_app/service/cameradevice.dart';
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
  String _videoPath;
  Timer _videoTimer;

  @override
  Widget build(BuildContext context) {
    return FutureProvider(
      key: ValueKey(_lensDirection),
      create: _createCameraController,
      child: _buildContent(context),
    );
  }

  Scaffold _buildContent(BuildContext context) {
    final portrait = MediaQuery.of(context).orientation == Orientation.portrait;
    return Scaffold(
      appBar: portrait ? AppBar(title: Text('Synpix')) : null,
      body: _CameraPreviewArea(),
      bottomNavigationBar: _CaptureNavigationBar(cameraNotifier: cameraNotifier, onCameraSwitch: _onCameraSwitch, onVideoStart: _onVideoRecord, onVideoPause: _onVideoPause,),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _CaptureButton(cameraNotifier: cameraNotifier, onPictureCapture: _onPictureCapture, onVideoStop: _onVideoStop),
    );
  }

  @override
  void initState() {
    super.initState();
    _asyncPosition = GeoLocationService.current(context).readPosition(20.0);
    _asyncDevice = CameraDeviceService.current(context).device;
  }


  @override
  void dispose() {
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
      String path = await _defineOutputFile('jpg');
      await _cameraController.takePicture(path);
      final device = await _asyncDevice;
      final position = await _asyncPosition;
      final task = MediaUploadTask(file: File(path), type: MediaUploadType.PICTURE, position: position, device: device);
      await MediaUploadService.current(context).saveTask(task);
      Navigator.of(context).pushReplacementNamed(AppRoute.AnnotateMedia, arguments: task);
    } catch (e) {
      print(e);
      showSimpleDialog(context, 'Capture failed', e.toString());
    }
  }

  Future<String> _defineOutputFile(String extension) async {
    final outputDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return join(outputDir.path, '$timestamp.$extension');
  }

  void _monitorVideoSize(Timer timer) async {
    if (await File(_videoPath).length() > MediaUploadTask.maximumFileSize) {
      timer.cancel();
      _onVideoStop();
      showWarningSnackBar(context, 'Maximum video size reached');
    }
  }

  void _onVideoRecord() async {
    cameraNotifier.value = null;
    _videoTimer = Timer.periodic(Duration(seconds: 1), _monitorVideoSize);
    try {
      if (_videoPath != null) {
        await _cameraController.resumeVideoRecording();
        cameraNotifier.value = _cameraController?.value;
      } else {
        _videoPath = await _defineOutputFile('mp4');
        await _cameraController.startVideoRecording(_videoPath);
        cameraNotifier.value = _cameraController?.value;
      }
    } catch (e) {
      _videoPath = null;
      print(e);
      showSimpleDialog(context, 'Capture failed', e.toString());
    }
  }

  void _onVideoStop() async {
    _videoTimer.cancel();
    cameraNotifier.value = null;
    try {
      await _cameraController.stopVideoRecording();
      cameraNotifier.value = _cameraController?.value;
      final device = await _asyncDevice;
      final position = await _asyncPosition;
      final task = MediaUploadTask(file: File(_videoPath), type: MediaUploadType.VIDEO, position: position, device: device);
      await MediaUploadService.current(context).saveTask(task);
      Navigator.of(context).pushReplacementNamed(AppRoute.AnnotateMedia, arguments: task);
    } catch (e) {
      _videoPath = null;
      print(e);
      showSimpleDialog(context, 'Capture failed', e.toString());
    }
  }

  void _onVideoPause() async {
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
    _cameraController = await CameraDeviceService.current(context).findCamera(_lensDirection, ResolutionPreset.veryHigh);
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

    return NativeDeviceOrientationReader(useSensor: true, builder: _buildCameraPreview);
  }

  Widget _buildCameraPreview(BuildContext context) {
    CameraController controller = Provider.of(context);
    int turns = _determineRotationCount(context);
    return RotatedBox(
      quarterTurns: turns,
      child: CameraPreview(controller),
    );
  }

  int _determineRotationCount(BuildContext context) {
    NativeDeviceOrientation orientation = NativeDeviceOrientationReader.orientation(context);
    switch (orientation) {
      case NativeDeviceOrientation.landscapeLeft: return -1;
      case NativeDeviceOrientation.landscapeRight: return 1;
      case NativeDeviceOrientation.portraitDown: return 2;
      default: return 0;
    }
  }
}

class _CaptureButton extends StatelessWidget {
  final VoidCallback onPictureCapture;
  final VoidCallback onVideoStop;
  final ValueNotifier<CameraValue> cameraNotifier;

  _CaptureButton({@required this.cameraNotifier, @required this.onPictureCapture, @required this.onVideoStop});

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
        tooltip: recording ? 'Stop video' : 'Take picture',
        child: recording
          ? Icon(Icons.stop, size: 50,)
          : Icon(Icons.camera_alt, size: 50,),
        onPressed: camera == null ? null : (recording ? onVideoStop : onPictureCapture),
      )
    );
  }
}

class _CaptureNavigationBar extends StatelessWidget {
  static final spacing = 15.0;
  final VoidCallback onVideoStart;
  final VoidCallback onVideoPause;
  final VoidCallback onCameraSwitch;
  final ValueNotifier<CameraValue> cameraNotifier;

  _CaptureNavigationBar({@required this.cameraNotifier, @required this.onVideoStart, @required this.onVideoPause, @required this.onCameraSwitch});

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
        fillColor: Colors.white,
        onPressed: camera == null ? null : (recording ? null : onCameraSwitch),
        tooltip: 'Switch camera'
    );
  }

  Widget _buildVideoButton(BuildContext context, CameraValue camera) {
    if (camera?.isRecordingPaused ?? false) {
      return _buildResumeVideoButton();
    } else if (camera?.isRecordingVideo ?? false) {
      return _buildPauseVideoButton();
    } else {
      return _buildStartVideoButton(camera != null);
    }
  }

  Widget _buildStartVideoButton(bool enabled) {
    return _buildRoundButton(
      icon: Icon(Icons.videocam),
      tooltip: 'Start recording',
      fillColor: Color.fromARGB(255, 231, 40, 102),
      onPressed: enabled ? onVideoStart : null,
    );
  }

  Widget _buildPauseVideoButton() {
    return _buildRoundButton(
      icon:Icon(Icons.pause),
      tooltip: 'Pause recording',
      fillColor: Color.fromARGB(255, 231, 40, 102),
      onPressed: onVideoPause,
    );
  }

  Widget _buildResumeVideoButton() {
    return _buildRoundButton(
      icon:Icon(Icons.play_arrow),
      tooltip: 'Resume recording',
      fillColor: Color.fromARGB(255, 231, 40, 102),
      onPressed: onVideoStart,
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