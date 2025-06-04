class CheatingDetectionManager {
  static const int MAX_LOOK_AWAY_COUNT = 5;
  static const int MAX_FACE_NOT_DETECTED_SECONDS = 300; // 5 minutes

  int _lookAwayCount = 0;
  int _faceNotDetectedSeconds = 0;
  int _faceNotDetectedCountdown = 300;
  int _blinkCountdown = 15; // UBAH JADI 15 DETIK
  String _currentStatus = "Normal";
  String _blinkStatus = "Normal";

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

  void recordLookAway() {
    _lookAwayCount++;
    _currentStatus = "Turning head detected";
    _updateStatus();

    if (_lookAwayCount >= MAX_LOOK_AWAY_COUNT) {
      onAutoSubmit?.call('Turning around too much (${_lookAwayCount}x)');
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
      // WARNING LEBIH AWAL
      _blinkStatus = "Silakan kedip!";
      // HANYA TRIGGER WARNING SEKALI SAAT COUNTDOWN MENCAPAI 5
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
    _currentStatus = "Normal";
    _updateStatus();
  }

  void blinkDetected() {
    _blinkStatus = "Kedipan terdeteksi ✓";
    _updateStatus();
  }

  void _updateStatus() {
    // THROTTLE UPDATES UNTUK PREVENT SPAM
    final now = DateTime.now();
    if (now.difference(_lastUpdateTime) < _updateThrottle) {
      return; // Skip update jika terlalu cepat
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

  void reset() {
    _lookAwayCount = 0;
    _faceNotDetectedSeconds = 0;
    _faceNotDetectedCountdown = 300;
    _blinkCountdown = 15; // RESET KE 15 DETIK
    _currentStatus = "Normal";
    _blinkStatus = "Normal";
    _updateStatus();
  }
}
