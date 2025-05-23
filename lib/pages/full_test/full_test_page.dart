import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lock_task/flutter_lock_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:slide_countdown/slide_countdown.dart';
import 'package:toefl/pages/full_test/cheating_detection.dart';
import 'package:toefl/pages/full_test/form_section.dart';
import 'package:toefl/pages/full_test/submit_dialog.dart';
import 'package:toefl/routes/route_key.dart';
import 'package:toefl/state_management/full_test_provider.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/custom_text_style.dart';
import 'package:toefl/utils/hex_color.dart';

import 'bookmark_button.dart';
import 'bottom_sheet_full_test.dart';

class FullTestPage extends ConsumerStatefulWidget {
  const FullTestPage({
    super.key,
    required this.diffInSec,
    required this.isRetake,
    required this.packetType,
  });

  final int diffInSec;
  final bool isRetake;
  final String packetType;

  @override
  ConsumerState<FullTestPage> createState() => _FullTestPageState();
}

Timer? _lockTaskChecker;
bool isAskedToReLock = false;
bool isTestFinished = false;
late final bool isSubmittingFinal; // true saat submit akhir

class _FullTestPageState extends ConsumerState<FullTestPage> {
  // @override
  // void initState() {
  //   super.initState();
  //   if (widget.packetType == "test") {
  //     FlutterLockTask().startLockTask().then((value) {
  //       debugPrint("startLockTask: $value");
  //     });
  //   }
  // }

