import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:toefl/main.dart';
import 'package:toefl/pages/full_test/cheating_management/cheating_detection_manager.dart';

class HiddenCameraFaceDetection extends StatefulWidget {
  final Function(String reason)? onAutoSubmit;
  final Function(int lookAway, int faceTime, int faceCountdown,
      int blinkCountdown, String status, String blinkStatus)? onStatusUpdate;

  const HiddenCameraFaceDetection({
    Key? key,
    this.onAutoSubmit,
    this.onStatusUpdate,
  }) : super(key: key);

  @override
  _HiddenCameraFaceDetectionState createState() =>
      _HiddenCameraFaceDetectionState();
}

class _HiddenCameraFaceDetectionState extends State<HiddenCameraFaceDetection> {
  late CameraController _cameraController;
  late CameraDescription _cameraDescription;
  late FaceDetector _faceDetector;
  late CheatingDetectionManager _cheatingManager;

  bool _isDetecting = false;
  Timer? _frameTimer;
  Timer? _notLookingTimer;
  Timer? _blinkMonitorTimer;

  bool _isFaceInFrame = true;
  bool _isLookingForward = true;
  bool _isBlinking = false;
  bool _blinkDetectedInCurrentWindow = false;

  // SNACKBAR MANAGEMENT
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _currentSnackBar;
  bool _isSnackBarShowing = false;
  Timer? _snackBarTimer;

