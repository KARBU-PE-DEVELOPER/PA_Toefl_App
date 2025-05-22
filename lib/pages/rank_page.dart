import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:toefl/models/leader_board.dart';
import 'package:toefl/remote/api/games/leaderboard_api.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:toefl/widgets/common_app_bar.dart';
import 'package:toefl/widgets/rank_page/list_rank.dart';
import 'package:toefl/widgets/rank_page/profile_rank.dart';
import 'dart:math' as math;

class RankPage extends StatefulWidget {
  final List<LeaderBoard> dataRank;
  const RankPage({super.key, required this.dataRank});

  @override
  State<RankPage> createState() => _RankPageState();
}

class _RankPageState extends State<RankPage> {
  List<LeaderBoard> listRank = [];

  bool isLoading = false;

  // Fetch leaderboard data when the page is opened
  Future<void> refreshData() async {
    if (mounted) setState(() => isLoading = true);
    List<LeaderBoard> data = await LeaderBoardApi().getLeaderBoardEntries();

    // Urutkan data berdasarkan skor tertinggi (descending)
    data.sort((a, b) => (double.tryParse(b.highestScore) ?? 0)
        .compareTo(double.tryParse(a.highestScore) ?? 0));

    if (mounted)
      setState(() {
        listRank = data;
        isLoading = false;
      });
  }

  @override
  void initState() {
    super.initState();
    refreshData(); // Fetch leaderboard data when the page is opened
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        withBack: false,
        title: 'Leaderboard',
        backgroundColor: HexColor(mariner100),
      ),
      body: RefreshIndicator(
        onRefresh: refreshData,
        child: Skeletonizer(
          enabled: isLoading,
          child: Skeleton.leaf(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  height: MediaQuery.of(context).size.height * 0.4,
                  alignment: Alignment.bottomCenter,
                  child: listRank.isNotEmpty
                      ? ListView.builder(
                          itemCount: math.max(0, listRank.length - 3),
                          itemBuilder: (context, index) {
                            final actualIndex =
                                index + 3; // Mulai dari peringkat ke-4
                            return Padding(
                              padding: EdgeInsets.only(
                                top: index == 0 ? 90 : 8,
                                bottom:
                                    actualIndex == listRank.length - 1 ? 20 : 8,
                                left: 24,
                                right: 24,
                              ),
                              child: ListRank(
                                index:
                                    actualIndex + 1, // Rank ke-4 dan seterusnya
                                name: listRank[actualIndex].userName,
                                score: (double.tryParse(listRank[actualIndex]
                                            .highestScore) ??
                                        0)
                                    .toInt(),
                              ),
                            );
                          })
                      : const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Take a game to participate'),
                        ),
                ),
                Positioned(
                  top: -200,
                  child: CustomPaint(
                    size: const Size(650, 600),
                    painter: BgRank(),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          "Take a game to participate",
                          style: TextStyle(
                            fontSize: 16,
                            color: HexColor(neutral60),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        verticalDirection: VerticalDirection.up,
                        children: <Widget>[
                          Expanded(
                            child: Transform.translate(
                              offset: const Offset(0, 80),
                              child: ProfileRank(
                                name: listRank.length > 1
                                    ? listRank[1].userName
                                    : "?",
                                score: listRank.length > 1
                                    ? (double.tryParse(
                                                listRank[1].highestScore) ??
                                            0)
                                        .toInt()
                                    : 0,
                                category: "Silver",
                                rank: 2,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ProfileRank(
                              isMiddle: true,
                              name: listRank.isNotEmpty
                                  ? listRank[0].userName
                                  : "?",
                              score: listRank.isNotEmpty
                                  ? (double.tryParse(
                                              listRank[0].highestScore) ??
                                          0)
                                      .toInt()
                                  : 0,
                              category: "Gold",
                              rank: 1,
                            ),
                          ),
                          Expanded(
                            child: Transform.translate(
                              offset: const Offset(0, 80),
                              child: ProfileRank(
                                name: listRank.length > 2
                                    ? listRank[2].userName
                                    : "?",
                                score: listRank.length > 2
                                    ? (double.tryParse(
                                                listRank[2].highestScore) ??
                                            0)
                                        .toInt()
                                    : 0,
                                category: "Bronze",
                                rank: 3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BgRank extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = HexColor(mariner100)
      ..strokeWidth = 4
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
