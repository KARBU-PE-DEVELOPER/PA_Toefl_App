import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:toefl/remote/api/games/scramble_api.dart';
import 'package:toefl/routes/route_key.dart';
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
  int attempts = 0;
  int maxAttempts = 0;
  int timeLeft = 60;
  bool isLoading = true;
  bool isGameFinished = false;
  late Timer _timer;

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
      attempts = 0;
      isGameFinished = false;
      timeLeft = 100;
    });

    final api = ScrambleGameApi();
    final data = await api.fetchScrambleWord();

    if (data != null) {
      word = data.answer.toUpperCase();
      clue = data.clue;
    } else {
      word = "DEFAULT";
      clue = "Fallback clue.";
    }

    maxAttempts = word.length * 2;

    setState(() {
      currentAnswer = List.filled(word.length, null);
      letterOptions = _generateLetterOptions(word);
      isLoading = false;
    });

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft <= 0 || isGameFinished) {
        _timer.cancel();
        _showResultModal();
      } else {
        setState(() {
          timeLeft--;
        });
      }
    });
  }

  List<String> _generateLetterOptions(String word) {
    List<String> letters = word.split('');
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final rand = Random();

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
  if (isGameFinished || currentIndex >= word.length) return;

  setState(() {
    if (word[currentIndex] == letter) {
      currentAnswer[currentIndex] = letter;
      currentIndex++;
      letterOptions.remove(letter); // Hapus huruf dari opsi setelah benar
    } else {
      attempts++; // Tambah attempt hanya saat salah
    }

    if (currentIndex >= word.length || attempts >= maxAttempts) {
      isGameFinished = true;
      _timer.cancel();
      _showResultModal();
    }
  });
}


  int _calculateScore() {
    const int maxScore = 100;
    int timeScore = ((timeLeft / 100) * 70).round();
    int attemptScore = (((maxAttempts - attempts).clamp(0, maxAttempts) / maxAttempts) * 30).round();
    return (timeScore + attemptScore).clamp(0, maxScore);
  }

Future<void> _submitScore(int score) async {
    try {
      await ScrambleGameApi().submitScrambleResult(score.toDouble());
    } catch (e) {
      debugPrint("Submit score failed: $e");
    }
  }
  
  void _showResultModal() {
  final isWin = !currentAnswer.contains(null);
  final score = _calculateScore();

  // Submit skor sebelum menampilkan dialog
  _submitScore(score);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isWin ? 'congratulations'.tr() : 'game_over'.tr(),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('the_correct_word_was'.tr()),
          const SizedBox(height: 4),
          Text(word,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.red)),
          const SizedBox(height: 12),
          Text("Score: $score",
              style: const TextStyle(fontSize: 20, color: Colors.green)),
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
    ),
  );
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
  void dispose() {
    _timer.cancel();
    super.dispose();
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
                    Text(
                      "Time Left: $timeLeft",
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Attempts: $attempts / $maxAttempts",
                      style: const TextStyle(fontSize: 16),
                    ),
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
                  ],
                ),
              ),
            ),
    );
  }
}
