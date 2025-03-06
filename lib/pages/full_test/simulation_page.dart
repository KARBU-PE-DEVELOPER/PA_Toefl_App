import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:toefl/remote/api/full_test_api.dart';
import 'package:toefl/remote/dio_toefl.dart';
import 'package:toefl/remote/env.dart';
import 'package:toefl/remote/local/shared_pref/test_shared_preferences.dart';
import 'package:toefl/routes/route_key.dart';
import 'package:toefl/state_management/full_test_provider.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/custom_text_style.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:toefl/widgets/blue_container.dart';
import 'package:toefl/widgets/quiz/modal/modal_confirmation.dart';
import 'package:flutter_lock_task/flutter_lock_task.dart';

import '../../models/test/packet.dart';
import '../../models/test/test_status.dart';
import '../../widgets/common_app_bar.dart';

class SimulationPage extends ConsumerStatefulWidget {
  const SimulationPage({super.key});

  @override
  ConsumerState<SimulationPage> createState() => _SimulationPageState();
}

class _SimulationPageState extends ConsumerState<SimulationPage> {
  final FullTestApi _fullTestApi = FullTestApi();
  final TestSharedPreference _testSharedPref = TestSharedPreference();
  bool isLoading = true;
  List<Packet> packets = [];
  TestStatus? testStatus;

