import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:impeller_android_camera/front_camera_livefeed.dart';

void main() {
  runApp(
    MaterialApp(
      home: MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  MainApp({super.key});

  final FaceDetector faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableContours: true,
      enableLandmarks: true,
      enableTracking: true,
      enableClassification: true,
    ),
  );

  Future<void> _processImage(InputImage inputImage) async {
    final List<Face> faces = await faceDetector.processImage(inputImage);
    if (faces.isNotEmpty) {
      log('Found ${faces.length} faces');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Detector'),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 30),
          color: Colors.transparent,
          child: SizedBox(
            width: 235,
            height: 235,
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(250),
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  child: CustomPaint(
                    child: FrontCamDetectorViewWidget(
                      onImage: _processImage,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
