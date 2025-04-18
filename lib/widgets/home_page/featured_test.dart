import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:toefl/pages/games/practice/cloze_game.dart';
import 'package:toefl/pages/games/practice/pairing_game.dart';
import 'package:toefl/pages/games/practice/scrambled_sentence.dart';
import 'package:toefl/pages/grammar-translator/grammarTranslator_page.dart';
import 'package:toefl/pages/grammar-commentator/grammarCommentator_page.dart';
import 'package:toefl/pages/games/practice/scrambled_word.dart';
import 'package:toefl/pages/games/practice/speaking_game.dart';
import 'package:toefl/widgets/home_page/featured_card.dart';
import 'package:toefl/widgets/home_page/try_card.dart';

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
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => SpeakingGame(),
                    )),
                    child: FeaturedCard(
                      isBgLight: true,
                      icon: "assets/images/vector_game_speaking.svg",
                      title: "Speaking Game",
                      subtitle: "Challange your speaking",
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ClozeGamePage(),
                    )),
                    child: FeaturedCard(
                      isBgLight: false,
                      icon: "assets/images/word_scramble.svg",
                      title: "Cloze Game",
                      subtitle: "Fill The Blank",
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => PairingGame(),
                    )),
                    child: FeaturedCard(
                      isBgLight: true,
                      icon: "assets/images/synonim_pairing.svg",
                      title: "Synonim Pairing",
                      subtitle: "A game that contains synonymous words",
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
                      isBgLight: false,
                      icon: "assets/images/vector_game_listening.svg",
                      title: "Listening Game",
                      subtitle: "Can you hear what i said?",
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(right: 24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => GrammarTranslatorPage(),
                    )),
                    child: FeaturedCard(
                      isBgLight: true,
                      icon: "assets/images/Group39369.svg",
                      title: "Grammar Translator",
                      subtitle: "Let's practice your grammar skill !!!",
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const GrammarCommentatorPage(),
                    )),
                    child: FeaturedCard(
                      isBgLight: false,
                      icon: "assets/images/Group39370.svg",
                      title: "Grammar Commentator",
                      subtitle: "Let's practice your grammar skill !!!",
                    ),
                  ),
                )
              ],
            ),
          ));
    });
  }
}