  void _onInit() async {
    setState(() {
      isLoading = true;
    });
    try {
      final allPacket = await _fullTestApi.getAllPacket();
      setState(() {
        packets = allPacket;
      });
      _handleOnAutoSubmit();
      testStatus = await _testSharedPref.getStatus();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _handleOnAutoSubmit() async {
    try {
      testStatus = await _testSharedPref.getStatus();
      if (testStatus != null) {
        final runningPacket =
            packets.where((element) => element.id == testStatus!.id).first;
        DateTime startTime = DateTime.parse(testStatus!.startTime);
        int diffInSecs = DateTime.now().difference(startTime).inSeconds;
        if (diffInSecs >= 7200) {
          bool submitResult = false;
          if (runningPacket.wasFilled) {
            submitResult =
                await ref.read(fullTestProvider.notifier).resubmitAnswer();
          } else {
            submitResult =
                await ref.read(fullTestProvider.notifier).submitAnswer();
          }
          if (submitResult) {
            await ref.read(fullTestProvider.notifier).resetAll();
          }
        }
      }
    } catch (e) {
      debugPrint("error ho : $e");
    }
  }

  void _pushReviewPage(Packet packet) {
    Navigator.pushNamed(context, RouteKey.testresult, arguments: {
      "packetId": packet.id.toString(),
      "isMiniTest": false,
      "packetName": packet.name
    }).then((afterRetake) {
      if (afterRetake == true) {
        _onInit();
        _pushReviewPage(packet);
      }
    });
  }

  @override
  void initState() {
    _onInit();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title: 'FULL TEST'),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: SingleChildScrollView(
          child: Skeletonizer(
            enabled: isLoading,
            child: Column(
              children: isLoading
                  ? List.generate(
                      4,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Skeleton.leaf(
                          child: PacketCard(
                            title: "",
                            questionCount: 0,
                            accuracy: 0,
                            onTap: () {},
                            isDisabled: false,
                          ),
                        ),
                      ),
                    )
                  : packets.isNotEmpty
                      ? List.generate(packets.length, (index) {
                          final packet = packets[index];
                          return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: PacketCard(
                                title: packet.name.toUpperCase(),
                                questionCount: packet.questionCount,
                                accuracy: packet.accuracy,
                                // Hapus logika isOnGoing, jadi properti ini tidak digunakan lagi
                                isDisabled: !(packet.questionCount == 88),
                                onTap: () async {
                                  final packet = packets[index];
                                  debugPrint("1");
                                  debugPrint("1 $packet");

                                  if (testStatus != null &&
                                      testStatus!.id == packet.id) {
                                    debugPrint("2");
                                    debugPrint("1 $testStatus");
                                    // Jika test masih berjalan (in progress)
                                    Navigator.of(context).pushNamed(
                                      RouteKey.openingLoadingTest,
                                      arguments: {
                                        "id": packet.id.toString(),
                                        "isRetake": packet.wasFilled,
                                        "packetName": packet.name,
                                      },
                                    ).then((value) {
                                      _onInit();
                                      _pushReviewPage(packet);
                                      FlutterLockTask()
                                          .startLockTask()
                                          .then((value) {
                                        print("startLockTask: " +
                                            value.toString());
                                      });
                                    });
                                  } else if (!packet.wasFilled) {
                                    // Jika test belum pernah diisi (baru)
                                    debugPrint(
                                        "Claiming paket for packet id: ${packet.id}");
                                    try {
                                      // Gunakan packet.id untuk meng-claim paket, bukan variable id yang tidak terdefinisi
                                      final response = await DioToefl.instance.post(
                                          '${Env.simulationUrl}/submit-paket/${packet.id}');

                                      // Pastikan untuk memeriksa apakah claim berhasil
                                      if (response.statusCode == 200) {
                                        debugPrint(
                                            "Paket claimed successfully.");
                                        Navigator.of(context).pushNamed(
                                          RouteKey.openingLoadingTest,
                                          arguments: {
                                            "id": packet.id.toString(),
                                            "packetName": packet.name,
                                            "isRetake": packet.wasFilled
                                          },
                                        ).then((value) {
                                          _onInit();
                                          _pushReviewPage(packet);
                                          FlutterLockTask()
                                              .startLockTask()
                                              .then((value) {
                                            print("startLockTask: " +
                                                value.toString());
                                          });
                                        });
                                      } else {
                                        debugPrint(
                                            "Failed to claim paket: ${response.statusCode}");
                                        // Anda bisa menambahkan dialog atau notifikasi error di sini
                                      }
                                    } catch (e) {
                                      debugPrint("Error claiming paket: $e");
                                      // Tangani error (misalnya, tampilkan dialog error)
                                    }
                                  } else {
                                    debugPrint("4");

                                    // Jika test sudah selesai, tampilkan dialog konfirmasi
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext submitContext) {
                                        return ModalConfirmation(
                                          message:
                                              "you_ve_finished_your_test".tr(),
                                          leftTitle: 'review'.tr(),
                                          rightTitle: 'retake'.tr(),
                                          rightFunction: () async {
                                            await _fullTestApi
                                                .claimPaketUjian(packet.id);
                                            Navigator.of(submitContext).pop();
                                            Navigator.of(context).pushNamed(
                                              RouteKey.openingLoadingTest,
                                              arguments: {
                                                "id": packet.id.toString(),
                                                "packetName": packet.name,
                                                "isRetake": packet.wasFilled
                                              },
                                            ).then((value) {
                                              _onInit();
                                              _pushReviewPage(packet);
                                              FlutterLockTask()
                                                  .startLockTask()
                                                  .then((value) {
                                                print("startLockTask: " +
                                                    value.toString());
                                              });
                                            });
                                          },
                                          leftFunction: () {
                                            Navigator.of(submitContext).pop();
                                            Navigator.pushNamed(
                                              context,
                                              RouteKey.testresult,
                                              arguments: {
                                                "packetId":
                                                    packet.id.toString(),
                                                "isMiniTest": false,
                                                "packetName": packet.name
                                              },
                                            ).then((afterRetake) {
                                              if (afterRetake == true) {
                                                _onInit();
                                                _pushReviewPage(packet);
                                              }
                                            });
                                          },
                                        );
                                      },
                                    );
                                  }
                                },
                              ));
                        })
                      : [],
            ),
          ),
        ),
      ),
    );
  }
}

class PacketCard extends StatelessWidget {
  const PacketCard({
    Key? key,
    required this.title,
    required this.questionCount,
    required this.accuracy,
    required this.onTap,
    this.isDisabled = true,
  }) : super(key: key);

  final String title;
  final int questionCount;
  final int accuracy;
  final Function() onTap;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!isDisabled) {
          onTap();
        }
      },
      child: Stack(
        children: [
          BlueContainer(
            showShadow: false,
            child: Row(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width / 8,
                  height: MediaQuery.of(context).size.height / 16,
                  decoration: BoxDecoration(
                    color: HexColor(mariner600),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: SvgPicture.asset(
                      'assets/icons/ic_buku.svg',
                    ),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.62,
                      child: Text(
                        title,
                        style: CustomTextStyle.bold16,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          "$questionCount Questions",
                          style: CustomTextStyle.normal12,
                        ),
                        const SizedBox(width: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.3,
                            height: MediaQuery.of(context).size.height / 64,
                            child: LinearProgressIndicator(
                              backgroundColor: HexColor(neutral40),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  HexColor(mariner700)),
                              value: accuracy / 100,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "$accuracy%",
                          style: CustomTextStyle.bold16
                              .copyWith(color: HexColor(mariner700)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isDisabled)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: HexColor(neutral40).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
