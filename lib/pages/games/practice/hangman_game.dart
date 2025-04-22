import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toefl/models/games/hangman_game.dart';
import 'package:toefl/remote/api/games/hangman_api.dart';
import 'package:toefl/routes/route_key.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:toefl/widgets/quiz/modal/modal_confirmation.dart';
import '../../../widgets/games/game_app_bar.dart';

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
    });

    final api = HangmanGameApi(); // Your custom API wrapper
    final data = await api.fetchHangmanWord(); // Fetch from backend

    if (data != null) {
      setState(() {
        word = data.answer.toUpperCase();
        clue = data.clue;
        isLoading = false;
      });
      _revealRandomLetter();
    } else {
      // fallback
      setState(() {
        word = "ROBOT";
        clue = "A machine that can move";
        isLoading = false;
      });
      _revealRandomLetter();
    }
  }

  void _revealRandomLetter() {
    final letters = word.split('').toSet().difference(guessedLetters);
    if (letters.isNotEmpty) {
      final randomLetter = letters.elementAt(Random().nextInt(letters.length));
      guessedLetters.add(randomLetter);
    }
  }

  void _onLetterTap(String letter) {
    setState(() {
      guessedLetters.add(letter);
      if (!word.contains(letter)) {
        attemptsLeft -= 1;
      }
    });

    if (_isGameOver()) {
      _showGameOverModal();
    }
  }

  bool _isGameOver() {
    return attemptsLeft <= 0 || _isWordGuessed();
  }

  bool _isWordGuessed() {
    return word.split('').every((letter) => guessedLetters.contains(letter));
  }

  void _showGameOverModal() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return ModalConfirmation(
          message: _isWordGuessed() ? "You Won!" : "Game Over",
          leftTitle: "Quit",
          rightTitle: "Retry",
          rightFunction: () {
            Navigator.pop(context);
            _startNewGame();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GameAppBar(title: 'Hangman'),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/images/robot_hangman.svg',
                  height: 150,
                ),
                Text(
                  _displayWord(),
                  style: GoogleFonts.nunito(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: HexColor(mariner700),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(19.0),
                  child: Text(
                    'Clue: $clue',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      color: HexColor(mariner400),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Attempts Left: $attemptsLeft',
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      color: HexColor(mariner500),
                    ),
                  ),
                ),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('').map((letter) {
                      return GestureDetector(
                        onTap: guessedLetters.contains(letter) ? null : () => _onLetterTap(letter),
                        child: CircleAvatar(
                          backgroundColor: guessedLetters.contains(letter)
                              ? Colors.grey
                              : HexColor(mariner100),
                          child: Text(
                            letter,
                            style: GoogleFonts.nunito(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: HexColor(mariner700),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }

  String _displayWord() {
    return word.split('').map((letter) => guessedLetters.contains(letter) ? letter : '_').join(' ');
  }
}