  @override
  void initState() {
    super.initState();
    if (widget.packetType == "test") {
      FlutterLockTask().startLockTask().then((value) {
        debugPrint("startLockTask: $value");
      });

      // // Jalankan deteksi kecurangan otomatis saat mulai
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   showDialog(
      //     context: context,
      //     barrierDismissible: false,
      //     builder: (_) => AlertDialog(
      //       content: const FaceDetectionPage(),
      //       actions: [
      //         TextButton(
      //           onPressed: () {
      //             Navigator.pop(context);
      //           },
      //           child: const Text('Tutup'),
      //         ),
      //       ],
      //     ),
      //   );
      // });

      // Loop check setiap 2 detik
      _lockTaskChecker =
          Timer.periodic(const Duration(seconds: 2), (timer) async {
        final isActive = await FlutterLockTask().isInLockTaskMode();
        if (!isActive && mounted) {
          // Lock task keluar secara paksa
          checkLockStatusPeriodically();
        }
      });
    }
  }

  // @override
  // void dispose() {
  //   if (widget.packetType == "test") {
  //     FlutterLockTask().stopLockTask().then((value) {
  //       debugPrint("stopLockTask: $value");
  //     });
  //   }
  //   super.dispose();
  // }

  @override
  void dispose() {
    _lockTaskChecker?.cancel(); // stop checker
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
                        const SizedBox(
                          height: 10,
                        ),
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
                        const SizedBox(
                          height: 20,
                        ),
                        Row(
                          children: [
                            Consumer(
                              builder: (context, ref, child) {
                                final state = ref.watch(fullTestProvider);
                                final totalQuestions = state
                                    .totalQuestions; // Ambil jumlah total soal
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
                                final totalQuestions = state
                                    .totalQuestions; // Ambil jumlah total soal
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
                                ref
                                    .read(fullTestProvider.notifier)
                                    .submitAnswer()
                                    .then((value) {
                                  if (value) {
                                    ref
                                        .read(fullTestProvider.notifier)
                                        .resetAll()
                                        .then((value) {
                                      Navigator.popUntil(
                                          context,
                                          (route) =>
                                              RouteKey.openingLoadingTest ==
                                              route.settings.name);
                                    });
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
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
                    child:
                        // Row(
                        //   children: [
                        //     IconButton(
                        //         onPressed: () {
                        //           if ((state.selectedQuestions.firstOrNull?.number ??
                        //                   1) <=
                        //               1) {
                        //             return;
                        //           } else {
                        //             ref
                        //                 .read(fullTestProvider.notifier)
                        //                 .getQuestionByNumber((state.selectedQuestions
                        //                             .firstOrNull?.number ??
                        //                         1) -
                        //                     1);
                        //           }
                        //         },
                        //         icon: const Icon(
                        //           Icons.chevron_left,
                        //           size: 30,
                        //         )),
                        //     const Spacer(),
                        //     IconButton(
                        //       onPressed: () {
                        //         showDialog(
                        //           context: context,
                        //           builder: (context) {
                        //             return AlertDialog(
                        //               title: const Center(
                        //                 child: Text(
                        //                   'Face Detection',
                        //                   style: TextStyle(
                        //                       fontWeight: FontWeight.bold,
                        //                       fontSize: 18),
                        //                 ),
                        //               ),
                        //               content: const FaceDetectionPage(),
                        //               actions: [
                        //                 TextButton(
                        //                   onPressed: () {
                        //                     Navigator.pop(context);
                        //                   },
                        //                   child: const Text('Tutup'),
                        //                 ),
                        //               ],
                        //             );
                        //           },
                        //         );
                        //       },
                        //       icon: const Icon(
                        //         Icons.security, // Icon bisa disesuaikan
                        //         size: 28,
                        //       ),
                        //     ),
                        //     const Spacer(),
                        //     IconButton(
                        //         onPressed: () {
                        //           ref
                        //               .read(fullTestProvider.notifier)
                        //               .getQuestionsFilledStatus()
                        //               .then((value) {
                        //             ref
                        //                 .read(fullTestProvider.notifier)
                        //                 .getQuestionsFilledStatus()
                        //                 .then((value) {
                        //               if (value != null) {
                        //                 showModalBottomSheet(
                        //                     context: context,
                        //                     builder: (context) {
                        //                       return BottomSheetFullTest(
                        //                         filledStatus: value,
                        //                         onTap: (number) {},
                        //                       );
                        //                     }).then((selectedNumber) {
                        //                   if (selectedNumber != null) {
                        //                     ref
                        //                         .read(fullTestProvider.notifier)
                        //                         .getQuestionByNumber(selectedNumber);
                        //                   }
                        //                 });
                        //               }
                        //             });
                        //           });
                        //         },
                        //         icon: const Icon(
                        //           Icons.list,
                        //           size: 30,
                        //         )),
                        //     const Spacer(),
                        //     IconButton(
                        //       onPressed: () {
                        //         final lastQuestionNumber =
                        //             state.selectedQuestions.lastOrNull?.number ?? 1;
                        //         final totalQuestions = state.totalQuestions;

                        //         if (lastQuestionNumber >= totalQuestions) {
                        //           return; // sudah soal terakhir, tidak lanjut
                        //         } else {
                        //           ref
                        //               .read(fullTestProvider.notifier)
                        //               .getQuestionByNumber(lastQuestionNumber + 1);
                        //         }
                        //       },
                        //       icon: const Icon(
                        //         Icons.chevron_right,
                        //         size: 30,
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        Row(
                      children: [
                        // Previous Button: tampil kalau soal sekarang > 1
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
                          const SizedBox(
                              width:
                                  48), // buat ruang supaya layout gak berubah

                        const Spacer(),

                        // Tombol lain tetap di tengah seperti security dan list
                        IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Center(
                                    child: Text(
                                      'Face Detection',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18),
                                    ),
                                  ),
                                  content: const FaceDetectionPage(),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Tutup'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          icon: const Icon(
                            Icons.security,
                            size: 28,
                          ),
                        ),

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

                        // Next Button: tampil kalau soal sekarang < totalQuestions
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
                          const SizedBox(
                              width: 48), // ruang supaya gak bergeser
                      ],
                    )
                    ),
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

      // Tampilkan dialog hanya sekali
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Mode Terkunci Dinonaktifkan'),
            content: const Text(
                'Silakan klik "Kunci Ulang" untuk melanjutkan ujian.'),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await FlutterLockTask().startLockTask();
                  isAskedToReLock =
                      false; // Reset agar bisa muncul lagi jika keluar lagi
                },
                child: const Text('Kunci Ulang'),
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
                bool submitResult = false;

                // Directly call submitAnswer
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
                    Navigator.popUntil(
                        context,
                        (route) =>
                            RouteKey.openingLoadingTest == route.settings.name);
                  }
                  if (widget.packetType == "test") {
                    FlutterLockTask().stopLockTask().then((value) {
                      debugPrint("stopLockTask: $value");
                    });
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
