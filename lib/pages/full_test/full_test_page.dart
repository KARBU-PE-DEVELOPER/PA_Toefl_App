import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lock_task/flutter_lock_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:slide_countdown/slide_countdown.dart';
import 'package:toefl/pages/full_test/cheating_management/cheating_detection_manager.dart';
import 'package:toefl/pages/full_test/cheating_management/cheating_floating_status.dart';
import 'package:toefl/pages/full_test/cheating_management/enhanced_face_detection_page.dart';
import 'package:toefl/pages/full_test/form_section.dart';
import 'package:toefl/pages/full_test/submit_dialog.dart';
import 'package:toefl/routes/route_key.dart';
import 'package:toefl/state_management/full_test_provider.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/custom_text_style.dart';
import 'package:toefl/utils/hex_color.dart';

import 'bottom_sheet_full_test.dart';

class FullTestPage extends ConsumerStatefulWidget {
  const FullTestPage({
    super.key,
    required this.diffInSec,
    required this.isRetake,
    required this.packetType,
    required this.packetId,
    required this.packetName,
  });

  final int diffInSec;
  final bool isRetake;
  final String packetType;
  final String packetId;
  final String packetName;

  @override
  ConsumerState<FullTestPage> createState() => _FullTestPageState();
}

class _FullTestPageState extends ConsumerState<FullTestPage>
    with WidgetsBindingObserver {
  Timer? _lockTaskChecker;
  bool isTestFinished = false;
  bool _isCheatingDetectionActive = false;
  bool _isSubmitting = false;
  bool _isBypassDialogShowing = false;
  bool _isFinishDialogShowing = false;
  Widget? _hiddenCheatingDetection;
  bool _isLockTaskDialogShowing = false;
  Timer? _lockTaskCountdownTimer;
  int _lockTaskCountdown = 10;
  final ValueNotifier<int> _countdownNotifier = ValueNotifier<int>(10);

  // Flag untuk memastikan cleanup hanya dilakukan sekali
  bool _isCleanedUp = false;

  // Enhanced background detection with multiple strategies
  AppLifecycleState? _lastAppState;
  DateTime? _backgroundStartTime;
  Timer? _backgroundCheckTimer;
  int _backgroundEventCount = 0;
  Timer? _backgroundEventResetTimer;

  // Lower threshold for more sensitive detection
  static const int _backgroundThresholdMs = 100; // Very low threshold
  static const int _maxBackgroundEvents = 3; // Multiple events trigger

  final ValueNotifier<Map<String, dynamic>> _statusNotifier = ValueNotifier({
    'lookAwayCount': 0,
    'faceNotDetectedSeconds': 0,
    'faceNotDetectedCountdown': 300,
    'blinkCountdown': 10,
    'currentStatus': 'Start monitoring...',
    'blinkStatus': 'Normal',
    'isCurrentlyLookingAway': false,
    'currentLookAwayDuration': 0,
  });

  OverlayEntry? _floatingOverlay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastAppState = WidgetsBinding.instance.lifecycleState;

    if (widget.packetType == "test") {
      FlutterLockTask().startLockTask().then((value) {
        debugPrint("startLockTask: $value");
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startCheatingDetection();
      });

      _startLockTaskChecker();
    }
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    debugPrint("🔄 App lifecycle changed from ${_lastAppState} to $state");

    // Skip if test is already finished or dialogs are showing or already cleaned up
    if (isTestFinished ||
        _isFinishDialogShowing ||
        _isBypassDialogShowing ||
        _isCleanedUp ||
        _isSubmitting) {
      _lastAppState = state;
      return;
    }

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Skip background detection if test is finished
        if (isTestFinished || _isSubmitting) return;

        // App is going to background
        _backgroundEventCount++;
        debugPrint(
            "📱 Background event #$_backgroundEventCount at: ${DateTime.now()}");

        if (_backgroundStartTime == null) {
          _backgroundStartTime = DateTime.now();
          debugPrint("📱 App went to background at: $_backgroundStartTime");
        }

        // Reset event counter after some time if no dialog shown
        _backgroundEventResetTimer?.cancel();
        _backgroundEventResetTimer = Timer(const Duration(seconds: 5), () {
          if (!isTestFinished && !_isCleanedUp) {
            _backgroundEventCount = 0;
            debugPrint("🔄 Reset background event counter");
          }
        });

        // Check if too many background events (indicates user trying to leave)
        if (_backgroundEventCount >= _maxBackgroundEvents) {
          debugPrint(
              "🚨 Multiple background events detected - showing dialog immediately");
          Timer(const Duration(milliseconds: 100), () {
            if (mounted &&
                !_isFinishDialogShowing &&
                !_isBypassDialogShowing &&
                !isTestFinished &&
                !_isCleanedUp &&
                !_isSubmitting) {
              _showFinishedDialog(context, ref);
            }
          });
        }

        _startBackgroundTimer();
        break;

      case AppLifecycleState.resumed:
        // Skip if test is finished
        if (isTestFinished || _isSubmitting || _isCleanedUp) return;

        // App returned to foreground
        debugPrint("📱 App resumed to foreground");

        if (_backgroundStartTime != null) {
          final backgroundDuration =
              DateTime.now().difference(_backgroundStartTime!);
          debugPrint(
              "📊 Background duration: ${backgroundDuration.inMilliseconds}ms");
          debugPrint("📊 Background event count: $_backgroundEventCount");

          // Multiple conditions to trigger dialog
          bool shouldShowDialog = false;
          String reason = "";

          // Condition 1: Duration threshold (lowered)
          if (backgroundDuration.inMilliseconds > _backgroundThresholdMs) {
            shouldShowDialog = true;
            reason =
                "background duration (${backgroundDuration.inMilliseconds}ms)";
          }

          // Condition 2: Multiple background events in short time
          if (_backgroundEventCount >= 2) {
            shouldShowDialog = true;
            reason = "multiple background events ($_backgroundEventCount)";
          }

          // Condition 3: Any background event for test mode (very strict)
          if (widget.packetType == "test" && _backgroundEventCount >= 1) {
            shouldShowDialog = true;
            reason = "any background event in test mode";
          }

          if (shouldShowDialog) {
            debugPrint(
                "🚨 Trigger condition met: $reason - showing finish dialog");

            Timer(const Duration(milliseconds: 300), () {
              if (mounted &&
                  !_isFinishDialogShowing &&
                  !_isBypassDialogShowing &&
                  !isTestFinished &&
                  !_isCleanedUp &&
                  !_isSubmitting) {
                _showFinishedDialog(context, ref);
              }
            });
          } else {
            debugPrint("✅ Background conditions within acceptable range");
          }

          // Check lock task status when returning from background
          if (widget.packetType == "test" && !isTestFinished && !_isCleanedUp) {
            final isActive = await FlutterLockTask().isInLockTaskMode();
            if (!isActive) {
              _handleLockTaskBypass();
            }
          }
        }

        // Reset background tracking
        _resetBackgroundTracking();
        break;

      case AppLifecycleState.detached:
        debugPrint("💀 App is being terminated");
        _performCompleteCleanup();
        break;
    }

    _lastAppState = state;
  }

  void _startBackgroundTimer() {
    // Don't start timer if test is finished
    if (isTestFinished || _isSubmitting || _isCleanedUp) return;

    _backgroundCheckTimer?.cancel();
    _backgroundCheckTimer =
        Timer(Duration(milliseconds: _backgroundThresholdMs + 200), () {
      // If still in background after threshold and test not finished
      if (_backgroundStartTime != null &&
          DateTime.now().difference(_backgroundStartTime!).inMilliseconds >
              _backgroundThresholdMs &&
          mounted &&
          !_isFinishDialogShowing &&
          !_isBypassDialogShowing &&
          !isTestFinished &&
          !_isCleanedUp &&
          !_isSubmitting) {
        debugPrint("🚨 Background timer triggered - showing dialog");

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !isTestFinished && !_isCleanedUp) {
            _showFinishedDialog(context, ref);
          }
        });
      }
    });
  }

  void _resetBackgroundTracking() {
    _backgroundStartTime = null;
    _backgroundCheckTimer?.cancel();
    _backgroundCheckTimer = null;
    _backgroundEventResetTimer?.cancel();
    _backgroundEventResetTimer = null;
  }

  void _startLockTaskChecker() {
    _lockTaskChecker?.cancel();
    _lockTaskChecker =
        Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (isTestFinished ||
          !mounted ||
          _isBypassDialogShowing ||
          _isLockTaskDialogShowing ||
          _isCleanedUp ||
          _isSubmitting) {
        return;
      }
      final isActive = await FlutterLockTask().isInLockTaskMode();
      if (!isActive) {
        _handleLockTaskBypass();
      }
    });
  }

  void _handleLockTaskBypass() {
    if (_isBypassDialogShowing ||
        !mounted ||
        isTestFinished ||
        _isLockTaskDialogShowing ||
        _isCleanedUp ||
        _isSubmitting) return;

    _lockTaskChecker?.cancel();

    debugPrint("🚨 BYPASS DETECTED: Starting 10 second countdown.");

    // Set flags to prevent multiple submissions
    setState(() {
      _isBypassDialogShowing = true;
      _isLockTaskDialogShowing = true;
      _lockTaskCountdown = 10;
    });

    // Reset countdown notifier
    _countdownNotifier.value = 10;

    // Start countdown timer
    _lockTaskCountdownTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !isTestFinished && !_isCleanedUp) {
        _lockTaskCountdown--;
        _countdownNotifier.value = _lockTaskCountdown;
        debugPrint("⏰ Countdown: $_lockTaskCountdown seconds remaining");

        if (_lockTaskCountdown <= 0) {
          timer.cancel();
          debugPrint("⏰ Countdown finished - auto submitting");
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop(); // Close dialog
          }
          _performAutoSubmit();
        }
      } else {
        timer.cancel();
      }
    });

    // Show countdown dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.security,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Security Violation Detected',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade600,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Lock Task Mode Bypassed',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You have exited the secure exam environment. Your test will be automatically submitted for security reasons.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ValueListenableBuilder<int>(
                      valueListenable: _countdownNotifier,
                      builder: (context, countdown, child) {
                        return Text(
                          'Auto-submitting in $countdown seconds...',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              debugPrint("👍 User clicked 'Mengerti' - canceling auto submit");
              _lockTaskCountdownTimer?.cancel();
              setState(() {
                _isBypassDialogShowing = false;
                _isLockTaskDialogShowing = false;
              });
              Navigator.of(dialogContext).pop();
              if (!isTestFinished && !_isCleanedUp) {
                _startLockTaskChecker(); // Restart checker only if test not finished
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
            ),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    ).then((_) {
      // Dialog dismissed by other means
      debugPrint("🔄 Dialog closed - cleaning up timer");
      _lockTaskCountdownTimer?.cancel();
      if (mounted) {
        setState(() {
          _isBypassDialogShowing = false;
          _isLockTaskDialogShowing = false;
        });
      }
    });
  }

  void _startCheatingDetection() {
    if (!_isCheatingDetectionActive &&
        mounted &&
        !isTestFinished &&
        !_isCleanedUp) {
      setState(() {
        _isCheatingDetectionActive = true;
        _statusNotifier.value = {
          ..._statusNotifier.value,
          'currentStatus': 'Monitoring Active',
        };
        _hiddenCheatingDetection = HiddenCameraFaceDetection(
          onAutoSubmit: (reason) {
            if (!isTestFinished && !_isCleanedUp && !_isSubmitting) {
              debugPrint("🚨 AUTO SUBMIT TRIGGERED: $reason");
              _handleAutoSubmit(reason);
            }
          },
          onStatusUpdate: (lookAway, faceTime, faceCountdown, blinkCountdown,
              status, blinkStatus) {
            if (mounted && !_isSubmitting && !isTestFinished && !_isCleanedUp) {
              _statusNotifier.value = {
                'lookAwayCount': lookAway,
                'faceNotDetectedSeconds': faceTime,
                'faceNotDetectedCountdown': faceCountdown,
                'blinkCountdown': blinkCountdown,
                'currentStatus': status,
                'blinkStatus': blinkStatus,
                'isCurrentlyLookingAway': false,
                'currentLookAwayDuration': 0,
              };
            }
          },
        );
      });
      _createFloatingOverlay();
    }
  }

  void _createFloatingOverlay() {
    if (isTestFinished || _isCleanedUp || _isSubmitting) return;

    _removeFloatingOverlay();
    _floatingOverlay = OverlayEntry(
      builder: (context) => ValueListenableBuilder<Map<String, dynamic>>(
        valueListenable: _statusNotifier,
        builder: (context, statusData, child) {
          if (_isSubmitting || isTestFinished || _isCleanedUp) {
            return const SizedBox.shrink();
          }
          return FloatingCheatingStatus(
            lookAwayCount: statusData['lookAwayCount'] ?? 0,
            maxLookAway: CheatingDetectionManager.MAX_LOOK_AWAY_COUNT,
            faceNotDetectedSeconds: statusData['faceNotDetectedSeconds'] ?? 0,
            faceNotDetectedCountdown:
                statusData['faceNotDetectedCountdown'] ?? 300,
            blinkCountdown: statusData['blinkCountdown'] ?? 10,
            currentStatus: statusData['currentStatus'] ?? 'Normal',
            blinkStatus: statusData['blinkStatus'] ?? 'Normal',
            isCurrentlyLookingAway:
                statusData['isCurrentlyLookingAway'] ?? false,
            currentLookAwayDuration: statusData['currentLookAwayDuration'] ?? 0,
            onUpdate: () {},
          );
        },
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _floatingOverlay != null &&
          !_isSubmitting &&
          !isTestFinished &&
          !_isCleanedUp) {
        Overlay.of(context).insert(_floatingOverlay!);
      }
    });
  }

  void _removeFloatingOverlay() {
    if (_floatingOverlay != null) {
      _floatingOverlay!.remove();
      _floatingOverlay = null;
    }
  }

  void _stopCheatingDetection() {
    debugPrint("🛑 Stopping cheating detection...");
    if (mounted) {
      setState(() {
        _isSubmitting = true;
        _isCheatingDetectionActive = false;
        _hiddenCheatingDetection = null;
      });
    }
    _removeFloatingOverlay();
    debugPrint("✅ Cheating detection stopped and overlay removed");
  }

  void _performCompleteCleanup() {
    if (_isCleanedUp) return;

    debugPrint("🧹 Performing complete cleanup...");
    _isCleanedUp = true;

    // Stop cheating detection
    _stopCheatingDetection();

    // Cancel all timers
    _lockTaskChecker?.cancel();
    _lockTaskCountdownTimer?.cancel();
    _resetBackgroundTracking();

    // Remove overlay
    _removeFloatingOverlay();

    // Set test as finished
    isTestFinished = true;

    debugPrint("✅ Complete cleanup finished");
  }

  void _handleAutoSubmit(String reason) {
    debugPrint("🔥 HANDLE AUTO SUBMIT CALLED: $reason");

    if (isTestFinished || _isCleanedUp || _isSubmitting) {
      debugPrint("⚠️ Test already finished/cleaned up, ignoring auto submit");
      return;
    }

    debugPrint("✅ Processing auto submit...");

    // Immediately mark as finished to prevent multiple calls
    isTestFinished = true;
    _isSubmitting = true;

    _performCompleteCleanup();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        debugPrint("📋 Showing auto submit dialog...");
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 32),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Auto Submit Exam',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.security, color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Cheating Detected',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reason,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your test will be automatically submitted to maintain test integration.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _performAutoSubmit();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                ),
                child: const Text('Submit Exam'),
              ),
            ],
          ),
        );
      }
    });
  }

  Future<void> _performAutoSubmit() async {
    debugPrint("🚀 Performing auto submit...");
    try {
      // Ensure cleanup is done
      _performCompleteCleanup();

      bool submitResult =
          await ref.read(fullTestProvider.notifier).submitAnswer();
      debugPrint("📤 Submit result: $submitResult");

      if (widget.packetType == "test") {
        await FlutterLockTask().stopLockTask();
        debugPrint("stopLockTask in auto-submit successful");
      }

      if (submitResult) {
        bool resetResult = await ref.read(fullTestProvider.notifier).resetAll();
        if (resetResult && context.mounted) {
          Navigator.pushReplacementNamed(
            context,
            RouteKey.testresult,
            arguments: {
              'packetId': ref.read(fullTestProvider).packetDetail.id.toString(),
              'isMiniTest': false,
              'packetName': ref.read(fullTestProvider).packetDetail.name,
              'packetType': widget.packetType,
            },
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error during auto submit: $e');
    }
  }

  @override
  void dispose() {
    debugPrint("🗑️ Disposing FullTestPage...");

    // Perform complete cleanup
    _performCompleteCleanup();

    // Remove observer
    WidgetsBinding.instance.removeObserver(this);

    // Dispose notifiers
    _statusNotifier.dispose();
    _countdownNotifier.dispose();

    // Stop lock task if not already finished
    if (!isTestFinished && widget.packetType == "test") {
      FlutterLockTask().stopLockTask().then((value) {
        debugPrint("stopLockTask on dispose: $value");
      });
    }

    super.dispose();
    debugPrint("✅ FullTestPage disposed");
  }

  Future<bool> _handleWillPop() async {
    if (_isFinishDialogShowing ||
        _isBypassDialogShowing ||
        _isSubmitting ||
        isTestFinished ||
        _isCleanedUp) {
      return false;
    }

    await _showFinishedDialog(context, ref);
    return false;
  }

  // Menangani penekanan tombol home/back
  void _handleSystemNavigation() {
    debugPrint("🏠 System navigation detected (Home/Back button pressed)");
    if (!_isFinishDialogShowing &&
        !_isBypassDialogShowing &&
        !_isSubmitting &&
        !isTestFinished &&
        !_isCleanedUp) {
      _showFinishedDialog(context, ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final state = ref.watch(fullTestProvider);

    // Stop cheating detection when submit loading starts
    if (state.isSubmitLoading && !_isSubmitting && !_isCleanedUp) {
      debugPrint("🔄 Submit loading detected, stopping cheating detection");
      _performCompleteCleanup();
    }

    Duration countdownDuration;
    if (state.testStatus.startTime.isNotEmpty) {
      final startTime = DateTime.parse(state.testStatus.startTime);
      final elapsed = DateTime.now().difference(startTime);
      final totalTestTime = const Duration(hours: 2);
      countdownDuration = totalTestTime - elapsed;

      // Pastikan tidak negatif
      if (countdownDuration.isNegative) {
        countdownDuration = const Duration(seconds: 0);
      }
    } else {
      countdownDuration = const Duration(hours: 2);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (!didPop) {
          debugPrint("🔙 PopScope triggered - showing finish dialog");
          _handleSystemNavigation();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // Only show cheating detection if test is active
            if (_hiddenCheatingDetection != null &&
                !_isSubmitting &&
                !isTestFinished &&
                !_isCleanedUp)
              Positioned.fill(
                child: _hiddenCheatingDetection!,
              ),
            Positioned(
                top: 50,
                child: SizedBox(
                  width: screenWidth,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        SizedBox(
                          width: screenWidth,
                          child: Center(
                            child: Consumer(
                              builder: (context, ref, child) {
                                final state = ref.watch(fullTestProvider);
                                return Text(
                                  state.packetDetail.name,
                                  style: CustomTextStyle.extraBold16
                                      .copyWith(fontSize: 20),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Spacer(),
                            GestureDetector(
                              onTap: () async {
                                if (!isTestFinished &&
                                    !_isCleanedUp &&
                                    !_isSubmitting) {
                                  debugPrint("📋 Submit button tapped");
                                  _showFinishedDialog(context, ref);
                                }
                              },
                              child: Text(
                                "Submit",
                                style: CustomTextStyle.extraBold16
                                    .copyWith(color: HexColor(mariner700)),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Consumer(
                              builder: (context, ref, child) {
                                final state = ref.watch(fullTestProvider);
                                final totalQuestions = state.totalQuestions;
                                final answeredQuestions = state
                                    .questionsFilledStatus
                                    .where((element) => element == true)
                                    .length;

                                return Text(
                                  "$answeredQuestions/$totalQuestions",
                                  style: CustomTextStyle.bold16.copyWith(
                                    color: HexColor(mariner700),
                                    fontSize: 14,
                                  ),
                                );
                              },
                            ),
                            const Spacer(),
                            Consumer(
                              builder: (context, ref, child) {
                                final state = ref.watch(fullTestProvider);
                                final totalQuestions = state.totalQuestions;
                                final answeredQuestions = state
                                    .questionsFilledStatus
                                    .where((element) => element == true)
                                    .length;

                                return SizedBox(
                                  width: screenWidth * 0.5,
                                  child: LinearProgressIndicator(
                                    value: totalQuestions > 0
                                        ? answeredQuestions / totalQuestions
                                        : 0,
                                    backgroundColor: HexColor(neutral40),
                                    color: HexColor(mariner700),
                                    minHeight: 7,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                );
                              },
                            ),
                            const Spacer(),
                            Icon(
                              Icons.timer,
                              color: HexColor(colorSuccess),
                              size: 18,
                            ),
                            SlideCountdown(
                              duration: countdownDuration,
                              style: CustomTextStyle.bold16.copyWith(
                                color: HexColor(colorSuccess),
                                fontSize: 14,
                              ),
                              separator: ":",
                              separatorStyle: CustomTextStyle.bold16.copyWith(
                                color: HexColor(colorSuccess),
                                fontSize: 14,
                              ),
                              padding: const EdgeInsets.only(left: 8),
                              separatorPadding:
                                  const EdgeInsets.symmetric(horizontal: 1),
                              decoration: const BoxDecoration(
                                color: Colors.transparent,
                              ),
                              onDone: () async {
                                if (!isTestFinished && !_isCleanedUp) {
                                  debugPrint(
                                      "⏰ Timer finished - auto submitting");
                                  _performCompleteCleanup();

                                  bool submitResult = await ref
                                      .read(fullTestProvider.notifier)
                                      .submitAnswer();
                                  if (submitResult) {
                                    await ref
                                        .read(fullTestProvider.notifier)
                                        .resetAll();

                                    if (context.mounted) {
                                      Navigator.pushReplacementNamed(
                                        context,
                                        RouteKey.testresult,
                                        arguments: {
                                          'packetId': widget.packetId,
                                          'isMiniTest': false,
                                          'packetName': widget.packetName,
                                          'packetType': widget.packetType,
                                        },
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Consumer(
                          builder: (context, ref, child) {
                            final state = ref.watch(fullTestProvider);
                            if (state.isSubmitLoading) {
                              return Column(children: [
                                Lottie.network(
                                    "https://lottie.host/61d1d16f-3171-4938-8112-e22de35c9943/5CS2iho5Gd.json",
                                    width: 400,
                                    height: 400),
                                Transform.translate(
                                    offset: const Offset(0, -50),
                                    child: Text("Sending data..",
                                        style: CustomTextStyle.bold16
                                            .copyWith(fontSize: 26))),
                              ]);
                            } else if (state.isLoading) {
                              return const Skeletonizer(
                                child: FormSection(
                                  questions: [],
                                ),
                              );
                            } else if (state.selectedQuestions.isNotEmpty) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: FormSection(
                                  questions: state.selectedQuestions,
                                ),
                              );
                            } else {
                              return const SizedBox();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                )),
            Positioned(
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 4,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                width: screenWidth,
                height: MediaQuery.of(context).size.height * 0.075,
                child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        if ((state.selectedQuestions.firstOrNull?.number ?? 1) >
                            1)
                          IconButton(
                            onPressed: () {
                              if (!isTestFinished && !_isCleanedUp) {
                                final currentNumber = state.selectedQuestions
                                        .firstOrNull?.number ??
                                    1;
                                if (currentNumber > 1) {
                                  ref
                                      .read(fullTestProvider.notifier)
                                      .getQuestionByNumber(currentNumber - 1);
                                }
                              }
                            },
                            icon: const Icon(
                              Icons.chevron_left,
                              size: 30,
                            ),
                          )
                        else
                          const SizedBox(width: 48),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            if (!isTestFinished && !_isCleanedUp) {
                              ref
                                  .read(fullTestProvider.notifier)
                                  .getQuestionsFilledStatus()
                                  .then((value) {
                                if (value != null) {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return BottomSheetFullTest(
                                        filledStatus: value,
                                        onTap: (number) {},
                                      );
                                    },
                                  ).then((selectedNumber) {
                                    if (selectedNumber != null &&
                                        !isTestFinished &&
                                        !_isCleanedUp) {
                                      ref
                                          .read(fullTestProvider.notifier)
                                          .getQuestionByNumber(selectedNumber);
                                    }
                                  });
                                }
                              });
                            }
                          },
                          icon: const Icon(
                            Icons.list,
                            size: 30,
                          ),
                        ),
                        const Spacer(),
                        if ((state.selectedQuestions.lastOrNull?.number ?? 1) <
                            state.totalQuestions)
                          IconButton(
                            onPressed: () {
                              if (!isTestFinished && !_isCleanedUp) {
                                final currentNumber = state
                                        .selectedQuestions.lastOrNull?.number ??
                                    1;
                                if (currentNumber < state.totalQuestions) {
                                  ref
                                      .read(fullTestProvider.notifier)
                                      .getQuestionByNumber(currentNumber + 1);
                                }
                              }
                            },
                            icon: const Icon(
                              Icons.chevron_right,
                              size: 30,
                            ),
                          )
                        else
                          const SizedBox(width: 48),
                      ],
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<dynamic> _showFinishedDialog(BuildContext context, WidgetRef ref) {
    if (_isFinishDialogShowing ||
        _isBypassDialogShowing ||
        _isSubmitting ||
        isTestFinished ||
        _isCleanedUp) {
      debugPrint("⚠️ Dialog already showing or conditions not met");
      return Future.value();
    }

    debugPrint("📋 Showing finish dialog");
    setState(() {
      _isFinishDialogShowing = true;
    });

    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext submitContext) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          content: SubmitDialog(
              onNo: () {
                debugPrint("📋 Dialog dismissed - No");
                setState(() {
                  _isFinishDialogShowing = false;
                });
                Navigator.pop(submitContext);
              },
              onYes: () async {
                debugPrint("📋 Dialog confirmed - Yes");
                setState(() {
                  _isFinishDialogShowing = false;
                });
                Navigator.pop(submitContext);

                // Perform complete cleanup before submitting
                _performCompleteCleanup();

                bool submitResult = false;
                submitResult =
                    await ref.read(fullTestProvider.notifier).submitAnswer();
                if (widget.packetType == "test") {
                  FlutterLockTask().stopLockTask().then((value) {
                    debugPrint("stopLockTask: $value");
                  });
                }
                if (submitResult) {
                  bool resetResult =
                      await ref.read(fullTestProvider.notifier).resetAll();
                  if (resetResult && context.mounted) {
                    Navigator.pushReplacementNamed(
                      context,
                      RouteKey.testresult,
                      arguments: {
                        'packetId': widget.packetId,
                        'isMiniTest': false,
                        'packetName': widget.packetName,
                        'packetType': widget.packetType,
                      },
                    );
                  }
                }
              },
              unAnsweredQuestion: ref
                  .watch(fullTestProvider)
                  .questionsFilledStatus
                  .where((element) => element == false)
                  .length),
        );
      },
    );
  }
}
