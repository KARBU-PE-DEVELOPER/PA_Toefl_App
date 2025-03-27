import 'package:flutter/material.dart';
import 'package:toefl/routes/navigator_key.dart';
import '../../utils/colors.dart';
import '../../utils/custom_text_style.dart';
import '../../utils/hex_color.dart';

class BottomSheetFullTest extends StatefulWidget {
  const BottomSheetFullTest({
    Key? key,
    required this.filledStatus,
    required this.onTap,
  }) : super(key: key);

  final List<bool> filledStatus;
  final Function(int) onTap;

  @override
  State<BottomSheetFullTest> createState() => _BottomSheetFullTestState();
}

class _BottomSheetFullTestState extends State<BottomSheetFullTest> {
  int selectedPage = 0;
  final PageController pageController = PageController();

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  // Fungsi untuk mengubah status pertanyaan menjadi answered (true)
  void updateFilledStatus(int index) {
    setState(() {
      widget.filledStatus[index] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      height: screenHeight * 0.6,
      decoration: BoxDecoration(
        color: HexColor(neutral20),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 65,
                height: 4,
                color: HexColor(neutral60),
              ),
            ),
            const SizedBox(height: 30),
            // Menu tab: All, Answered, Unanswered
            Row(
              children: [
                buildMenu(
                  "All(${widget.filledStatus.length})",
                  selectedPage == 0,
                  () {
                    setState(() {
                      selectedPage = 0;
                      pageController.animateToPage(
                        0,
                        duration: const Duration(milliseconds: 10),
                        curve: Curves.easeIn,
                      );
                    });
                  },
                ),
                const Spacer(),
                buildMenu(
                  "Answered(${widget.filledStatus.where((element) => element).length})",
                  selectedPage == 1,
                  () {
                    setState(() {
                      selectedPage = 1;
                      pageController.animateToPage(
                        1,
                        duration: const Duration(milliseconds: 10),
                        curve: Curves.easeIn,
                      );
                    });
                  },
                ),
                const Spacer(),
                buildMenu(
                  "Unanswered(${widget.filledStatus.where((element) => !element).length})",
                  selectedPage == 2,
                  () {
                    setState(() {
                      selectedPage = 2;
                      pageController.animateToPage(
                        2,
                        duration: const Duration(milliseconds: 10),
                        curve: Curves.easeIn,
                      );
                    });
                  },
                ),
              ],
            ),
            Divider(height: 2, color: HexColor(neutral40)),
            SizedBox(
              height: screenHeight * 0.45,
              child: PageView(
                controller: pageController,
                onPageChanged: (index) {
                  setState(() {
                    selectedPage = index;
                  });
                },
                children: [
                  buildQuestionGrid(), // Semua pertanyaan
                  buildQuestionGrid(
                      answeredOnly: true), // Hanya yang sudah dijawab
                  buildQuestionGrid(
                      unansweredOnly: true), // Hanya yang belum dijawab
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildQuestionGrid(
      {bool answeredOnly = false, bool unansweredOnly = false}) {
    final screenWidth = MediaQuery.of(context).size.width;
    List<int> questionNumbers =
        List.generate(widget.filledStatus.length, (index) => index + 1);

    if (answeredOnly) {
      questionNumbers = questionNumbers
          .where((number) => widget.filledStatus[number - 1])
          .toList();
    } else if (unansweredOnly) {
      questionNumbers = questionNumbers
          .where((number) => !widget.filledStatus[number - 1])
          .toList();
    }

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Wrap(
            spacing: screenWidth * 0.03,
            runSpacing: screenWidth * 0.03,
            children: questionNumbers.map((number) {
              return buildNumOption(
                number,
                () {
                  // Set pertanyaan terjawab dan kembalikan nomor pertanyaan
                  updateFilledStatus(number - 1);
                  Navigator.of(context).pop(number);
                  widget.onTap(number);
                },
                isActive: widget.filledStatus[number - 1],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget buildNumOption(int number, Function onTap, {bool isActive = false}) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive ? HexColor(mariner700) : Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            "$number",
            style: CustomTextStyle.bold16.copyWith(
              color: isActive ? Colors.white : HexColor(neutral50),
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildMenu(String title, bool isActive, Function onTap) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Column(
        children: [
          Text(
            title,
            style: CustomTextStyle.medium14.copyWith(
              color: isActive ? Colors.black : HexColor(neutral60),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 80,
            height: 3,
            color: isActive ? HexColor(mariner700) : Colors.transparent,
          ),
        ],
      ),
    );
  }
}
