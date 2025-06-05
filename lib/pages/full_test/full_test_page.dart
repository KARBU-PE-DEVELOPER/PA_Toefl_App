import 'dart:async';

import 'package:flutter/material.dart';
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
    required this.packetId, // TAMBAH PARAMETER INI
    required this.packetName, // TAMBAH PARAMETER INI
  });

  final int diffInSec;
  final bool isRetake;
  final String packetType;
  final String packetId; // TAMBAH FIELD INI
  final String packetName; // TAMBAH FIELD INI

  @override
  ConsumerState<FullTestPage> createState() => _FullTestPageState();
}

class _FullTestPageState extends ConsumerState<FullTestPage> {
  Timer? _lockTaskChecker;
  bool isAskedToReLock = false;
  bool isTestFinished = false;
  bool _isCheatingDetectionActive = false;
  bool _isSubmitting = false; // TAMBAH FLAG UNTUK SUBMIT
  Widget? _hiddenCheatingDetection;

  // Status untuk floating widget - GUNAKAN NOTIFIER
  final ValueNotifier<Map<String, dynamic>> _statusNotifier = ValueNotifier({
    'lookAwayCount': 0,
    'faceNotDetectedSeconds': 0,
    'faceNotDetectedCountdown': 300,
    'blinkCountdown': 10,
    'currentStatus': 'Start monitoring...',
    'blinkStatus': 'Normal',
  });

  OverlayEntry? _floatingOverlay;

  @override
  void initState() {
    super.initState();
    if (widget.packetType == "test") {
      FlutterLockTask().startLockTask().then((value) {
        debugPrint("startLockTask: $value");
      });

      // LANGSUNG START CHEATING DETECTION
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startCheatingDetection();
      });

