import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:toefl/pages/games/practice/scrambled_sentence.dart';
import 'package:toefl/pages/games/practice/hangman_game.dart';
import 'package:toefl/widgets/home_page/featured_card.dart';
import 'package:toefl/routes/route_key.dart';

class FeatureTest extends StatelessWidget {
  const FeatureTest({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint) {
      return Container(
          height: MediaQuery.of(context).size.height / 7,
          width: constraint.maxWidth / 1,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: ListView(
              scrollDirection: Axis.horizontal,
              // mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: EdgeInsets.only(right: 24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () =>
                        Navigator.of(context).pushNamed(RouteKey.speakingGame),
                    child: FeaturedCard(
                      isBgLight: true,
                      icon: "assets/images/vector_game_speaking.svg",
                      title: "speaking_game".tr(),
                      subtitle: "speaking_game_subtitle".tr(),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () =>
                        Navigator.of(context).pushNamed(RouteKey.hangmanGame),
                    child: FeaturedCard(
                      isBgLight: false,
                      icon: "assets/images/word_scramble.svg",
                      title: "hangman_game".tr(),
                      subtitle: "hangman_game_subtitle".tr(),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () =>
                        Navigator.of(context).pushNamed(RouteKey.clozeGame),
                    child: FeaturedCard(
                      isBgLight: true,
                      icon: "assets/images/word_scramble.svg",
                      title: "cloze_game".tr(),
                      subtitle: "cloze_game_subtitle".tr(),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () =>
                        Navigator.of(context).pushNamed(RouteKey.pairingGame),
                    child: FeaturedCard(
                      isBgLight: false,
                      icon: "assets/images/synonim_pairing.svg",
                      title: "synonym_pair".tr(),
                      subtitle: "synonim_pair_subtitle".tr(),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => SentenceScramblePage(),
                    )),
                    child: FeaturedCard(
                      isBgLight: true,
                      icon: "assets/images/vector_game_listening.svg",
                      title: "listening_game".tr(),
                      subtitle: "listening_game_subtitle".tr(),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () =>
                        Navigator.of(context).pushNamed(RouteKey.translateQuiz),
                    child: FeaturedCard(
                      isBgLight: false,
                      icon: "assets/images/Group39369.svg",
                      title: "translate_quiz".tr(),
                      subtitle: "translate_quiz_subtitle".tr(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.of(context)
                        .pushNamed(RouteKey.writingPractice),
                    child: FeaturedCard(
                      isBgLight: true,
                      icon: "assets/images/Group39370.svg",
                      title: "comment_practice".tr(),
                      subtitle: "comment_practice_subtitle".tr(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () =>
                        Navigator.of(context).pushNamed(RouteKey.coursePage),
                    child: FeaturedCard(
                      isBgLight: false,
                      icon: "assets/images/Group39370.svg",
                      title: "learning".tr(),
                      subtitle: "comment_practice_subtitle".tr(),
                    ),
                  ),
                ),
              ],
            ),
          ));
    });
  }
}
