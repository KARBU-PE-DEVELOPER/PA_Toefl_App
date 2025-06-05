import 'dart:convert';

import 'package:dio/dio.dart';
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
import 'package:toefl/utils/list_ext.dart';
import 'package:toefl/widgets/blue_container.dart';
import 'package:toefl/widgets/quiz/modal/modal_confirmation.dart';

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
  String selectedType = "test";
  int? unfinishedPacketId;
  Set<int> ongoingPacketIds = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ambil argumen dari Navigator
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic> && args['type'] != null) {
      selectedType = args['type'];
    }
  }

  void _onInit() async {
    setState(() => isLoading = true);

    try {
      // Step 1: Ambil semua packet dari backend
      final allPackets = await _fullTestApi.getAllPacket();

      // Step 2: Reset ongoing & completed sets
      ongoingPacketIds.clear();
      final Set<int> completedPacketIds = {};

      // Step 3: Cek status tiap packet dari backend
      for (final packet in allPackets) {
        try {
          final response = await DioToefl.instance.get(
            '${Env.simulationUrl}/check-exam/${packet.id}',
            options: Options(
                validateStatus: (status) => status != null && status < 500),
          );

          final packetId = packet.id is int
              ? packet.id as int
              : int.tryParse(packet.id.toString());
          if (packetId == null) continue;

          if (response.statusCode == 200) {
            final data = response.data is String
                ? jsonDecode(response.data)
                : response.data;
            if (data['success'] == true && data['payload'] is Map) {
              final payload = data['payload'] as Map<String, dynamic>;
              final isCompleted = payload['completed'] ?? false;
              if (isCompleted) {
                completedPacketIds.add(packetId);
              } else {
                ongoingPacketIds.add(packetId);
              }
            } else {
              completedPacketIds.add(packetId);
            }
          } else {
            completedPacketIds.add(packetId);
          }
        } catch (e) {
          final packetId = packet.id is int
              ? packet.id as int
              : int.tryParse(packet.id.toString());
          if (packetId != null) completedPacketIds.add(packetId);
        }
      }

      // Step 4: Jika ada ongoing packet, pastikan ambil ulang data langsung dari backend
      final filteredPackets = allPackets
          .where((packet) => packet.packetType == selectedType)
          .toList();

      setState(() {
        packets = filteredPackets;
        isLoading = false;
      });

      // Step 5: Handle auto submit jika durasi sudah lebih dari 2 jam
      await _handleOnAutoSubmit();

      // Step 6: Simpan status terakhir
      testStatus = await _testSharedPref.getStatus();
    } catch (e, stack) {
      debugPrint("❌ Error in _onInit: $e\n$stack");
      setState(() => isLoading = false);
    }
  }

  void _showAlertDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleOnAutoSubmit() async {
    try {
      testStatus = await _testSharedPref.getStatus();
      if (testStatus != null) {
        final runningPacket =
            packets.firstWhereOrNull((element) => element.id == testStatus!.id);
        if (runningPacket == null) return;

        DateTime startTime = DateTime.parse(testStatus!.startTime);
        int diffInSecs = DateTime.now().difference(startTime).inSeconds;
        if (diffInSecs >= 7200) {
          bool submitResult = false;

          // Langsung pakai submitAnswer tanpa cek wasFilled
          submitResult =
              await ref.read(fullTestProvider.notifier).submitAnswer();

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
      "packetName": packet.name,
      "packetType": selectedType,
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
      appBar: CommonAppBar(
        title: selectedType == 'simulation' ? 'Simulation' : 'Test',
      ),
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
                              isDisabled: ongoingPacketIds.isNotEmpty &&
                                  !ongoingPacketIds.contains(packet.id),
                              hasOngoingTest: ongoingPacketIds.isNotEmpty,
                              // isDisabled: !(packet.questionCount == 140),
                              onTap: () async {
                                if (ongoingPacketIds.contains(packet.id)) {
                                  Navigator.of(context).pushNamed(
                                    RouteKey.openingLoadingTest,
                                    arguments: {
                                      "id": packet.id.toString(),
                                      "packetName": packet.name,
                                      "isRetake": true,
                                      "packetType": selectedType,
                                    },
                                  ).then((value) {
                                    // _onInit();
                                    // _pushReviewPage(packet);
                                  });
                                  return;
                                }
                                if (!packet.wasFilled) {
                                  // Tampilkan dialog konfirmasi sebelum klaim paket
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext claimContext) {
                                      return AlertDialog(
                                        title: Text("Confirmation"),
                                        content: Text(
                                            "Are you sure to do the test on this package?"),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(claimContext)
                                                  .pop(); // Tutup dialog
                                            },
                                            child: Text("No"),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              Navigator.of(claimContext)
                                                  .pop(); // Tutup dialog konfirmasi
                                              debugPrint(
                                                  "Claiming paket for packet id: ${packet.id}");
                                              try {
                                                final response = await DioToefl
                                                    .instance
                                                    .post(
                                                  '${Env.simulationUrl}/submit-paket/${packet.id}',
                                                  options: Options(
                                                    validateStatus: (status) =>
                                                        status != null &&
                                                        status < 500,
                                                  ),
                                                );

                                                if (response.statusCode ==
                                                    200) {
                                                  debugPrint(
                                                      "Paket claimed successfully.");
                                                  await TestSharedPreference()
                                                      .saveStatus(
                                                    TestStatus(
                                                      id: packet.id
                                                          .toString(), // Pastikan menggunakan packet.id yang benar
                                                      startTime: DateTime.now()
                                                          .toIso8601String(),
                                                      name: packet.name,
                                                      resetTable: true,
                                                      isRetake:
                                                          packet.wasFilled,
                                                    ),
                                                  );
                                                  // Jika tipe test, tampilkan modal attention
                                                  if (selectedType !=
                                                      "simulation") {
                                                    showDialog(
                                                      context: context,
                                                      barrierDismissible:
                                                          false, // Tidak bisa ditutup dengan klik di luar
                                                      builder: (BuildContext
                                                          attentionContext) {
                                                        return WillPopScope(
                                                          onWillPop: () async =>
                                                              false, // Mencegah tombol back
                                                          child: AlertDialog(
                                                            title: Text(
                                                                "attention"
                                                                    .tr()),
                                                            content: Text(
                                                                "isiContent"
                                                                    .tr()),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () {
                                                                  Navigator.of(
                                                                          attentionContext)
                                                                      .pop();
                                                                  Navigator.of(
                                                                          context)
                                                                      .pushNamed(
                                                                    RouteKey
                                                                        .openingLoadingTest,
                                                                    arguments: {
                                                                      "id": packet
                                                                          .id
                                                                          .toString(),
                                                                      "packetName":
                                                                          packet
                                                                              .name,
                                                                      "isRetake":
                                                                          packet
                                                                              .wasFilled,
                                                                      "packetType":
                                                                          selectedType,
                                                                    },
                                                                  ).then((value) {
                                                                    // _onInit();
                                                                    // _pushReviewPage(
                                                                    //     packet);
                                                                  });
                                                                },
                                                                child: Text(
                                                                    "Start"),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  } else {
                                                    // Untuk simulation, langsung pindah ke halaman test dengan tombol konfirmasi saja
                                                    Navigator.of(context)
                                                        .pushNamed(
                                                      RouteKey
                                                          .openingLoadingTest,
                                                      arguments: {
                                                        "id": packet.id
                                                            .toString(),
                                                        "packetName":
                                                            packet.name,
                                                        "isRetake":
                                                            packet.wasFilled,
                                                        "packetType":
                                                            selectedType,
                                                      },
                                                    ).then((value) {
                                                      // _onInit();
                                                      // _pushReviewPage(packet);
                                                    });
                                                  }
                                                } else if (response
                                                        .statusCode ==
                                                    400) {
                                                  final responseData =
                                                      response.data;
                                                  if (responseData is Map<
                                                          String, dynamic> &&
                                                      responseData["message"] ==
                                                          "Anda sudah mengklaim packet") {
                                                    debugPrint(
                                                        "Paket sudah diklaim sebelumnya.");
                                                    _showAlertDialog(
                                                        "Pemberitahuan",
                                                        "Anda sudah mengklaim paket ini sebelumnya.");
                                                  } else {
                                                    debugPrint(
                                                        "Paket sudah selesai dikerjakan.");
                                                    _showAlertDialog(
                                                        "Pemberitahuan",
                                                        "Anda sudah menyelesaikan paket ini.");
                                                  }
                                                } else {
                                                  debugPrint(
                                                      "Failed to claim paket: ${response.statusCode}");
                                                }
                                              } catch (e) {
                                                debugPrint(
                                                    "Error claiming paket: $e");
                                                _showAlertDialog("Error",
                                                    "Terjadi kesalahan saat mengklaim paket.");
                                              }
                                            },
                                            child: Text("Yes"),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  return; // Hentikan eksekusi setelah menampilkan dialog
                                }

                                // Jika paket sudah diselesaikan, tampilkan modal konfirmasi untuk review/retake
                                //
                              },
                            ),
                          );
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
    this.hasOngoingTest = false,
  }) : super(key: key);

  final String title;
  final int questionCount;
  final int accuracy;
  final bool hasOngoingTest;
  final Function() onTap;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (!isDisabled) {
          onTap();
        } else if (hasOngoingTest) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Ongoing Test'),
              content: const Text('Please finish your ongoing test first'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
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
