import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:toefl/models/estimated_score.dart' as model;
import 'package:toefl/models/game_data.dart';
import 'package:toefl/pages/rank_page.dart';
import 'package:toefl/remote/api/estimated_score.dart';
import 'package:toefl/routes/route_key.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:toefl/widgets/home_page/topic_interest.dart';
import 'package:toefl/widgets/quiz/modal/modal_confirmation.dart';
import 'package:toefl/widgets/toefl_progress_indicator.dart';

import 'user_rank_card.dart';

class EstimatedScoreWidget extends StatefulWidget {
  EstimatedScoreWidget({super.key});

  @override
  State<EstimatedScoreWidget> createState() => _EstimatedScoreWidgetState();
}

class _EstimatedScoreWidgetState extends State<EstimatedScoreWidget> {
  final estimatedScoreApi = EstimatedScoreApi();
  model.EstimatedScore? estimatedScore;
  Map<String, dynamic> score = {};
  bool isLoading = false;
  final _controller = PageController();

  @override
  void initState() {
    super.initState();
    fetchEstimatedScore();
  }

  void fetchEstimatedScore() async {
    _setLoadingState(true);

    try {
      model.EstimatedScore temp = await estimatedScoreApi.getEstimatedScore();
      _updateScore(temp);
    } catch (e) {
      print("Error in fetchEstimatedScore: $e");
    } finally {
      _setLoadingState(false);
    }
  }

  void _setLoadingState(bool isLoading) {
    if (mounted) {
      setState(() {
        this.isLoading = isLoading;
      });
    }
  }

  void _updateScore(model.EstimatedScore temp) {
    if (mounted) {
      setState(() {
        estimatedScore = temp;
        score = {
          'Listening Score': temp.scoreListening,
          'Structure Score': temp.scoreStructure,
          'Reading Score': temp.scoreReading,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: MediaQuery.of(context).size.height / 4.5,
          child: PageView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              Skeletonizer(
                enabled: isLoading,
                child: Skeleton.leaf(
                  child: LayoutBuilder(builder: (context, constraint) {
                    return Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFC4D7FF), // Border color
                            width: 2, // Border width
                          ),
                          color: HexColor(mariner400)),
                      margin: EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "${estimatedScore?.userScore}",
                                        style: TextStyle(
                                            fontSize: constraint.maxHeight / 7,
                                            fontWeight: FontWeight.w800,
                                            height: 0.9,
                                            color: Color(0xFF00394C)),
                                      ),
                                      Text(
                                        "/${estimatedScore?.targetUser}",
                                        style: TextStyle(
                                            fontSize: constraint.maxHeight / 10,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF585A66)),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  child: ToeflProgressIndicator(
                                    value: (estimatedScore?.userScore ?? 0) /
                                        _getTargetScore(),
                                    scale: constraint.maxHeight / 150,
                                    strokeWidth: constraint.maxHeight / 10,
                                    strokeScaler: constraint.maxHeight / 180,
                                    activeHexColor: mariner700,
                                    nonActiveHexColor: mariner200,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  // "Estimated score",
                                  'My Target'.tr(),
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF00394C),
                                      height: 2),
                                ),
                                ...score.entries.map(
                                  (entry) => Text(
                                    '${entry.key}: ${entry.value}',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontFamily:
                                            GoogleFonts.nunito().fontFamily,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w400),
                                  ),
                                ),
                                SizedBox(
                                  height: 16,
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pushNamed(
                                      context, RouteKey.setTargetPage),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF47AFFF),
                                    minimumSize: const Size(140,
                                        38), // Fixed width (140px) and height (38px)
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 9,
                                        horizontal: 34), // Padding (9px, 34px)
                                    shape: const RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(12)),
                                    ),
                                  ),
                                  child: Text(
                                    'Set Now'.tr(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily:
                                          GoogleFonts.nunito().fontFamily,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white, // White text color
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 30,
        ),
        // const Padding(
        //   padding: EdgeInsets.symmetric(horizontal: 14),
        //   child: Text(
        //     "Today’s Learning",
        //     style: TextStyle(
        //         color: Color(0xFF00394C),
        //         fontSize: 24,
        //         fontWeight: FontWeight.w700),
        //   ),
        // ),
        // const KeeplearningProgress(),
      ],
    );
  }

  int _getTargetScore() {
    var tmp = estimatedScore?.targetUser ?? 0;
    return tmp <= 0 ? 1 : tmp;
  }
}
