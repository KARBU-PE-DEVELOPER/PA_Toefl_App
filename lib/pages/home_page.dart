import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:toefl/pages/full_test/history_score.dart';
import 'package:toefl/remote/api/profile_api.dart';
import 'package:toefl/remote/local/shared_pref/test_shared_preferences.dart';
import 'package:toefl/routes/route_key.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:toefl/widgets/home_page/estimated_score.dart';
import 'package:toefl/widgets/home_page/featured_test.dart';
import 'package:toefl/widgets/home_page/learning_path.dart';
import 'package:toefl/widgets/home_page/simulation_test.dart';
import 'package:toefl/widgets/home_page/topic_interest.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TestSharedPreference _testSharedPref = TestSharedPreference();
  String? userName;
  final profileApi = ProfileApi();
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _init();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await profileApi.getProfile();
      setState(() {
        userName = profile.nameUser; // Set the userName from profile
      });
    } catch (e) {
      print("Error loading user profile: $e");
    }
  }

  void _init() async {
    // final fullTestStatus = await _testSharedPref.getStatus();
    // if (fullTestStatus != null && mounted) {
    //   Navigator.of(context).pushNamed(RouteKey.openingLoadingTest, arguments: {
    //     "id": fullTestStatus.id,
    //     "isRetake": fullTestStatus.isRetake,
    //     "packetName": fullTestStatus.name
    //   });
    // }

    // final miniTestStatus = await _testSharedPref.getMiniStatus();
    // if (miniTestStatus != null && mounted) {
    //   Navigator.of(context).pushNamed(RouteKey.openingMiniTest, arguments: {
    //     "id": miniTestStatus.id,
    //     "isRetake": miniTestStatus.isRetake,
    //     "packetName": miniTestStatus.name
    //   });
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  

Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    "Hi, ",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF00394C),
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      userName != null ? "$userName!" : "",
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF00394C),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const Text(
                                "Welcome Back!",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  EstimatedScoreWidget(),
                ],
              ),
              SizedBox(
                height: 15,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'learning'.tr(),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: HexColor(neutral90)),
                    ),
                    Text(
                      'learning_subtitle'.tr(),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: HexColor(neutral50)),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 15,
              ),
              TopicInterest(),
              SizedBox(
                height: 15,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "game".tr(),
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: HexColor(neutral90)),
                    ),
                    Text(
                      "game_subtitle".tr(),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: HexColor(neutral50)),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 15,
              ),
              FeatureTest(),
              SizedBox(
                height: 15,
              ),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'simulation_test'.tr(),
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: HexColor(neutral90)),
                      ),
                      Text(
                        "try_simulation_test".tr(),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: HexColor(neutral50)),
                      ),
                    ],
                  )),
              SizedBox(
                height: 15,
              ),
              SimulationTestWidget(),
              SizedBox(
                height: 15,
              ),
            ],
          ),
        )));
  }
}
