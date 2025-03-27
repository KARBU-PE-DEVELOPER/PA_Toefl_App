import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toefl/models/games/pairing_game.dart';
import 'package:toefl/remote/api/mini_game_api.dart';
import 'package:toefl/remote/api/games/synonympair_api.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:toefl/widgets/games/game_app_bar.dart';
import 'package:toefl/widgets/quiz/modal/modal_confirmation.dart';
import 'package:toefl/routes/route_key.dart';

class PairingGame extends StatefulWidget {
  const PairingGame({super.key});

  @override
  State<PairingGame> createState() => _PairingGameState();
}

class _PairingGameState extends State<PairingGame> {
  List<SynonymPair> words = [];
  List<String> shuffledWords = [];
  List<int> selectedIndices = [];
  List<int> matchedIndices = [];
  int totalAttempts = 0;
  int wrongAttempts = 0;
  double score = 100.0; 

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    words = [];
    shuffledWords = [];
    selectedIndices = [];
    matchedIndices = [];
    totalAttempts = 0;
    wrongAttempts = 0;
    score = 100.0;

    try {
      words = await PairingGameApi().fetchSynonyms();
      _prepareGame();
    } catch (e) {
      print("Error loading words: $e");
    }
  }

  void _prepareGame() {
    shuffledWords = [];
    for (var pair in words) {
      shuffledWords.add(pair.word);
      shuffledWords.add(pair.synonym);
    }
    shuffledWords.shuffle();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GameAppBar(title: 'Synonym Pairing'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        SvgPicture.asset(
                            'assets/images/score_board.svg'),
                        Positioned(
                          bottom: 30,
                            child: AnimatedSwitcher(
                              duration: Duration(milliseconds: 500),
                              transitionBuilder: (Widget child, Animation<double> animation) {
                                return ScaleTransition(scale: animation, child: child);
                              },                     
                              child: Text(
                              '${score.toInt()}',
                              key: ValueKey<int>(score.toInt()),
                              style: GoogleFonts.pressStart2p(
                              fontSize: 50,
                              color: Color(0xFF0C42A7),
                              fontWeight: FontWeight.w100,
                            ),
                            ),
                            ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
              Expanded(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                  ),
                  itemCount: shuffledWords.length,
                  itemBuilder: (context, index) {
                    bool isSelected = selectedIndices.contains(index);
                    bool isMatched = matchedIndices.contains(index);

                    return GestureDetector(
                      onTap: () => _onCardTap(index),
                      child: Card(
                        color: isMatched
                            ? HexColor(mariner500)
                            : (isSelected
                                ? HexColor(mariner100)
                                : Colors.white),
                        child: Center(
                          child: Text(
                            shuffledWords[index],
                            style: GoogleFonts.nunito(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: isMatched
                                  ? HexColor(neutral10)
                                  : (isSelected
                                      ? HexColor(mariner700)
                                      : HexColor(mariner500)),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onCardTap(int index) {
    if (matchedIndices.contains(index) || selectedIndices.contains(index)) {
      return;
    }

     setState(() {
      selectedIndices.add(index);
      if (selectedIndices.length == 2) {
        totalAttempts++; 
        _checkMatch();
      } else if (selectedIndices.length > 2) {
        selectedIndices.removeAt(0);
      }
    });
  }

  void _checkMatch() async {
  int firstIndex = selectedIndices[0];
  int secondIndex = selectedIndices[1];

  String firstWord = shuffledWords[firstIndex];
  String secondWord = shuffledWords[secondIndex];

  bool isMatch = words.any((pair) =>
      (pair.word == firstWord && pair.synonym == secondWord) ||
      (pair.word == secondWord && pair.synonym == firstWord));

  if (isMatch) {
    setState(() {
      matchedIndices.addAll(selectedIndices);
    });
  } else {
    wrongAttempts++; 
  }

  _calculateScore();

  if (matchedIndices.length == shuffledWords.length) {
    await PairingGameApi().submitPairingGameResult(score);
    showModalEnd();
  }

  Future.delayed(const Duration(seconds: 1), () {
    setState(() {
      selectedIndices.clear();
    });
  });
}

 void _calculateScore() {
  int totalPairs = words.length; 

  score = (100 - ((wrongAttempts / (totalPairs * 2)) * 100)).clamp(0, 100);

  setState(() {});
}



  void showModalEnd() async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return ModalConfirmation(
          message: "Final Score: ${score.toInt()}",
          leftTitle: "Quit",
          rightTitle: "Retry",
          rightFunction: () {
            _loadWords();
            Navigator.pop(context);
          },
          leftFunction: () => Navigator.pushNamedAndRemoveUntil(
            context,
            RouteKey.main,
            (route) => false,
          ),
        );
      },
    );
  }
}
