
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:impeller_android_camera/camera_livefeed.dart';

class FrontCamDetectorViewWidget extends StatefulWidget {
  const FrontCamDetectorViewWidget({
    super.key,
    required this.onImage,
    this.onCameraFeedReady,
  });

  final Function(InputImage inputImage) onImage;
  final Function()? onCameraFeedReady;

  @override
  State<FrontCamDetectorViewWidget> createState() =>
      _FrontCamDetectorViewState();
}

class _FrontCamDetectorViewState
    extends State<FrontCamDetectorViewWidget> {
  ///According to : https://stackoverflow.com/questions/49946153/flutter-camera-appears-stretched
  ///
  ///Do a calculate between camera aspect ratio and divide it with
  ///Screen Size ratio
  ///
  ///This way, you get an accurate scale for the widget.

  @override
  Widget build(BuildContext context) {
      return CameraLiveFeed(
        cameraDirection: CameraLensDirection.front,
        context: context,
        onImage: widget.onImage,
        onCameraFeedReady: widget.onCameraFeedReady,
      );
    }
}