      _lockTaskChecker =
          Timer.periodic(const Duration(seconds: 2), (timer) async {
        final isActive = await FlutterLockTask().isInLockTaskMode();
        if (!isActive && mounted) {
          checkLockStatusPeriodically();
        }
      });
    }
  }

  void _startCheatingDetection() {
    if (!_isCheatingDetectionActive && mounted) {
      setState(() {
        _isCheatingDetectionActive = true;

        // UPDATE STATUS AWAL
        _statusNotifier.value = {
          ..._statusNotifier.value,
          'currentStatus': 'Monitoring Active',
        };

        // Buat hidden camera detection
        _hiddenCheatingDetection = HiddenCameraFaceDetection(
          onAutoSubmit: (reason) {
            debugPrint("🚨 AUTO SUBMIT TRIGGERED: $reason");
            _handleAutoSubmit(reason);
          },
          onStatusUpdate: (lookAway, faceTime, faceCountdown, blinkCountdown,
              status, blinkStatus) {
            if (mounted && !_isSubmitting) {
              // JANGAN UPDATE JIKA SEDANG SUBMIT
              // UPDATE DATA LANGSUNG TANPA RECREATE OVERLAY
              _statusNotifier.value = {
                'lookAwayCount': lookAway,
                'faceNotDetectedSeconds': faceTime,
                'faceNotDetectedCountdown': faceCountdown,
                'blinkCountdown': blinkCountdown,
                'currentStatus': status,
                'blinkStatus': blinkStatus,
              };

              debugPrint(
                  "📊 Status Update - LookAway: $lookAway, Face: $faceTime, Countdown: $faceCountdown, Status: $status");
            }
          },
        );
      });

      // BUAT FLOATING OVERLAY SEKALI SAJA
      _createFloatingOverlay();
    }
  }

  void _createFloatingOverlay() {
    _removeFloatingOverlay(); // Remove existing overlay if any

    _floatingOverlay = OverlayEntry(
      builder: (context) => ValueListenableBuilder<Map<String, dynamic>>(
        valueListenable: _statusNotifier,
        builder: (context, statusData, child) {
          // SEMBUNYIKAN OVERLAY JIKA SEDANG SUBMIT/LOADING
          if (_isSubmitting) {
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
            onUpdate: () {
              // Callback ketika widget di-update - TIDAK PERLU LAGI
            },
          );
        },
      ),
    );

    // Insert overlay dengan delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _floatingOverlay != null && !_isSubmitting) {
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

    setState(() {
      _isSubmitting = true; // SET FLAG SUBMIT
      _isCheatingDetectionActive = false;
      _hiddenCheatingDetection = null;
    });

    // HILANGKAN OVERLAY
    _removeFloatingOverlay();

    debugPrint("✅ Cheating detection stopped and overlay removed");
  }

  void _handleAutoSubmit(String reason) {
    debugPrint("🔥 HANDLE AUTO SUBMIT CALLED: $reason");

    if (isTestFinished) {
      debugPrint("⚠️ Test already finished, ignoring auto submit");
      return;
    }

    debugPrint("✅ Processing auto submit...");
    isTestFinished = true;

    // Stop cheating detection dan remove overlay
    _stopCheatingDetection();

    // ENSURE DIALOG SHOWS
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
      bool submitResult =
          await ref.read(fullTestProvider.notifier).submitAnswer();
      debugPrint("📤 Submit result: $submitResult");

      if (widget.packetType == "test") {
        await FlutterLockTask().stopLockTask();
      }

      if (submitResult) {
        _lockTaskChecker?.cancel();
        bool resetResult = await ref.read(fullTestProvider.notifier).resetAll();
        if (resetResult && context.mounted) {
          // NAVIGASI KE TEST RESULT DENGAN PACKET TYPE
          Navigator.pushReplacementNamed(
            context,
            RouteKey.testresult,
            arguments: {
              'packetId': ref.read(fullTestProvider).packetDetail.id.toString(),
              'isMiniTest': false,
              'packetName': ref.read(fullTestProvider).packetDetail.name,
              'packetType': widget.packetType, // KIRIM PACKET TYPE
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
    _removeFloatingOverlay();
    _statusNotifier.dispose(); // DISPOSE NOTIFIER
    _lockTaskChecker?.cancel();
    if (widget.packetType == "test") {
      FlutterLockTask().stopLockTask().then((value) {
        debugPrint("stopLockTask: $value");
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final state = ref.watch(fullTestProvider);

    // DETECT LOADING STATE DAN HIDE OVERLAY
    if (state.isSubmitLoading && !_isSubmitting) {
      debugPrint("🔄 Submit loading detected, stopping cheating detection");
      _stopCheatingDetection();
    }

    final countdownDuration = widget.diffInSec >= 7200
        ? const Duration(seconds: 2)
        : const Duration(hours: 2) - Duration(seconds: widget.diffInSec);

    return PopScope(
      canPop: false,
      onPopInvoked: (val) async {
        _showFinishedDialog(context, ref);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            if (_hiddenCheatingDetection != null && !_isSubmitting)
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
                                _showFinishedDialog(context, ref);
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
                                // STOP CHEATING DETECTION SAAT TIMER HABIS
                                _stopCheatingDetection();

                                bool submitResult = await ref
                                    .read(fullTestProvider.notifier)
                                    .submitAnswer();
                                if (submitResult) {
                                  await ref
                                      .read(fullTestProvider.notifier)
                                      .resetAll();

                                  if (context.mounted) {
                                    // LANGSUNG REPLACE KE TEST RESULT TANPA POP
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
                              final currentNumber =
                                  state.selectedQuestions.firstOrNull?.number ??
                                      1;
                              if (currentNumber > 1) {
                                ref
                                    .read(fullTestProvider.notifier)
                                    .getQuestionByNumber(currentNumber - 1);
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
                                  if (selectedNumber != null) {
                                    ref
                                        .read(fullTestProvider.notifier)
                                        .getQuestionByNumber(selectedNumber);
                                  }
                                });
                              }
                            });
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
                              final currentNumber =
                                  state.selectedQuestions.lastOrNull?.number ??
                                      1;
                              if (currentNumber < state.totalQuestions) {
                                ref
                                    .read(fullTestProvider.notifier)
                                    .getQuestionByNumber(currentNumber + 1);
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

  checkLockStatusPeriodically() async {
    if (isTestFinished) return;
    final isActive = await FlutterLockTask().isInLockTaskMode();

    if (!isActive && !isAskedToReLock) {
      isAskedToReLock = true;

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Locked Mode Disabled'),
            content: const Text('Please click "Re-Lock" to continue the exam.'),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await FlutterLockTask().startLockTask();
                  isAskedToReLock = false;
                },
                child: const Text('Rekey'),
              )
            ],
          ),
        );
      }
    }
  }

  Future<dynamic> _showFinishedDialog(BuildContext context, WidgetRef ref) {
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
                Navigator.pop(submitContext);
              },
              onYes: () async {
                Navigator.pop(submitContext);

                // STOP CHEATING DETECTION SEBELUM SUBMIT
                _stopCheatingDetection();

                bool submitResult = false;

                submitResult =
                    await ref.read(fullTestProvider.notifier).submitAnswer();

                if (widget.packetType == "test") {
                  FlutterLockTask().stopLockTask().then((value) {
                    debugPrint("stopLockTask: $value");
                  });
                }

                if (submitResult) {
                  isTestFinished = true;
                  _lockTaskChecker?.cancel();
                  bool resetResult =
                      await ref.read(fullTestProvider.notifier).resetAll();
                  if (resetResult && context.mounted) {
                    // LANGSUNG REPLACE KE TEST RESULT TANPA POP
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
