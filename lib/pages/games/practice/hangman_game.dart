import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toefl/models/games/hangman_game.dart';
import 'package:toefl/remote/api/games/hangman_api.dart';
import 'package:toefl/routes/route_key.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:toefl/widgets/games/game_app_bar.dart';

class HangmanGame extends StatefulWidget {
  const HangmanGame({super.key});

  @override
  State<HangmanGame> createState() => _HangmanGameState();
}

class _HangmanGameState extends State<HangmanGame> {
  String word = "";
  String clue = "";
  Set<String> guessedLetters = {};
  int attemptsLeft = 6;
  bool isLoading = true;
  late Timer _timer;
  int timeLeft = 60; // 60 detik
  bool isGameFinished = false;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  Future<void> _startNewGame() async {
    setState(() {
      isLoading = true;
      guessedLetters.clear();
      attemptsLeft = 6;
      timeLeft = 60;
      isGameFinished = false;
    });

    final api = HangmanGameApi();
    final data = await api.fetchHangmanWord();

    if (data != null) {
      setState(() {
        word = data.answer.toUpperCase();
        clue = data.clue;
        isLoading = false;
      });
    } else {
      setState(() {
        word = "ROBOT";
        clue = "A machine that can move";
        isLoading = false;
      });
    }

    _revealRandomLetter();
    _startTimer();
  }

  void _revealRandomLetter() {
    final letters = word.split('').toSet().difference(guessedLetters);
    if (letters.isNotEmpty) {
      final randomLetter = letters.elementAt(Random().nextInt(letters.length));
      guessedLetters.add(randomLetter);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft <= 0 || isGameFinished) {
        _timer.cancel();
        if (!isGameFinished) _showResultModal(); // Waktu habis
      } else {
        setState(() {
          timeLeft--;
        });
      }
    });
  }

  void _onLetterTap(String letter) {
    if (guessedLetters.contains(letter)) return;

    setState(() {
      guessedLetters.add(letter);
      if (!word.contains(letter)) {
        attemptsLeft -= 1;
      }
    });

    if (_isGameOver()) {
      _timer.cancel();
      _showResultModal();
    }
  }

  bool _isGameOver() {
    return attemptsLeft <= 0 || _isWordGuessed();
  }

  bool _isWordGuessed() {
    return word.split('').every((letter) => guessedLetters.contains(letter));
  }

  int _calculateScore() {
  const int maxScore = 100;
  const int maxTime = 60;
  const int maxAttempts = 6;

  double timeScore = (timeLeft / maxTime) * 70;     
  double attemptScore = (attemptsLeft / maxAttempts) * 30; 

  return (timeScore + attemptScore).round().clamp(0, maxScore);
}


  Future<void> _submitScore(int score) async {
    try {
      await HangmanGameApi().submitHangmanResult(score.toDouble());
    } catch (e) {
      debugPrint("Submit score failed: $e");
    }
  }

  void _showResultModal() {
    isGameFinished = true;
    final isWin = _isWordGuessed();
    final score = _calculateScore();
    _submitScore(score);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isWin ? 'congratulations'.tr() : 'game_over'.tr(),
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isWin) ...[
                Text('the_correct_word_was'.tr(),
                    style: GoogleFonts.nunito(fontSize: 18),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(word,
                    style: GoogleFonts.nunito(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),
              ],
              Text("${'score'.tr()}: $score",
                  style: GoogleFonts.nunito(
                      fontSize: 22, color: Colors.green, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startNewGame();
                },
                child: Text('restart'.tr()),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    RouteKey.main,
                    (route) => false,
                  );
                },
                child: Text('quit'.tr()),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _displayWord() {
    return word
        .split('')
        .map((letter) => guessedLetters.contains(letter) ? letter : '_')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GameAppBar(title: 'hangman_game'.tr()),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(HexColor(mariner700)),
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              Text(
  'Time Left: $timeLeft',
  style: GoogleFonts.nunito(
    fontSize: 20,
    color: Colors.redAccent,
    fontWeight: FontWeight.bold,
  ),
),
                const SizedBox(height: 10),
                SvgPicture.asset('assets/images/robot_hangman.svg', height: 150),
                Text(_displayWord(),
                    style: GoogleFonts.nunito(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: HexColor(mariner700))),
                Padding(
                  padding: const EdgeInsets.all(19.0),
                  child: Text(
                    'Clue: $clue',
                    style: GoogleFonts.nunito(fontSize: 18, color: HexColor(mariner400)),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'attempts_left'.tr(args: [attemptsLeft.toString()]),
                    style: GoogleFonts.nunito(fontSize: 20, color: HexColor(mariner500)),
                  ),
                ),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('').map((letter) {
                      return GestureDetector(
                        onTap: guessedLetters.contains(letter)
                            ? null
                            : () => _onLetterTap(letter),
                        child: CircleAvatar(
                          backgroundColor: guessedLetters.contains(letter)
                              ? Colors.grey
                              : HexColor(mariner100),
                          child: Text(letter,
                              style: GoogleFonts.nunito(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: HexColor(mariner700))),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }
}