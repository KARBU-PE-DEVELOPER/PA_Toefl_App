import 'package:toefl/widgets/blue_container.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toefl/models/games/game_tense.dart';
import 'package:toefl/remote/api/mini_game_api.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:toefl/widgets/answer_validation_container.dart';
import 'package:toefl/widgets/blue_button.dart';
import 'package:collection/collection.dart';
import '../../../widgets/games/game_app_bar.dart';

class ClozeGamePage extends StatefulWidget {
  const ClozeGamePage({super.key});

  @override
  _ClozeGameScreenState createState() => _ClozeGameScreenState();
}

class _ClozeGameScreenState extends State<ClozeGamePage> {
  final List<Map<String, dynamic>> questions = [
    {
      "sentence": "She _____ to school every morning.",
      "correct": "goes",
      "options": ["go", "going", "goes", "gone"]
    },
    {
      "sentence": "They _____ football every weekend.",
      "correct": "play",
      "options": ["playing", "plays", "play", "played"]
    },
    {
      "sentence": "I _____ a book last night.",
      "correct": "read",
      "options": ["read", "reads", "reading", "wrote"]
    }
  ];

  int currentQuestionIndex = 0;
  String? selectedAnswer;
  bool isAnswered = false;

  void checkAnswer(String answer) {
    setState(() {
      selectedAnswer = answer;
      isAnswered = true;
    });
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        if (currentQuestionIndex < questions.length - 1) {
          currentQuestionIndex++;
          selectedAnswer = null;
          isAnswered = false;
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Game Over"),
              content: Text("You've completed all questions!"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      currentQuestionIndex = 0;
                      selectedAnswer = null;
                      isAnswered = false;
                    });
                  },
                  child: Text("Restart"),
                ),
              ],
            ),
          );
        }
      });
    });
  }



    @override
  Widget build(BuildContext context) {
    var question = questions[currentQuestionIndex];
    List<String> shuffledOptions = List<String>.from(question["options"]);
    shuffledOptions.shuffle(Random());
    return Scaffold(
      appBar: GameAppBar(
        title: 'Scrambled Word',
      ),
      body: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            BlueContainer(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  question["sentence"].replaceAll("_____", "____?____"),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: HexColor(mariner900)),
                ),
              ),
            ),
            SizedBox(height: 15),
            Text(
              'Fill the blanks using suitable words!',
              style: GoogleFonts.nunito(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
              ),
              itemCount: shuffledOptions.length,
              itemBuilder: (context, index) {
                String option = shuffledOptions[index];
                bool isCorrect = option == question["correct"];
                bool isSelected = selectedAnswer == option;

                return GestureDetector(
                  onTap: isAnswered ? null : () => checkAnswer(option),
                  child: Card(
                    color: isSelected
                        ? (isCorrect ? Colors.green : Colors.red)
                        : Colors.white,
                    child: Center(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
