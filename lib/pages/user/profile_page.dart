import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';
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
    // listenToNotification();
    initProfile();
    super.initState();
  }

  initProfile() async {
    setState(() {
      isLoading = true;
    });
    if (widget.isMe) {
      UserLeaderBoard rank = await LeaderBoardApi().getUserRank();
      final history = await miniGameApi.getHistoryGame();
      await profileApi.getProfile().then((value) async {
        // value.rank = rank.rank!;
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
        // value.rank = rank.rank!;
        setState(() {
          gameHistory = history;
          profile = value;
          isLoading = false;
        });
      });
    }
  }

  // listenToNotification() {
  //   print("Listening to notification");
  //   NotificationHelper.onClickNotification.stream.listen((event) {
  //     Navigator.push(
  //         context, MaterialPageRoute(builder: (context) => HomePage()));
  //   });
  // }

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
                            // <<<<<<< adam-notifikasi
                            //                   const Profile(),
                            //                   const SizedBox(
                            //                     height: 20,
                            //                   ),
                            //                   const LevelScore(),
                            //                   const SizedBox(
                            // =======
                            ProfileNameSection(
                                isLoading: isLoading, profile: profile),
                            const SizedBox(
                              height: 20,
                            ),
                            Skeleton.leaf(
                                child: buildProfileStatus(context, profile)),
                            Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16.0),
                                  child: Text("game_history".tr(),
                                      style: CustomTextStyle.bold16.copyWith(
                                        fontSize: 18,
                                      )),
                                ),
                                const Spacer(),
                              ],
                            ),

                            // ElevatedButton.icon(
                            //   onPressed: () {
                            //     LocalNotification.showSimpleNotification(
                            //         title: "Ayo belajar",
                            //         body: "Ini adalah notifikasi reminder",
                            //         payload: "This is simple data");
                            //   },
                            //   icon: const Icon(Icons.notifications_outlined),
                            //   label: const Text("Simple Notifikasi"),
                            // ),
                            // ElevatedButton.icon(
                            //   icon: const Icon(Icons.timer_outlined),
                            //   onPressed: () {
                            //     LocalNotification.showScheduleNotification(
                            //         title: "Ayo belajar toefl",
                            //         body: "Tingkatkan target toefl mu",
                            //         payload: "This is schedule data");
                            //   },
                            //   label: const Text("Reminder Notifikasi"),
                            // )
                          ],
                        ),
                      ),
                      buildGameHistorySection(context)
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
              SizedBox(
                height: 15,
              ),
              HistoryScore(),
              SizedBox(
                height: 30,
              ),
            ],
          )),
    );
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
                              .copyWith(color: Colors.white),
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

  Widget buildProfileStatus(BuildContext context, Profile profile) {
    bool showBanner = profile.targetScore == 0;

    return BlueContainer(
      padding: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ProfileStatusCard(
                  width: MediaQuery.of(context).size.width * 0.3 - 25,
                  title: "Level",
                  icon: Icons.star,
                  value: profile.level,
                  bannerText: "take_a_test".tr(),
                  hideBanner: !widget.isMe,
                ),
                ProfileStatusCard(
                  width: MediaQuery.of(context).size.width * 0.3 - 25,
                  title: "score".tr(),
                  bannerText: "target_needed".tr(),
                  icon: Icons.score,
                  onSetTap: () {
                    initProfile();
                  },
                  showSetTarget: showBanner && widget.isMe,
                  hideBanner: !showBanner || !widget.isMe,
                  value:
                      "${profile.currentScore}${profile.targetScore != 0 ? '/${profile.targetScore}' : ''}",
                ),
                // ProfileStatusCard(
                //     width: MediaQuery.of(context).size.width * 0.3 - 25,
                //     title: "Rank",
                //     hideBanner: true,
                //     icon: Icons.emoji_events,
                //     value: profile.rank <= 0
                //         ? "Unranked"
                //         : profile.rank.toString()),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            //   children: [
            //     GestureDetector(
            //       onTap: () async {
            //         if (widget.isMe) {
            //           Navigator.pushNamed(context, RouteKey.searchUser);
            //         } else {
            //           setState(() {
            //             isLoading = true;
            //           });
            //           await profileApi
            //               .changeFriendStatus(widget.userId)
            //               .then((value) {
            //             setState(() {
            //               this.profile =
            //                   profile.copyWith(isFriend: !profile.isFriend);
            //               isLoading = false;
            //             });
            //           });
            //         }
            //       },
            //       child: !profile.isFriend
            //           ? BlueContainer(
            //               width: MediaQuery.of(context).size.width *
            //                       (widget.isMe ? 0.55 : 0.7) -
            //                   25,
            //               color: mariner700,
            //               padding: 14,
            //               child: Center(
            //                 child: Text(
            //                   widget.isMe
            //                       ? "find_a_friend".tr()
            //                       : profile.isFriend
            //                           ? "remove_friend".tr()
            //                           : "add_friend".tr(),
            //                   style: CustomTextStyle.bold16.copyWith(
            //                     color: Colors.white,
            //                     fontWeight: FontWeight.w900,
            //                   ),
            //                 ),
            //               ),
            //             )
            //           : BorderButton(
            //               size: MediaQuery.of(context).size.width * 0.7 - 25,
            //               title: 'Remove Friend',
            //               padding: EdgeInsets.symmetric(vertical: 12),
            //               onTap: () async {
            //                 setState(() {
            //                   isLoading = true;
            //                 });
            //                 await profileApi
            //                     .changeFriendStatus(widget.userId)
            //                     .then((value) {
            //                   setState(() {
            //                     this.profile = profile.copyWith(
            //                         isFriend: !profile.isFriend);
            //                     isLoading = false;
            //                   });
            //                 });
            //               },
            //             ),
            //     ),
            //     widget.isMe
            //         ? GestureDetector(
            //             onTap: () {
            //               Navigator.pushNamed(context, RouteKey.searchUser,
            //                   arguments: {
            //                     "searchFriend": true,
            //                   });
            //             },
            //             child: BlueContainer(
            //               padding: 12,
            //               width: MediaQuery.of(context).size.width * 0.2 - 25,
            //               color: mariner700,
            //               child: const Icon(
            //                 Icons.group,
            //                 color: Colors.white,
            //               ),
            //             ),
            //           )
            //         : const SizedBox(),
            //     GestureDetector(
            //       onTap: () async {
            //         await Share.share(
            //             'check out my website https://example.com');
            //       },
            //       child: BlueContainer(
            //         padding: 12,
            //         width: MediaQuery.of(context).size.width * 0.2 - 25,
            //         color: mariner700,
            //         child: const Icon(
            //           Icons.share,
            //           color: Colors.white,
            //         ),
            //       ),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }
}

class ProfileStatusCard extends StatelessWidget {
  final double width;
  final bool hideBanner;
  final String bannerText;
  final String title;
  final String value;
  final bool showSetTarget;
  final IconData icon;
  final Function()? onSetTap;

  const ProfileStatusCard({
    super.key,
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
    this.bannerText = "",
    this.showSetTarget = false,
    this.hideBanner = false,
    this.onSetTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 152,
      child: Stack(
        children: [
          BlueContainer(
            color: neutral10,
            padding: 0,
            colorOpacity: hideBanner ? 0 : 1.0,
            width: width,
            borderRadius: 7,
            child: Transform.translate(
              offset: const Offset(0, -14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  bannerText,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CustomTextStyle.bold12.copyWith(
                    fontSize: 11,
                    color:
                        hideBanner ? Colors.transparent : HexColor(mariner900),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            child: BlueContainer(
              height: 115,
              color: mariner500,
              width: width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        icon,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(
                        width: 2,
                      ),
                      Text(
                        title,
                        style: CustomTextStyle.extrabold24.copyWith(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    value,
                    style: CustomTextStyle.bold16.copyWith(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  showSetTarget
                      ? GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, RouteKey.setTargetPage)
                                .then((val) {
                              if (onSetTap != null) {
                                onSetTap!();
                              }
                            });
                          },
                          child: Container(
                            width: 60,
                            decoration: BoxDecoration(
                              color: HexColor(mariner600),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Text(
                                "Set Target",
                                style: GoogleFonts.nunito(
                                    color: Colors.white, fontSize: 8),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