  // Status untuk floating widget
  int _blinkCountdown = 15; // UBAH JADI 15 DETIK

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableTracking: true,
      ),
    );

    _cheatingManager = CheatingDetectionManager(
      onStatusChanged: (lookAway, faceTime, faceCountdown, blinkCountdown,
          status, blinkStatus) {
        if (mounted) {
          setState(() {
            _blinkCountdown = blinkCountdown;
          });

          widget.onStatusUpdate?.call(lookAway, faceTime, faceCountdown,
              blinkCountdown, status, blinkStatus);
        }
      },
      onAutoSubmit: (reason) {
        widget.onAutoSubmit?.call(reason);
      },
      onBlinkWarning: (message) {
        _showPersistentBlinkWarning(message);
      },
    );

    _initializeCamera();
    _startBlinkMonitoringTimer();
  }

  void _showPersistentBlinkWarning(String message) {
    if (!mounted) return;

    if (_isSnackBarShowing) {
      debugPrint("🟡 Snackbar already showing, skipping duplicate");
      return;
    }

    debugPrint("🔔 Showing persistent blink warning");
    _isSnackBarShowing = true;

    _currentSnackBar?.close();

    _currentSnackBar = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.visibility,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kedipkan mata Anda',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Untuk memverifikasi kehadiran Anda',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.85),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 3,
                height: 35,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFFF6F00), // Deep orange
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        duration: const Duration(days: 1),
      ),
    );

    _currentSnackBar?.closed.then((_) {
      _isSnackBarShowing = false;
      _currentSnackBar = null;
      debugPrint("🔕 Snackbar dismissed");
    });
  }

  void _dismissBlinkWarning() {
    if (!_isSnackBarShowing || _currentSnackBar == null) return;

    debugPrint("✅ Dismissing blink warning");
    _currentSnackBar?.close();
    _isSnackBarShowing = false;
    _currentSnackBar = null;
  }

  void _startBlinkMonitoringTimer() {
    _blinkMonitorTimer?.cancel();
    _blinkDetectedInCurrentWindow = false;

    _blinkMonitorTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_blinkCountdown > 0) {
        _cheatingManager.updateBlinkCountdown(_blinkCountdown - 1);
        _blinkCountdown--;

        // UPDATE COUNTDOWN DI SNACKBAR JIKA SEDANG TAMPIL
        if (_isSnackBarShowing) {
          // Force rebuild snackbar dengan countdown baru
          setState(() {});
        }
      } else {
        timer.cancel();
        if (!_blinkDetectedInCurrentWindow) {
          _showPersistentBlinkWarning(
              "Silakan kedipkan mata untuk membuktikan Anda manusia.");
        }
        Future.delayed(const Duration(seconds: 1), () {
          _blinkCountdown = 15; // RESET KE 15 DETIK
          _startBlinkMonitoringTimer();
        });
      }
    });
  }

  Future<void> _initializeCamera() async {
    try {
      _cameraDescription = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _cameraController = CameraController(
        _cameraDescription,
        ResolutionPreset.low,
        enableAudio: false,
      );
      await _cameraController.initialize();
      _cameraController.startImageStream(_processCameraImage);
      setState(() {});
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Uint8List _convertYUV420toNV21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final ySize = width * height;
    final nv21 = Uint8List(width * height * 3 ~/ 2);

    nv21.setRange(0, ySize, image.planes[0].bytes);

    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel!;

    int offset = ySize;
    for (int row = 0; row < height ~/ 2; row++) {
      for (int col = 0; col < width ~/ 2; col++) {
        final uIndex = row * uvRowStride + col * uvPixelStride;
        final vIndex = row * image.planes[2].bytesPerRow +
            col * image.planes[2].bytesPerPixel!;
        nv21[offset++] = image.planes[2].bytes[vIndex];
        nv21[offset++] = image.planes[1].bytes[uIndex];
      }
    }
    return nv21;
  }

  void _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;
    _isDetecting = true;

    try {
      final bytes = _convertYUV420toNV21(image);
      final imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final rotation = InputImageRotationValue.fromRawValue(
            _cameraDescription.sensorOrientation,
          ) ??
          InputImageRotation.rotation0deg;

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.width,
        ),
      );

      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        if (_isFaceInFrame) {
          _startFrameTimer();
          _isFaceInFrame = false;
        }
      } else {
        if (!_isFaceInFrame) {
          _cancelFrameTimer();
          _isFaceInFrame = true;
          _cheatingManager.resetFaceDetected();
        }

        final headY = faces.first.headEulerAngleY ?? 0.0;

        if (headY.abs() > 40) {
          if (_isLookingForward) {
            _cheatingManager.recordLookAway();
            _isLookingForward = false;
          }
        } else {
          if (!_isLookingForward) {
            _isLookingForward = true;
            _cheatingManager.resetFaceDetected();
          }
        }

        // Blink detection
        final leftEye = faces.first.leftEyeOpenProbability;
        final rightEye = faces.first.rightEyeOpenProbability;

        if (leftEye != null && rightEye != null) {
          if (leftEye < 0.5 && rightEye < 0.5) {
            if (!_isBlinking) {
              _isBlinking = true;
              if (!_blinkDetectedInCurrentWindow) {
                _blinkDetectedInCurrentWindow = true;
                _cheatingManager.blinkDetected();

                // DISMISS SNACKBAR KETIKA BERHASIL KEDIP
                _dismissBlinkWarning();

                _blinkMonitorTimer?.cancel();
                Future.delayed(const Duration(seconds: 1), () {
                  _blinkCountdown = 15; // RESET KE 15 DETIK
                  _startBlinkMonitoringTimer();
                });
              }
            }
          } else {
            _isBlinking = false;
          }
        }
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
    } finally {
      _isDetecting = false;
    }
  }

  void _startFrameTimer() {
    _frameTimer?.cancel();
    _frameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _cheatingManager.updateFaceNotDetected(timer.tick);
    });
  }

  void _cancelFrameTimer() {
    _frameTimer?.cancel();
  }

  @override
  void dispose() {
    debugPrint("🧹 Disposing HiddenCameraFaceDetection...");

    // CLEANUP SNACKBAR
    _dismissBlinkWarning();

    // STOP CAMERA
    if (_cameraController.value.isInitialized) {
      _cameraController.dispose();
    }

    // CLEANUP FACE DETECTOR
    _faceDetector.close();

    // CANCEL TIMERS
    _frameTimer?.cancel();
    _notLookingTimer?.cancel();
    _blinkMonitorTimer?.cancel();
    _snackBarTimer?.cancel();

    debugPrint("✅ HiddenCameraFaceDetection disposed completely");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.shrink();
  }
}
