import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lock_task/flutter_lock_task.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:toefl/models/test/result.dart';
import 'package:toefl/pages/bookmark/bookmarked_page.dart';
import 'package:toefl/remote/api/full_test_api.dart';
import 'package:toefl/routes/route_key.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/custom_text_style.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:toefl/widgets/blue_container.dart';
import 'package:toefl/widgets/toefl_progress_indicator.dart';

import '../../widgets/common_app_bar.dart';

class TestResultPage extends StatefulWidget {
  const TestResultPage({
    super.key,
    required this.packetId,
    required this.isMiniTest,
    required this.packetName,
    required this.packetType, // TAMBAH PARAMETER INI
  });

  final String packetId;
  final bool isMiniTest;
  final String packetName;
  final String packetType; // TAMBAH FIELD INI

  @override
  State<TestResultPage> createState() => _TestResultPageState();
}

class _TestResultPageState extends State<TestResultPage> {
  FullTestApi api = FullTestApi();
  bool isLoading = false;
  Result? result;

  @override
  void initState() {
    super.initState();
    _init();
    FlutterLockTask().stopLockTask();
  }

  void _init() async {
    setState(() {
      isLoading = true;
    });
    result = await api.getTestResult(widget.packetId);
    setState(() {
      isLoading = false;
    });
  }

