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
import 'package:easy_localization/easy_localization.dart';

class RankPage extends StatefulWidget {
  final List<LeaderBoard> dataRank;
  const RankPage({super.key, required this.dataRank});

  @override
  State<RankPage> createState() => _RankPageState();
}

class _RankPageState extends State<RankPage> {
  List<LeaderBoard> listRank = [];
  bool isLoading = false;

  Future<void> refreshData() async {
    setState(() => isLoading = true);
    List<LeaderBoard> data = await LeaderBoardApi().getLeaderBoardEntries();

    data.sort((a, b) => (double.tryParse(b.highestScore) ?? 0)
        .compareTo(double.tryParse(a.highestScore) ?? 0));

    setState(() {
      listRank = data;
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Putih bersih
      appBar: CommonAppBar(
        withBack: false,
        title: 'leaderboard'.tr(),
      ),
      body: RefreshIndicator(
        onRefresh: refreshData,
        child: Skeletonizer(
          enabled: isLoading,
          child: Skeleton.leaf(
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
                  child: Column(
                    children: [
                      Text(
                        "leaderboard_subtitle".tr(),
                        style: TextStyle(
                          fontSize: 16,
                          color: HexColor(neutral60),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          double profileHeight = constraints.maxWidth < 400 ? 180 : 200;

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Expanded(
                                child: Transform.translate(
                                  offset: const Offset(0, 40),
                                  child: ProfileRank(
                                    name: listRank.length > 1 ? listRank[1].userName : "?",
                                    score: listRank.length > 1
                                        ? (double.tryParse(listRank[1].highestScore) ?? 0).toInt()
                                        : 0,
                                    category: "Silver",
                                    rank: 2,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ProfileRank(
                                  isMiddle: true,
                                  name: listRank.isNotEmpty ? listRank[0].userName : "?",
                                  score: listRank.isNotEmpty
                                      ? (double.tryParse(listRank[0].highestScore) ?? 0).toInt()
                                      : 0,
                                  category: "Gold",
                                  rank: 1,
                                ),
                              ),
                              Expanded(
                                child: Transform.translate(
                                  offset: const Offset(0, 40),
                                  child: ProfileRank(
                                    name: listRank.length > 2 ? listRank[2].userName : "?",
                                    score: listRank.length > 2
                                        ? (double.tryParse(listRank[2].highestScore) ?? 0).toInt()
                                        : 0,
                                    category: "Bronze",
                                    rank: 3,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 29),
                Expanded(
                  child: listRank.length > 3
                      ? ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          itemCount: math.max(0, listRank.length - 3),
                          itemBuilder: (context, index) {
                            final actualIndex = index + 3;
                            return Padding(
                              padding: EdgeInsets.only(
                                top: index == 0 ? 10 : 8,
                                bottom: actualIndex == listRank.length - 1 ? 24 : 8,
                              ),
                              child: ListRank(
                                index: actualIndex + 1,
                                name: listRank[actualIndex].userName,
                                score: (double.tryParse(listRank[actualIndex].highestScore) ?? 0).toInt(),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'leaderboard_subtitle'.tr(),
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ),
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
