import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:toefl/models/games/game_history.dart';
import 'package:toefl/models/games/user_leaderboard.dart';
import 'package:toefl/models/profile.dart';
import 'package:toefl/pages/full_test/history_score.dart';
import 'package:toefl/remote/api/leader_board_api.dart';
import 'package:toefl/remote/api/mini_game_api.dart';
import 'package:toefl/remote/api/profile_api.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/custom_text_style.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:toefl/widgets/blue_container.dart';
import 'package:toefl/widgets/border_button.dart';
import 'package:toefl/widgets/common_app_bar.dart';

import 'package:toefl/widgets/profile_page/profile_name_section.dart';

import '../../routes/route_key.dart';
import '../../widgets/profile_page/progress_score_chart.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.isMe = true,
    this.userId = "",
  });

  final bool isMe;
  final String userId;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late List<GameHistory> gameHistory = [];
  Profile profile = Profile(
    id: 0,
    level: "",
    currentScore: 0,
    targetScore: 0,
    profileImage: "",
    nameUser: "",
    // emailUser: "",
  );

  final profileApi = ProfileApi();
  final miniGameApi = MiniGameApi();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    initProfile();
  }

  initProfile() async {
    setState(() {
      isLoading = true;
    });
    if (widget.isMe) {
      UserLeaderBoard rank = await LeaderBoardApi().getUserRank();
      final history = await miniGameApi.getHistoryGame();
      await profileApi.getProfile().then((value) async {
        setState(() {
          gameHistory = history;
          profile = value;
          isLoading = false;
        });
      });
    } else {
      UserLeaderBoard rank =
          await LeaderBoardApi().getUserRank(id: widget.userId);
      final history = await miniGameApi.getHistoryGame(id: widget.userId);

      await profileApi.getUserProfile(widget.userId).then((value) {
        setState(() {
          gameHistory = history;
          profile = value;
          isLoading = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: isLoading,
      child: Scaffold(
          appBar: CommonAppBar(
            title: 'appbar_profile'.tr(),
            withBack: widget.isMe ? false : true,
            actions: [
              widget.isMe
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, RouteKey.settingPage,
                              arguments: {
                                "name": profile.nameUser,
                                "image": profile.profileImage
                              }).then((val) {
                            initProfile();
                          });
                        },
                        child: BlueContainer(
                          width: 30,
                          padding: 4,
                          borderRadius: 10,
                          child: Icon(
                            Icons.settings,
                            color: HexColor(mariner800),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(),
            ],
          ),
          body: ListView(
            primary: false,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          children: <Widget>[
                            ProfileNameSection(
                                isLoading: isLoading, profile: profile),
                            const SizedBox(
                              height: 20,
                            ),
                            Skeleton.leaf(
                              child: ProgressScoreChart(
                                currentScore: _getCurrentScore(),
                                targetScore: profile.targetScore,
                                currentLevel: profile
                                    .level, // Menggunakan level dari API response
                              ),
                            ),
                          ],
                        ),
                      ),
                      // buildGameHistorySection(context)
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'history_score'.tr(),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: HexColor(neutral90)),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 5,
              ),
              const HistoryScore(),
              const SizedBox(
                height: 30,
              ),
            ],
          )),
    );
  }

  double _getCurrentScore() {
    // Parse current score safely
    if (profile.currentScore is String) {
      return double.tryParse(profile.currentScore.toString()) ?? 0;
    } else {
      return profile.currentScore.toDouble();
    }
  }

  Widget buildGameHistorySection(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const SizedBox(
            width: 24,
          ),
          ...List.generate(
            gameHistory.length,
            (index) => Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Skeleton.leaf(
                child: BlueContainer(
                  width: MediaQuery.of(context).size.width * 0.35,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BlueContainer(
                        color: mariner700,
                        width: 55,
                        height: 55,
                        padding: 10,
                        child: Center(
                            child: Text(
                          gameHistory[index]
                              .score!
                              .toStringAsFixed(0)
                              .toString(),
                          style: CustomTextStyle.extrabold20
                              .copyWith(color: Colors.black12),
                        )),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 2),
                        child: Text(
                          gameHistory[index].gameType.toString(),
                          style: CustomTextStyle.medium14.copyWith(
                              fontSize: 11, color: HexColor(neutral60)),
                        ),
                      ),
                      Text(
                        gameHistory[index].gameName.toString(),
                        style: CustomTextStyle.bold16.copyWith(
                          color: HexColor(neutral90),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(
            width: 24,
          ),
        ],
      ),
    );
  }
}
