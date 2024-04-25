// ignore_for_file: no_leading_underscores_for_local_identifiers
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';


class CameraLiveFeed extends StatefulWidget {
  const CameraLiveFeed({
    super.key,
    required this.onImage,
    required this.context,
    required this.cameraDirection,
    this.onCameraFeedReady,
  });

  final Function(InputImage inputImage) onImage;
  final VoidCallback? onCameraFeedReady;
  final BuildContext context;
  final CameraLensDirection cameraDirection;

  static double scale = 0;

  @override
  State<CameraLiveFeed> createState() =>
      _CameraLiveFeedWidgetState();
}

class _CameraLiveFeedWidgetState extends State<CameraLiveFeed> {
  static List<CameraDescription> cameras = [];
  static int cameraIndex = -1;
  static Size cameracontrollerValue = const Size(1, 1);

  CameraController? cameraController;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  ///get camera
  Future<void> initialize() async {
    if (cameras.isEmpty) {
      cameras = await availableCameras();
    }

    for (var c = 0; c < cameras.length; c++) {
      if (cameras[c].lensDirection == widget.cameraDirection) {
        cameraIndex = c;
        break;
      }
    }

    if (cameraIndex != -1) {
      _startLiveFeed();
    }
  }

  ///Start live feed
  Future _startLiveFeed() async {
    cameraController = CameraController(
      cameras[cameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    cameraController!.initialize().then((_) {
      if (!context.mounted) return;
      cameraController!.startImageStream(_processCameraImage).then((value) {
        setState(() {
          cameracontrollerValue = cameraController!.value.previewSize!;
          CameraLiveFeed.scale = cameraController!.value.aspectRatio;
        });
        if (widget.onCameraFeedReady != null) {
          widget.onCameraFeedReady?.call();
        }
      });
    });
  }

  ///Processing Images from the feed
  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _inputImageFromCameraImage(
    CameraImage image,
    List<CameraDescription> camera,
    CameraLensDirection cameraDirection,
  ) {
    //get image rotation
    CameraDescription? _camera;
    for (final camera in cameras) {
      if (camera.lensDirection == cameraDirection) {
        _camera = camera;
        break;
      }
    }
    final sensorOrientation = _camera!.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[cameraController!.value.deviceOrientation];
      if (rotationCompensation == null) return null;

      //front only
      rotationCompensation = (sensorOrientation + rotationCompensation) % 360;

      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    if (rotation == null) return null;
    //get image format
    final format = InputImageFormatValue.fromRawValue(image.format.raw as int);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    //nv21 and bgra8888 return only one plane.
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    //compose Inputimage using bytes
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  void _processCameraImage(CameraImage image) {
    final inputimage = _inputImageFromCameraImage(
      image,
      cameras,
      widget.cameraDirection,
    );
    if (inputimage == null) return;
    widget.onImage(inputimage);
  }

  ///Building The Widget
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.aspectRatio;
    if (cameraController == null) {
      return Container();
    }

    var cameraAspectRatio = cameracontrollerValue.aspectRatio * size;
    if (cameraAspectRatio < 1) {
      cameraAspectRatio = 1 / cameraAspectRatio;
    }
    return Transform.scale(
      scale: cameraAspectRatio,
      child: _liveFeedBody(),
    );
  }

  /// Need to separate as its own function because
  /// frontCameraController will return null upon
  /// first initialized.
  /// And using [late] won't work because it doesn't actually
  /// initized until we get a list of CameraDescription
  /// And at that point [CameraController] is definitely did not
  /// getting any assign and will instantly return [Exception]
  Widget _liveFeedBody() {
    final cameraControllerWidth = cameracontrollerValue.height;
    final cameraControllerHeight = cameracontrollerValue.width;
    return SizedBox(
      width: cameraControllerWidth,
      height: cameraControllerHeight,
      child: CameraPreview(cameraController!),
    );
  }

  ///Stop the live feed onDispose
  Future<void> stopLiveFeed() async {
    await cameraController?.stopImageStream();
    await cameraController?.dispose();
    cameraController = null;
  }

  @override
  Future<void> dispose() async {
    try {
      await stopLiveFeed();
    } catch (e) {
      log(e.toString());
    } finally {
      super.dispose();
    }
  }
}
