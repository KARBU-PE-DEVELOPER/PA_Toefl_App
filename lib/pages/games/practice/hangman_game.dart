import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toefl/remote/api/mini_game_api.dart';
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
  String word = "FLUTTER";
  Set<String> guessedLetters = {};
  int attemptsLeft = 6;

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  void _startNewGame() {
    setState(() {
      word = "ROBOT";
      guessedLetters.clear();
      attemptsLeft = 6;
    });
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
            _startNewGame();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GameAppBar(title: 'Hangman'),
      body: Column(
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
              'Attempts Left: $attemptsLeft',
              style: GoogleFonts.nunito(
                fontSize: 20,
                color: HexColor(mariner500),
              ),
            ),
          ),
          Wrap(
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
        ],
      ),
    );
  }

  String _displayWord() {
    return word.split('').map((letter) => guessedLetters.contains(letter) ? letter : '_').join(' ');
  }
}
