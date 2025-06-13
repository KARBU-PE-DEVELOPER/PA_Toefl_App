import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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
  bool isLoading = false;
  Result? result;
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

  // FUNCTION UNTUK KEMBALI KE DASHBOARD
  void _navigateToDashboard() {
    // Hapus semua route dan kembali ke dashboard
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/main', // Ganti dengan route dashboard Anda
      (Route<dynamic> route) => false,
    );
  }

  // FUNCTION UNTUK MENAMPILKAN SERTIFIKAT
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
                // Certificate content
                RepaintBoundary(
                  key: _certificateKey,
                  child: _buildCertificateContent(),
                ),
                // Close button
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

  // FUNCTION UNTUK MEMBUAT KONTEN SERTIFIKAT
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
            // Header dengan logo/icon
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

            // Title
            Text(
              'CERTIFICATE OF ACHIEVEMENT',
              style: CustomTextStyle.extrabold24.copyWith(
                color: HexColor(mariner800),
                fontSize: 28,
                letterSpacing: 2,
              ),
              textAlign: TextAlign.center,
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

            // Content
            Text(
              'This is to certify that',
              style: CustomTextStyle.medium14.copyWith(
                color: HexColor(neutral70),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),

            // Name (using current user login)
            Container(
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
                'Dony-Ahmad-Hisyam', // Current user's login
                style: CustomTextStyle.extrabold24.copyWith(
                  color: HexColor(mariner800),
                  fontSize: 32,
                ),
              ),
            ),
            const SizedBox(height: 30),

            Text(
              'has successfully completed the',
              style: CustomTextStyle.medium14.copyWith(
                color: HexColor(neutral70),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),

            // Test type
            Text(
              widget.packetType.toUpperCase() == 'TEST'
                  ? 'TOEFL TEST'
                  : 'TOEFL SIMULATION',
              style: CustomTextStyle.extrabold24.copyWith(
                color: HexColor(mariner700),
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 8),

            // Packet name
            Text(
              '"${widget.packetName}"',
              style: CustomTextStyle.bold16.copyWith(
                color: HexColor(mariner600),
                fontSize: 18,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Score section
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
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildScoreItem(
                          'TOTAL SCORE', '${result?.toeflScore ?? 0}'),
                      _buildScoreItem(
                          'PERCENTAGE', '${result?.percentage ?? 0}%'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildScoreItem('LISTENING',
                          '${result?.correctListeningAll ?? 0}/${result?.totalListeningAll ?? 0}'),
                      _buildScoreItem('STRUCTURE',
                          '${result?.correctStructureAll ?? 0}/${result?.totalStructureAll ?? 0}'),
                      _buildScoreItem('READING',
                          '${result?.correctReading ?? 0}/${result?.totalReading ?? 0}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Date and signature section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text(
                      'Date of Completion',
                      style: CustomTextStyle.medium14.copyWith(
                        color: HexColor(neutral60),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formattedDate,
                      style: CustomTextStyle.bold16.copyWith(
                        color: HexColor(mariner700),
                      ),
                    ),
                  ],
                ),
                Column(
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
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Footer
            Text(
              'VOCADIA TOEFL PREPARATION',
              style: CustomTextStyle.bold16.copyWith(
                color: HexColor(mariner600),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget untuk score items
  Widget _buildScoreItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: CustomTextStyle.medium14.copyWith(
            color: HexColor(neutral60),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: CustomTextStyle.extrabold24.copyWith(
            color: HexColor(mariner800),
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Menggunakan PopScope untuk Flutter versi terbaru atau WillPopScope untuk versi lama
    return PopScope(
      canPop: false, // Mencegah back gesture
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
                            // FIXED: Improved layout untuk score containers
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    height: MediaQuery.of(context).size.height *
                                        1 /
                                        20,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: SvgPicture.asset(
                                              'assets/icons/ic_time.svg'),
                                          onPressed: () {},
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 40,
                                            minHeight: 40,
                                          ),
                                        ),
                                        // FIXED: Flexible text untuk mencegah overflow
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            widget.isMiniTest
                                                ? 'answered_questions'.tr()
                                                : "Toefl score",
                                            style: CustomTextStyle.medium14
                                                .copyWith(
                                              fontSize:
                                                  12, // Smaller font to prevent overflow
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        // const SizedBox(width: 4),
                                        // FIXED: Flexible score text
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            widget.isMiniTest
                                                ? "${result?.answeredQuestion ?? 0}/${result?.totalQuestionAll ?? 0}"
                                                : "${result?.toeflScore ?? 0}/${result?.targetUser ?? 0}",
                                            style:
                                                CustomTextStyle.bold16.copyWith(
                                              fontSize: 14, // Smaller font
                                            ),
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: MediaQuery.of(context).size.height *
                                        1 /
                                        20,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: SvgPicture.asset(
                                              'assets/icons/ic_checklist.svg'),
                                          onPressed: () {},
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 40,
                                            minHeight: 40,
                                          ),
                                        ),
                                        // FIXED: Flexible text untuk mencegah overflow
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            'correct_questions'.tr(),
                                            style: CustomTextStyle.medium14
                                                .copyWith(
                                              fontSize: 12, // Smaller font
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        // FIXED: Flexible score text
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            "${result?.correctQuestionAll ?? "0"}/${result?.totalQuestionAll ?? "0"}",
                                            style:
                                                CustomTextStyle.bold16.copyWith(
                                              fontSize: 14, // Smaller font
                                            ),
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
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

                  // NEW: Certificate button (hanya untuk type test dan jika ada result)
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
