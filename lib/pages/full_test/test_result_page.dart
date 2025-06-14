import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:toefl/models/test/history.dart';
import 'package:toefl/models/test/result.dart';
import 'package:toefl/remote/api/full_test_api.dart';
import 'package:toefl/remote/api/history_api.dart';
import 'package:toefl/remote/api/profile_api.dart';
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
    required this.packetType,
  });

  final String packetId;
  final bool isMiniTest;
  final String packetName;
  final String packetType;

  @override
  State<TestResultPage> createState() => _TestResultPageState();
}

class _TestResultPageState extends State<TestResultPage> {
  FullTestApi api = FullTestApi();
  ProfileApi profileApi = ProfileApi();
  HistoryApi historyApi = HistoryApi();
  bool isLoading = false;
  Result? result;
  String? userName;
  HistoryItem? historyItem;
  static const platform = MethodChannel('com.pens.vocadia/exam_security');
  final GlobalKey _certificateKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _init();
    if (widget.packetType == "test") {
      platform.invokeMethod('stopExamMode').catchError((e) {
        debugPrint("Error stopping native exam mode: $e");
      });
    }
  }

  void _init() async {
    setState(() {
      isLoading = true;
    });

    await Future.wait([
      _loadTestResult(),
      _loadUserProfile(),
      _loadHistoryData(),
    ]);

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadTestResult() async {
    try {
      result = await api.getTestResult(widget.packetId);
    } catch (e) {
      debugPrint("Error loading test result: $e");
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await profileApi.getProfile();
      setState(() {
        userName = profile.nameUser;
      });
      debugPrint("User profile loaded: $userName");
    } catch (e) {
      debugPrint("Error loading user profile: $e");
      setState(() {
        userName = "VocaBot";
      });
    }
  }

  Future<void> _loadHistoryData() async {
    try {
      final packetIdInt = int.parse(widget.packetId);
      historyItem = await historyApi.getHistoryByPacketId(packetIdInt);
      debugPrint("History data loaded: ${historyItem?.displayPacketName}");
    } catch (e) {
      debugPrint("Error loading history data: $e");
    }
  }

  String _getPageTitle() {
    if (widget.packetType.toLowerCase() == "test") {
      return "Test Result";
    } else {
      return "Simulation Result";
    }
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/main',
      (Route<dynamic> route) => false,
    );
  }

  String get displayPacketName {
    if (historyItem != null) {
      return historyItem!.displayPacketName;
    }
    return widget.packetName.isNotEmpty
        ? widget.packetName
        : 'Test Package ${widget.packetId}';
  }

  void _showCertificate() {
    if (result == null) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
              maxWidth: MediaQuery.of(context).size.width * 0.95,
            ),
            child: Stack(
              children: [
                RepaintBoundary(
                  key: _certificateKey,
                  child: _buildCertificateContent(),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCertificateContent() {
    final DateTime now = DateTime.now();
    final String formattedDate = DateFormat('MMMM dd, yyyy').format(now);

    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            HexColor(mariner50),
          ],
        ),
        border: Border.all(
          color: HexColor(mariner500),
          width: 8,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HexColor(mariner500),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.school,
                size: 48,
                color: HexColor(primaryWhite),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'CERTIFICATE OF ACHIEVEMENT',
              style: CustomTextStyle.extrabold24.copyWith(
                color: HexColor(mariner800),
                fontSize: 28,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
              softWrap: true,
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Container(
              height: 3,
              width: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    HexColor(mariner300),
                    HexColor(mariner700),
                    HexColor(mariner300),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'This is to certify that',
              style: CustomTextStyle.medium14.copyWith(
                color: HexColor(neutral70),
                fontSize: 18,
              ),
              softWrap: true,
            ),
            const SizedBox(height: 16),
            // FIXED: User name with proper wrapping
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: HexColor(mariner500),
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                userName != null ? userName! : "VocaBot",
                style: CustomTextStyle.extrabold24.copyWith(
                  color: HexColor(mariner800),
                  fontSize: 32,
                ),
                textAlign: TextAlign.center,
                softWrap: true,
                maxLines: 3, // Allow up to 3 lines for very long names
                overflow: TextOverflow.visible,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'has successfully completed the',
              style: CustomTextStyle.medium14.copyWith(
                color: HexColor(neutral70),
                fontSize: 18,
              ),
              softWrap: true,
            ),
            const SizedBox(height: 12),
            Text(
              widget.packetType.toUpperCase() == 'TEST'
                  ? 'TOEFL TEST'
                  : 'TOEFL SIMULATION',
              style: CustomTextStyle.extrabold24.copyWith(
                color: HexColor(mariner700),
                fontSize: 24,
              ),
              softWrap: true,
            ),
            const SizedBox(height: 8),
            // FIXED: Packet name with proper wrapping and responsive container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: HexColor(mariner50),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: HexColor(mariner200),
                  width: 1,
                ),
              ),
              child: Text(
                '"${displayPacketName}"',
                style: CustomTextStyle.bold16.copyWith(
                  color: HexColor(mariner600),
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
                softWrap: true,
                maxLines: 4, // Allow multiple lines for long packet names
                overflow: TextOverflow.visible,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: HexColor(mariner100),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: HexColor(mariner300),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'ACHIEVEMENT SCORE',
                    style: CustomTextStyle.bold16.copyWith(
                      color: HexColor(mariner800),
                      letterSpacing: 1,
                    ),
                    softWrap: true,
                  ),
                  const SizedBox(height: 12),
                  // FIXED: Responsive score layout
                  Wrap(
                    alignment: WrapAlignment.spaceAround,
                    children: [
                      _buildScoreItem(
                          'TOTAL SCORE', '${result?.toeflScore ?? 0}'),
                      const SizedBox(width: 20), // Add spacing between items
                      _buildScoreItem(
                          'PERCENTAGE', '${result?.percentage ?? 0}%'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // FIXED: Responsive detailed scores layout
                  Wrap(
                    alignment: WrapAlignment.spaceAround,
                    children: [
                      _buildScoreItem('LISTENING',
                          '${result?.correctListeningAll ?? 0}/${result?.totalListeningAll ?? 0}'),
                      const SizedBox(width: 10),
                      _buildScoreItem('STRUCTURE',
                          '${result?.correctStructureAll ?? 0}/${result?.totalStructureAll ?? 0}'),
                      const SizedBox(width: 10),
                      _buildScoreItem('READING',
                          '${result?.correctReading ?? 0}/${result?.totalReading ?? 0}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // FIXED: Responsive bottom section
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Text(
                        'Date of Completion',
                        style: CustomTextStyle.medium14.copyWith(
                          color: HexColor(neutral60),
                        ),
                        softWrap: true,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formattedDate,
                        style: CustomTextStyle.bold16.copyWith(
                          color: HexColor(mariner700),
                        ),
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Container(
                        height: 2,
                        width: 120,
                        color: HexColor(mariner500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Administrator',
                        style: CustomTextStyle.medium14.copyWith(
                          color: HexColor(neutral60),
                        ),
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'VOCADIA TOEFL PREPARATION',
              style: CustomTextStyle.bold16.copyWith(
                color: HexColor(mariner600),
                letterSpacing: 1,
              ),
              softWrap: true,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

// FIXED: Updated score item with better text handling
  Widget _buildScoreItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        children: [
          Text(
            label,
            style: CustomTextStyle.medium14.copyWith(
              color: HexColor(neutral60),
              fontSize: 10,
            ),
            softWrap: true,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: CustomTextStyle.extrabold24.copyWith(
              color: HexColor(mariner800),
              fontSize: 18,
            ),
            softWrap: true,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // FIXED: Build score container with better overflow handling
  Widget _buildScoreContainer({
    required String iconPath,
    required String label,
    required String value,
  }) {
    return Container(
      height: MediaQuery.of(context).size.height * 1 / 20,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          // Icon with fixed width
          SizedBox(
            width: 36,
            child: IconButton(
              icon: SvgPicture.asset(iconPath),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
            ),
          ),
          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Label with minimum space
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 60),
                    child: Text(
                      label,
                      style: CustomTextStyle.medium14.copyWith(
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.visible,
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Score with adequate space
                  Text(
                    value,
                    style: CustomTextStyle.bold16.copyWith(
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.visible,
                  ),
                  const SizedBox(width: 8), // Extra padding for scroll
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _navigateToDashboard();
        }
      },
      child: Scaffold(
        appBar: CommonAppBar(
          title: _getPageTitle(),
          withBack: false,
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
                                    size: MediaQuery.of(context).size.width *
                                        1 /
                                        5,
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
                                          .copyWith(
                                              color: HexColor(mariner800)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            // FIXED: Improved layout for score containers with horizontal scroll
                            Expanded(
                              child: Column(
                                children: [
                                  // First score container
                                  _buildScoreContainer(
                                    iconPath: 'assets/icons/ic_time.svg',
                                    label: widget.isMiniTest
                                        ? 'answered_questions'.tr()
                                        : "Toefl score",
                                    value: widget.isMiniTest
                                        ? "${result?.answeredQuestion ?? 0}/${result?.totalQuestionAll ?? 0}"
                                        : "${result?.toeflScore ?? 0}/${result?.targetUser ?? 0}",
                                  ),
                                  const SizedBox(height: 8),
                                  // Second score container
                                  _buildScoreContainer(
                                    iconPath: 'assets/icons/ic_checklist.svg',
                                    label: 'correct_questions'.tr(),
                                    value:
                                        "${result?.correctQuestionAll ?? "0"}/${result?.totalQuestionAll ?? "0"}",
                                  ),
                                ],
                              ),
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
                              progressValue:
                                  (result?.accuracyListeningPartA ?? 0)
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
                              progressValue:
                                  (result?.accuracyListeningPartB ?? 0)
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
                              progressValue:
                                  (result?.accuracyListeningPartC ?? 0)
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
                              progressValue:
                                  (result?.accuracyStructurePartA ?? 0)
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
                              progressValue:
                                  (result?.accuracyStructurePartB ?? 0)
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
                                  (result?.accuracyReading ?? 0).toDouble() /
                                      100,
                              progressText:
                                  "${result?.accuracyReading ?? "0"}%",
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
                  if (widget.packetType.toLowerCase() == "test" &&
                      result != null) ...[
                    GestureDetector(
                      onTap: _showCertificate,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              HexColor(mariner500),
                              HexColor(mariner600),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: HexColor(mariner500).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.workspace_premium,
                              color: HexColor(primaryWhite),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'View Certificate',
                              textAlign: TextAlign.center,
                              style: CustomTextStyle.bold18.copyWith(
                                color: HexColor(primaryWhite),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  GestureDetector(
                    onTap: _navigateToDashboard,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 24),
                      decoration: BoxDecoration(
                          color: HexColor(mariner700),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        'Back to Dashboard',
                        textAlign: TextAlign.center,
                        style: CustomTextStyle.bold18.copyWith(
                          color: HexColor(primaryWhite),
                        ),
                      ),
                    ),
                  )
                ],
              ),
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
