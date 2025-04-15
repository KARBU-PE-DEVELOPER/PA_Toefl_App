import 'package:flutter/material.dart';
import 'package:toefl/routes/navigator_key.dart';
import '../../utils/colors.dart';
import '../../utils/custom_text_style.dart';
import '../../utils/hex_color.dart';

class BottomSheetFullTest extends StatefulWidget {
  const BottomSheetFullTest({
    super.key,
    required this.filledStatus,
    required this.onTap,
  });

  final List<bool> filledStatus;
  final Function(int) onTap;

  @override
  State<BottomSheetFullTest> createState() => _BottomSheetFullTestState();
}

class _BottomSheetFullTestState extends State<BottomSheetFullTest> {
  var selectedPage = 0;
  var pageController = PageController();

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

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
              child:
                  Container(width: 65, height: 4, color: HexColor(neutral60)),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                buildMenu(
                    "All (${widget.filledStatus.length})", selectedPage == 0,
                    () {
                  setState(() {
                    selectedPage = 0;
                    pageController.jumpToPage(0);
                  });
                }),
                const Spacer(),
                buildMenu(
                    "Answered (${widget.filledStatus.where((e) => e).length})",
                    selectedPage == 1, () {
                  setState(() {
                    selectedPage = 1;
                    pageController.jumpToPage(1);
                  });
                }),
                const Spacer(),
                buildMenu(
                    "Unanswered (${widget.filledStatus.where((e) => !e).length})",
                    selectedPage == 2, () {
                  setState(() {
                    selectedPage = 2;
                    pageController.jumpToPage(2);
                  });
                }),
              ],
            ),
            Divider(height: 2, color: HexColor(neutral40)),
            Expanded(
              child: PageView(
                controller: pageController,
                onPageChanged: (index) => setState(() => selectedPage = index),
                children: [
                  buildNumberGrid(widget.onTap, widget.filledStatus),
                  buildNumberGrid(widget.onTap, widget.filledStatus,
                      answered: true),
                  buildNumberGrid(widget.onTap, widget.filledStatus,
                      unanswered: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMenu(String title, bool isActive, Function onTap) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Column(
        children: [
          Text(title,
              style: CustomTextStyle.medium14.copyWith(
                  color: isActive ? Colors.black : HexColor(neutral60))),
          const SizedBox(height: 6),
          Container(
              width: 80,
              height: 3,
              color: isActive ? HexColor(mariner700) : Colors.transparent),
        ],
      ),
    );
  }

  Widget buildNumberGrid(Function(int) onTap, List<bool> filledStatus,
      {bool answered = false, bool unanswered = false}) {
    final screenWidth = MediaQuery.of(context).size.width;

    List<int> questionNumbers =
        List.generate(filledStatus.length, (i) => i + 1);
    if (answered) {
      questionNumbers =
          questionNumbers.where((i) => filledStatus[i - 1]).toList();
    } else if (unanswered) {
      questionNumbers =
          questionNumbers.where((i) => !filledStatus[i - 1]).toList();
    }

    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: screenWidth * 0.03,
            runSpacing: screenWidth * 0.03,
            children: questionNumbers
                .map((num) => buildNumOption(
                    num, () => Navigator.of(context).pop(num),
                    isActive: filledStatus[num - 1]))
                .toList(),
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
}
