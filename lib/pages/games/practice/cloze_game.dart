import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:toefl/widgets/games/game_app_bar.dart';
import 'package:toefl/widgets/blue_container.dart';

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
  bool? isCorrectAnswer;
  double score = 100;

  void checkAnswer(String answer) {
    final isCorrect = answer == questions[currentQuestionIndex]["correct"];
    setState(() {
      selectedAnswer = answer;
      isAnswered = true;
      isCorrectAnswer = isCorrect;
      if (!isCorrect) {
        score = (score - 30).clamp(0, 100);
      }
    });
  }

  void nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswer = null;
        isAnswered = false;
        isCorrectAnswer = null;
      });
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Game Over"),
          content: Text("Your final score: ${score.toInt()}"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  currentQuestionIndex = 0;
                  selectedAnswer = null;
                  isAnswered = false;
                  isCorrectAnswer = null;
                  score = 100;
                });
              },
              child: Text("Restart"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var question = questions[currentQuestionIndex];
    List<String> shuffledOptions = List<String>.from(question["options"]);

    return Scaffold(
      appBar: GameAppBar(title: 'Cloze Game'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              BlueContainer(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    question["sentence"].replaceAll("_____", "_________"),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: HexColor(mariner900),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                itemCount: shuffledOptions.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.8,
                ),
                itemBuilder: (context, index) {
                  String option = shuffledOptions[index];
                  bool isSelected = selectedAnswer == option;
                  bool isCorrect = option == question["correct"];
                  Color cardColor = Colors.white;

                  if (isAnswered) {
                    if (isSelected && !isCorrect) {
                      cardColor = Colors.red;
                    } else if (isCorrect) {
                      cardColor = Colors.green;
                    }
                  }

                  return Card(
                    color: cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: HexColor(mariner500), width: 2),
                    ),
                    elevation: 4,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: isAnswered ? null : () => checkAnswer(option),
                      child: Center(
                        child: Text(
                          option,
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 24),
              if (isAnswered)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HexColor(mariner500),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  ),
                  onPressed: nextQuestion,
                  child: Text(
                    currentQuestionIndex == questions.length - 1 ? 'Finish' : 'Next',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
