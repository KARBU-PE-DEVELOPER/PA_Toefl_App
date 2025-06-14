import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:toefl/models/estimated_score.dart' as model;
import 'package:toefl/remote/api/estimated_score.dart';
import 'package:toefl/routes/route_key.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:toefl/widgets/toefl_progress_indicator.dart';

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
      debugPrint("Error in fetchEstimatedScore: $e");
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

  // Helper method untuk mendapatkan user score sebagai double
  double _getUserScoreAsDouble() {
    if (estimatedScore?.userScore == null) return 0.0;

    // Jika menggunakan model dengan String
    if (estimatedScore!.userScore is String) {
      return double.tryParse(estimatedScore!.userScore as String) ?? 0.0;
    }

    // Jika menggunakan model dengan double (alternative model)
    if (estimatedScore!.userScore is double) {
      return estimatedScore!.userScore as double;
    }

    return 0.0;
  }

  // Helper method untuk format score display
  String _formatScore(dynamic score) {
    if (score == null) return "0.00";

    if (score is String) {
      // Jika sudah string, langsung return
      return score;
    }

    if (score is double) {
      // Jika double, format ke 2 desimal
      return score.toStringAsFixed(2);
    }

    if (score is int) {
      // Jika int, convert ke double lalu format
      return score.toDouble().toStringAsFixed(2);
    }

    return score.toString();
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
                                        _formatScore(estimatedScore?.userScore),
                                        style: TextStyle(
                                            fontSize: constraint.maxHeight / 7,
                                            fontWeight: FontWeight.w800,
                                            height: 0.9,
                                            color: Color(0xFF00394C)),
                                      ),
                                      Text(
                                        "/${estimatedScore?.targetUser ?? 0}",
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
                                    value: _getUserScoreAsDouble() /
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
                                  'My Target'.tr(),
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF00394C),
                                      height: 2),
                                ),
                                ...score.entries.map(
                                  (entry) => Text(
                                    '${entry.key}: ${_formatScore(entry.value)}',
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
      ],
    );
  }

  int _getTargetScore() {
    var tmp = estimatedScore?.targetUser ?? 0;
    return tmp <= 0 ? 1 : tmp;
  }
}
