import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:toefl/main.dart';

class FaceDetectionPage extends StatefulWidget {
  const FaceDetectionPage({Key? key}) : super(key: key);

  @override
  _FaceDetectionPageState createState() => _FaceDetectionPageState();
}

class _FaceDetectionPageState extends State<FaceDetectionPage> {
  late CameraController _cameraController;
  late CameraDescription _cameraDescription;
  late FaceDetector _faceDetector;
  bool _isDetecting = false;

  Timer? _frameTimer;
  Timer? _notLookingTimer;
  Timer? _blinkingTimer;
  int _blinkCount = 0;
  int _notLookingSeconds = 0;
  int _timeLeft = 300;
  bool _showCountdown = false;

  bool _isFaceInFrame = true;
  bool _isLookingForward = true;
  bool _isBlinking = false;
  int _shortLookAwayCount = 0;

  String _statusText = "Normal";
  String _blinkStatus = "Normal";
  int _blinkTimeLeft = 5; // Countdown for blinking time in seconds

  Timer? _blinkMonitorTimer;
  bool _blinkDetectedInCurrentWindow = false;
  int _blinkCountdown = 10;

  bool _hasShownCheatingDialog = false;

  bool _showBlinkCountdown =
      true; // Untuk mengatur apakah countdown tampil di UI

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableTracking: true,
      ),
    );
    _initializeCamera();

    _startBlinkMonitoringTimer();
  }

  void _startBlinkMonitoringTimer() {
    _blinkMonitorTimer?.cancel();
    _blinkCountdown = 10;
    _blinkDetectedInCurrentWindow = false;

    setState(() {
      _showBlinkCountdown = true; // Tampilkan countdown di UI
    });

    _blinkMonitorTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_blinkCountdown > 0) {
        setState(() {
          _blinkCountdown--;
        });
      } else {
        timer.cancel();
        if (!_blinkDetectedInCurrentWindow) {
          _showCheatingDialog(
            "Tidak ada kedipan dalam 10 detik. Liveness gagal.",
          );
        } else {
          setState(() {
            _showBlinkCountdown = false;
          });
          Future.delayed(const Duration(seconds: 1), () {
            _startBlinkMonitoringTimer();
          });
        }
      }
    });
  }

  Future<void> _initializeCamera() async {
    _cameraDescription = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _cameraController = CameraController(
      _cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cameraController.initialize();
    _cameraController.startImageStream(_processCameraImage);
    setState(() {});
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
          setState(() {
            _statusText = "Wajah Tidak Terdeteksi";
          });
        }
      } else {
        if (!_isFaceInFrame) {
          _cancelFrameTimer();
          _isFaceInFrame = true;
        }

        final headY = faces.first.headEulerAngleY ?? 0.0;

        if (headY.abs() > 40) {
          if (_isLookingForward) {
            _handleStartLookingAway();
            _isLookingForward = false;
          }
          setState(() {
            _statusText = "Menoleh";
          });
        } else {
          if (!_isLookingForward) {
            _handleBackLookingForward();
            _isLookingForward = true;
          }
          setState(() {
            _statusText = "Normal";
          });
        }

        // Check if the eyes are blinking (for liveness detection)
        final leftEye = faces.first.leftEyeOpenProbability;
        final rightEye = faces.first.rightEyeOpenProbability;

        if (leftEye != null && rightEye != null) {
          if (leftEye < 0.5 && rightEye < 0.5) {
            if (!_isBlinking) {
              _isBlinking = true;

              if (!_blinkDetectedInCurrentWindow) {
                _blinkDetectedInCurrentWindow = true;

                setState(() {
                  _showBlinkCountdown = false; // Sembunyikan countdown dari UI
                });

                _blinkMonitorTimer?.cancel(); // Stop timer saat ini

                // Restart timer dengan delay 1 detik
                Future.delayed(const Duration(seconds: 1), () {
                  _startBlinkMonitoringTimer();
                });
              }

              _blinkCount++;
              setState(() {
                _blinkStatus = "Kedip Terdeteksi";
              });
            }
          } else {
            if (_isBlinking) {
              _isBlinking = false;
            }
            setState(() {
              _blinkStatus = "Normal";
            });
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
    _timeLeft = 300;
    _showCountdown = true;

    _frameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        timer.cancel();
        _showCheatingDialog('Wajah tidak terdeteksi selama 5 menit.');
      }
    });
  }

  void _cancelFrameTimer() {
    _frameTimer?.cancel();
    setState(() {
      _showCountdown = false;
    });
  }

  void _cancelBlinkTimer() {
    _blinkingTimer?.cancel();
    setState(() {
      _blinkTimeLeft = 5;
    });
  }

  void _handleStartLookingAway() {
    _shortLookAwayCount++;
    if (_shortLookAwayCount >= 5) {
      _showCheatingDialog('Terdeteksi menoleh lebih dari 5 kali.');
    }

    _notLookingSeconds = 0;
    _notLookingTimer?.cancel();
    _notLookingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _notLookingSeconds++;
      });
    });
  }

  void _handleBackLookingForward() {
    _notLookingTimer?.cancel();
    setState(() {
      _notLookingSeconds = 0;
    });
  }

  void _showCheatingDialog(String reason) {
    if (_hasShownCheatingDialog) return; // Mencegah dialog ganda

    _hasShownCheatingDialog = true; // Tandai sudah ditampilkan
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🚨 Curang Terdeteksi!'),
        content: Text(reason),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetState();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _resetState() {
    _isFaceInFrame = true;
    _isLookingForward = true;
    _cancelFrameTimer();
    _cancelBlinkTimer();
    _hasShownCheatingDialog = false;
    setState(() {
      _statusText = "Normal";
      _blinkStatus = "Normal";
      _shortLookAwayCount = 0;
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _faceDetector.close();
    _frameTimer?.cancel();
    _notLookingTimer?.cancel();
    _blinkingTimer?.cancel();
    _blinkMonitorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraController.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      // appBar: AppBar(title: const Text('Deteksi Kecurangan')),
      body: Stack(
        children: [
          CameraPreview(_cameraController),
          Positioned(
            top: 30,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Status: $_statusText',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            top: 70,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Kedip: $_blinkStatus\nKedipan: $_blinkCount kali',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (_shortLookAwayCount > 0 || _notLookingSeconds > 0)
            Positioned(
              top: 150,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_shortLookAwayCount > 0)
                      Text(
                        'Menoleh: $_shortLookAwayCount kali',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (_notLookingSeconds > 0)
                      Text(
                        'Waktu menoleh: ${_formatTime(_notLookingSeconds)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (_showCountdown)
            Positioned(
              top: 200,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Waktu tanpa wajah: ${_formatTime(_timeLeft)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (_showBlinkCountdown)
            Positioned(
              top: 250,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Harus kedip dalam: $_blinkCountdown detik',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
