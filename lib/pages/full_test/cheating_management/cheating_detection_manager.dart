import 'dart:async';

class CheatingDetectionManager {
  static const int MAX_LOOK_AWAY_COUNT = 5;
  static const int MAX_FACE_NOT_DETECTED_SECONDS = 300; // 5 minutes
  static const int LOOK_AWAY_DURATION_THRESHOLD = 5; // 5 detik durasi menoleh

  int _lookAwayCount = 0;
  int _faceNotDetectedSeconds = 0;
  int _faceNotDetectedCountdown = 300;
  int _blinkCountdown = 15;
  String _currentStatus = "Normal";
  String _blinkStatus = "Normal";

  // TAMBAHAN UNTUK DURASI MENOLEH
  DateTime? _lookAwayStartTime;
  bool _isCurrentlyLookingAway = false;
  int _currentLookAwayDuration = 0;

  // THROTTLING UNTUK PREVENT SPAM UPDATES
  DateTime _lastUpdateTime = DateTime.now();
  static const Duration _updateThrottle = Duration(milliseconds: 250);

  final Function(int lookAway, int faceTime, int faceCountdown,
      int blinkCountdown, String status, String blinkStatus)? onStatusChanged;
  final Function(String reason)? onAutoSubmit;
  final Function(String message)? onBlinkWarning;

  CheatingDetectionManager({
    this.onStatusChanged,
    this.onAutoSubmit,
    this.onBlinkWarning,
  });

  void startLookAway() {
    if (!_isCurrentlyLookingAway) {
      _isCurrentlyLookingAway = true;
      _lookAwayStartTime = DateTime.now();
      _currentLookAwayDuration = 0;
      _currentStatus = "Turning head detected";
      _updateStatus();

      // Mulai timer untuk menghitung durasi menoleh
      _startLookAwayTimer();
    }
  }

  void _startLookAwayTimer() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isCurrentlyLookingAway) {
        timer.cancel();
        return;
      }

      _currentLookAwayDuration++;
      _currentStatus = "Turning head detected (${_currentLookAwayDuration}s)";
      _updateStatus();

      // Jika sudah lebih dari 5 detik, kurangi count dan reset
      if (_currentLookAwayDuration >= LOOK_AWAY_DURATION_THRESHOLD) {
        _lookAwayCount++;
        _currentStatus = "Turn head violation recorded";
        _updateStatus();

        timer.cancel();
        _isCurrentlyLookingAway = false;
        _lookAwayStartTime = null;
        _currentLookAwayDuration = 0;

        // Reset status setelah 2 detik
        Future.delayed(const Duration(seconds: 2), () {
          if (_currentStatus == "Turn head violation recorded") {
            _currentStatus = "Normal";
            _updateStatus();
          }
        });

        // Cek apakah sudah mencapai batas maksimum
        if (_lookAwayCount >= MAX_LOOK_AWAY_COUNT) {
          onAutoSubmit?.call('Turning around too much (${_lookAwayCount}x)');
        }
      }
    });
  }

  void stopLookAway() {
    if (_isCurrentlyLookingAway) {
      _isCurrentlyLookingAway = false;
      _lookAwayStartTime = null;
      _currentLookAwayDuration = 0;

      // Jika durasi menoleh kurang dari 5 detik, tidak dihitung sebagai pelanggaran
      _currentStatus = "Face forward detected";
      _updateStatus();

      // Reset status ke normal setelah 1 detik
      Future.delayed(const Duration(seconds: 1), () {
        if (_currentStatus == "Face forward detected") {
          _currentStatus = "Normal";
          _updateStatus();
        }
      });
    }
  }

  void updateFaceNotDetected(int seconds) {
    _faceNotDetectedSeconds = seconds;
    _faceNotDetectedCountdown = MAX_FACE_NOT_DETECTED_SECONDS - seconds;
    _currentStatus = "Face not detected";
    _updateStatus();

    if (_faceNotDetectedSeconds >= MAX_FACE_NOT_DETECTED_SECONDS) {
      onAutoSubmit?.call('Face not detected for 5 minutes');
    }
  }

  void updateBlinkCountdown(int countdown) {
    _blinkCountdown = countdown;
    if (countdown <= 5) {
      _blinkStatus = "Silakan kedip!";
      if (countdown == 5) {
        onBlinkWarning
            ?.call('Mohon kedipkan mata Anda dalam ${countdown} detik.');
      }
    } else {
      _blinkStatus = "Normal";
    }
    _updateStatus();
  }

  void resetFaceDetected() {
    _faceNotDetectedSeconds = 0;
    _faceNotDetectedCountdown = 300;
    if (_currentStatus == "Face not detected") {
      _currentStatus = "Normal";
    }
    _updateStatus();
  }

  void blinkDetected() {
    _blinkStatus = "Kedipan terdeteksi ✓";
    _updateStatus();
  }

  void _updateStatus() {
    final now = DateTime.now();
    if (now.difference(_lastUpdateTime) < _updateThrottle) {
      return;
    }

    _lastUpdateTime = now;

    onStatusChanged?.call(
      _lookAwayCount,
      _faceNotDetectedSeconds,
      _faceNotDetectedCountdown,
      _blinkCountdown,
      _currentStatus,
      _blinkStatus,
    );
  }

  // Getters
  int get lookAwayCount => _lookAwayCount;
  int get faceNotDetectedSeconds => _faceNotDetectedSeconds;
  int get faceNotDetectedCountdown => _faceNotDetectedCountdown;
  int get blinkCountdown => _blinkCountdown;
  String get currentStatus => _currentStatus;
  String get blinkStatus => _blinkStatus;
  int get currentLookAwayDuration => _currentLookAwayDuration;
  bool get isCurrentlyLookingAway => _isCurrentlyLookingAway;

  void reset() {
    _lookAwayCount = 0;
    _faceNotDetectedSeconds = 0;
    _faceNotDetectedCountdown = 300;
    _blinkCountdown = 15;
    _currentStatus = "Normal";
    _blinkStatus = "Normal";
    _isCurrentlyLookingAway = false;
    _lookAwayStartTime = null;
    _currentLookAwayDuration = 0;
    _updateStatus();
  }
}
