import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toefl/models/games/cloze_game.dart';
import 'package:toefl/remote/api/games/cloze_api.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:toefl/widgets/blue_container.dart';
import 'package:toefl/widgets/quiz/modal/modal_confirmation.dart';
import 'package:toefl/widgets/games/game_app_bar.dart';
import 'package:easy_localization/easy_localization.dart';

class ClozeGamePage extends StatefulWidget {
  const ClozeGamePage({super.key});

  @override
  State<ClozeGamePage> createState() => _ClozeGamePageState();
}

class _ClozeGamePageState extends State<ClozeGamePage> {
  List<ClozeQuestion> questions = [];
  int currentQuestionIndex = 0;
  String? selectedAnswer;
  bool isAnswered = false;
  bool? isCorrectAnswer;
  double score = 100;
  bool isLoading = true;

  final api = ClozeGameApi();

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    setState(() {
      isLoading = true;
    });
    final response = await api.fetchClozeQuestions();
    setState(() {
      questions = response;
      isLoading = false;
    });
  }

  void checkAnswer(String answer) {
    final isCorrect = answer == questions[currentQuestionIndex].keyAnswer;
    setState(() {
      selectedAnswer = answer;
      isAnswered = true;
      isCorrectAnswer = isCorrect;
      if (!isCorrect) score = (score - 30).clamp(0, 100);
    });
  }

  void restartGame() {
    Navigator.pop(context); // Tutup modal sebelum restart
    loadQuestions();
    setState(() {
      currentQuestionIndex = 0;
      selectedAnswer = null;
      isAnswered = false;
      isCorrectAnswer = null;
      score = 100;
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
        builder: (context) => ModalConfirmation(
          message: 'Your final score: ${score.toInt()}',
          leftTitle: 'restart'.tr(),
          rightTitle: 'quit'.tr(),
          leftFunction: restartGame,
          rightFunction: () {
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
      );
      api.submitClozeResult(score);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(HexColor(mariner700)),
          ),
        ),
      );
    }

    final question = questions[currentQuestionIndex];
    final options = question.answers;

    return Scaffold(
      appBar: GameAppBar(title: 'cloze_game'.tr()),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BlueContainer(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    question.question.replaceAll("_____", "_________"),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: HexColor(mariner900),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.8,
                ),
                itemBuilder: (context, index) {
                  final option = options[index];
                  final isSelected = selectedAnswer == option;
                  final isCorrect = option == question.keyAnswer;
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
              const SizedBox(height: 24),
              if (isAnswered)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HexColor(mariner500),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 12),
                  ),
                  onPressed: nextQuestion,
                  child: Text(
                    currentQuestionIndex == questions.length - 1
                        ? 'finish'.tr()
                        : 'next'.tr(),
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