  // FUNCTION UNTUK MENDAPATKAN TITLE BERDASARKAN PACKET TYPE
  String _getPageTitle() {
    if (widget.packetType.toLowerCase() == "test") {
      return "Test Result";
    } else {
      return "Simulation Result";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: _getPageTitle(), // GUNAKAN DYNAMIC TITLE
      ),
      body: Skeletonizer(
        enabled: isLoading,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                BlueContainer(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Stack(
                            children: [
                              SizedBox(
                                width: 90,
                                height: 120,
                                child: ToeflProgressIndicator(
                                  value: (result?.percentage ?? 0) / 100.0,
                                  activeHexColor: mariner800,
                                  nonActiveHexColor: neutral40,
                                  size:
                                      MediaQuery.of(context).size.width * 1 / 5,
                                  strokeWidth: 18,
                                  strokeScaler: 1.2,
                                ),
                              ),
                              Positioned(
                                top: 0,
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Text(
                                    "${result?.percentage ?? 0}%",
                                    textAlign: TextAlign.center,
                                    style: CustomTextStyle.extrabold24
                                        .copyWith(color: HexColor(mariner800)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Column(
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width * 0.54,
                                height:
                                    MediaQuery.of(context).size.height * 1 / 20,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      icon: SvgPicture.asset(
                                          'assets/icons/ic_time.svg'),
                                      onPressed: () {},
                                    ),
                                    SizedBox(
                                      width: 70,
                                      child: Text(
                                        widget.isMiniTest
                                            ? 'answered_questions'.tr()
                                            : "Toefl score",
                                        style: CustomTextStyle.medium14,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      widget.isMiniTest
                                          ? "${result?.answeredQuestion ?? 0}/${result?.totalQuestionAll ?? 0}"
                                          : "${result?.toeflScore ?? 0}/${result?.targetUser ?? 0}",
                                      style: CustomTextStyle.bold16,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(
                                      width: 20,
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: MediaQuery.of(context).size.width * 0.54,
                                height:
                                    MediaQuery.of(context).size.height * 1 / 20,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      icon: SvgPicture.asset(
                                          'assets/icons/ic_checklist.svg'),
                                      onPressed: () {},
                                    ),
                                    SizedBox(
                                      width: 70,
                                      child: Text(
                                        'correct_questions'.tr(),
                                        style: CustomTextStyle.medium14,
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      "${result?.correctQuestionAll ?? "0"}/${result?.totalQuestionAll ?? "0"}",
                                      style: CustomTextStyle.bold16,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(
                                      width: 20,
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(
                          top: 60, left: 24, right: 24, bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: HexColor(primaryWhite),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            blurRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildContainerTest(
                            partText: "Part A",
                            progressValue: (result?.accuracyListeningPartA ?? 0)
                                    .toDouble() /
                                100,
                            progressText:
                                "${result?.accuracyListeningPartA ?? "0"}%",
                            totalQuestions:
                                "${result?.listeningPartACorrect ?? "0"}/${result?.totalListeningPartA ?? "0"}",
                            correctness: "Correct",
                            progressColor: Colors.green,
                          ),
                          const SizedBox(height: 12),
                          _buildContainerTest(
                            partText: "Part B",
                            progressValue: (result?.accuracyListeningPartB ?? 0)
                                    .toDouble() /
                                100,
                            progressText:
                                "${result?.accuracyListeningPartB ?? "0"}%",
                            totalQuestions:
                                "${result?.correctListeningPartB ?? "0"}/${result?.totalListeningPartB ?? "0"}",
                            correctness: "Correct",
                            progressColor: HexColor(colorWarning),
                          ),
                          const SizedBox(height: 12),
                          _buildContainerTest(
                            partText: "Part C",
                            progressValue: (result?.accuracyListeningPartC ?? 0)
                                    .toDouble() /
                                100,
                            progressText:
                                "${result?.accuracyListeningPartC ?? "0"}%",
                            totalQuestions:
                                "${result?.correctListeningPartC ?? "0"}/${result?.totalListeningPartC ?? "0"}",
                            correctness: "Correct",
                            progressColor: HexColor(colorError),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10)),
                        color: HexColor(mariner500),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            blurRadius: 1,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      width: MediaQuery.of(context).size.width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Listening Comprehension : ",
                              style: CustomTextStyle.bold16
                                  .copyWith(color: HexColor(primaryWhite))),
                          Text(
                              "${result?.correctListeningAll ?? "0"}/${result?.totalListeningAll ?? "0"}",
                              style: CustomTextStyle.extraBold16
                                  .copyWith(color: HexColor(mariner950))),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 18),
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(
                          top: 60, left: 20, right: 24, bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: HexColor(primaryWhite),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            blurRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildContainerTest(
                            partText: "Part A",
                            progressValue: (result?.accuracyStructurePartA ?? 0)
                                    .toDouble() /
                                100,
                            progressText:
                                "${result?.accuracyStructurePartA ?? "0"}%",
                            totalQuestions:
                                "${result?.correctStructurePartA ?? "0"}/${result?.totalStructurePartA ?? "0"}",
                            correctness: "Correct",
                            progressColor: HexColor(colorError),
                          ),
                          const SizedBox(height: 12),
                          _buildContainerTest(
                            partText: "Part B",
                            progressValue: (result?.accuracyStructurePartB ?? 0)
                                    .toDouble() /
                                100,
                            progressText:
                                "${result?.accuracyStructurePartB ?? "0"}%",
                            totalQuestions:
                                "${result?.correctStructurePartB ?? "0"}/${result?.totalStructurePartB ?? "0"}",
                            correctness: "Correct",
                            progressColor: HexColor(colorWarning),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10)),
                        color: HexColor(mariner500),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            blurRadius: 1,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      width: MediaQuery.of(context).size.width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Structure : ",
                              style: CustomTextStyle.bold16
                                  .copyWith(color: HexColor(primaryWhite))),
                          Text(
                              "${result?.correctStructureAll ?? "0"}/${result?.totalStructureAll ?? "0"}",
                              style: CustomTextStyle.extraBold16
                                  .copyWith(color: HexColor(mariner950))),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 18),
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(
                          top: 60, left: 20, right: 24, bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: HexColor(primaryWhite),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            blurRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildContainerTest(
                            partText: "Part A",
                            progressValue:
                                (result?.accuracyReading ?? 0).toDouble() / 100,
                            progressText: "${result?.accuracyReading ?? "0"}%",
                            totalQuestions:
                                "${result?.correctReading ?? "0"}/${result?.totalReading ?? "0"}",
                            correctness: "Correct",
                            progressColor: Colors.green,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10)),
                        color: HexColor(mariner500),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            blurRadius: 1,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      width: MediaQuery.of(context).size.width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Reading Comprehension : ",
                              style: CustomTextStyle.bold16
                                  .copyWith(color: HexColor(primaryWhite))),
                          Text(
                              "${result?.correctReading ?? "0"}/${result?.totalReading ?? "0"}",
                              style: CustomTextStyle.extraBold16
                                  .copyWith(color: HexColor(mariner950))),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                    decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: HexColor(mariner700))),
                    child: Text('btn_back_course'.tr(),
                        textAlign: TextAlign.center,
                        style: CustomTextStyle.bold18
                            .copyWith(color: HexColor(mariner700))),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildContainerTest({
  required String partText,
  required double progressValue,
  required String progressText,
  required String totalQuestions,
  required String correctness,
  required Color progressColor,
}) {
  return Row(
    children: [
      Text(
        partText,
        style: CustomTextStyle.semibold12.copyWith(color: HexColor(mariner700)),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 50,
        child: Text(
          totalQuestions,
          textAlign: TextAlign.center,
          style: CustomTextStyle.bold12.copyWith(color: HexColor(mariner900)),
        ),
      ),
      SvgPicture.asset(
        "assets/icons/ic_pembatas_putih.svg",
      ),
      const SizedBox(width: 8),
      Text(
        correctness,
        style: CustomTextStyle.regular10.copyWith(color: HexColor(neutral50)),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: LinearProgressIndicator(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          minHeight: 8,
          backgroundColor: HexColor(mariner100),
          value: progressValue,
          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        progressText,
        style: CustomTextStyle.bold12.copyWith(color: HexColor(mariner700)),
      ),
    ],
  );
}
