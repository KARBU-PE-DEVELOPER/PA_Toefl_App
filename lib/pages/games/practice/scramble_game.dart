import 'dart:math';
import 'package:flutter/material.dart';
import 'package:toefl/remote/api/games/scramble_api.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../widgets/games/game_app_bar.dart';

class ScrambleGame extends StatefulWidget {
  const ScrambleGame({super.key});

  @override
  _ScrambleGameState createState() => _ScrambleGameState();
}

class _ScrambleGameState extends State<ScrambleGame> {
  String word = '';
  String clue = '';
  List<String?> currentAnswer = [];
  List<String> letterOptions = [];
  int currentIndex = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  Future<void> _startNewGame() async {
    setState(() {
      isLoading = true;
      currentAnswer = [];
      currentIndex = 0;
    });

    final api = ScrambleGameApi();
    final data = await api.fetchScrambleWord(); // must include `clue`

    if (data != null) {
      setState(() {
        word = data.answer.toUpperCase();
        clue = data.clue;
        currentAnswer = List.filled(word.length, null);
        letterOptions = _generateLetterOptions(word);
        isLoading = false;
      });
    } else {
      setState(() {
        word = "DEFAULT";
        clue = "Fallback clue.";
        currentAnswer = List.filled(word.length, null);
        letterOptions = _generateLetterOptions(word);
        isLoading = false;
      });
    }
  }

  List<String> _generateLetterOptions(String word) {
    List<String> letters = word.split('');
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final rand = Random();

    // Tambahkan 3-5 huruf acak yang tidak ada di kata
    int extraCount = 3 + rand.nextInt(3);
    while (extraCount > 0) {
      String randomChar = alphabet[rand.nextInt(alphabet.length)];
      if (!letters.contains(randomChar)) {
        letters.add(randomChar);
        extraCount--;
      }
    }

    letters.shuffle();
    return letters;
  }

  void _selectLetter(String letter) {
    if (currentIndex < word.length && word[currentIndex] == letter) {
      setState(() {
        currentAnswer[currentIndex] = letter;
        currentIndex++;
      });
    }
  }

  Widget _buildLetterBox(String? letter) {
    return Container(
      width: 40,
      height: 40,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(8),
        color: letter != null ? Colors.blue : Colors.transparent,
      ),
      child: Center(
        child: Text(
          letter ?? '',
          style: const TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildLetterButton(String letter) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          minimumSize: const Size(48, 48),
        ),
        onPressed: () => _selectLetter(letter),
        child: Text(letter, style: const TextStyle(fontSize: 18)),
      ),
    );
  }

  Widget _buildClue() {
    return Text(
      "Clue: $clue",
      style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildHowToPlay() {
    return const Text(
      "How to Play:\nTap the correct letters in order to form the word based on the clue.\nWrong order will be ignored!",
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GameAppBar(title: 'scramble_game'.tr()),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(HexColor(mariner700)),
            ))
          : SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    _buildHowToPlay(),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: currentAnswer.map(_buildLetterBox).toList(),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: letterOptions.map(_buildLetterButton).toList(),
                    ),
                    const SizedBox(height: 24),
                    _buildClue(),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: currentAnswer.contains(null)
                          ? null
                          : () {
                              // Do something on finish
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade300,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text("Finish"),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
