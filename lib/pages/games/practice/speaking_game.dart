import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:toefl/models/games/speak_game.dart';
import 'package:toefl/remote/api/games/speakgame_api.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:toefl/widgets/answer_validation_container.dart';
import 'package:toefl/widgets/blue_button.dart';
import '../../../widgets/games/game_app_bar.dart';

class SpeakingGame extends ConsumerStatefulWidget {
  const SpeakingGame({super.key});

  @override
  ConsumerState<SpeakingGame> createState() => _SpeakingGameState();
}

class _SpeakingGameState extends ConsumerState<SpeakingGame> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _userAnswer = '';
  String _answerKey = "";
  bool _isCheck = false;
  bool _isCorrect = false;
  bool _disable = true;
  double accuracy = 0;

  @override
  void initState() {
    super.initState();
    _loadWords();
    _initSpeech();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _userAnswer = result.recognizedWords;
      if (result.recognizedWords.isNotEmpty) {
        _disable = false;
      }
    });
  }

  void _loadWords() async {
    try {
      List<SpeakGame> words = await SpeakGameApi().getWord();
      debugPrint("$words");
      setState(() {
        _answerKey = '';
      });
    } catch (e) {
      print("Error loading words: $e");
    }
  }

  void _checkAnswer() {
    var similarity = _answerKey
        .replaceAll(".", "")
        .replaceAll(",", "")
        .toLowerCase()
        .similarityTo(_userAnswer);
    setState(() {
      accuracy = similarity;
      _isCorrect = similarity > 0.8;
      _isCheck = true;
    });
  }

  void _nextWord() {
    if (_isCheck) {
      setState(() {
        _userAnswer = '';
        _answerKey = '';
        _isCheck = false;
        _isCorrect = false;
        _disable = true;
      });
      _loadWords();
    } else if (_userAnswer.isNotEmpty) {
      _checkAnswer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GameAppBar(title: 'Pronounciation'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _answerKey,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
            ),
            SizedBox(height: 16),
            GestureDetector(
              onTap: _speechToText.isNotListening
                  ? _startListening
                  : _stopListening,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mic, color: Colors.blue[900]),
                    SizedBox(width: 8),
                    Text(
                      "KETUK UNTUK BICARA",
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Spacer(),
            if (_isCheck)
              AnswerValidationContainer(
                isCorrect: _isCorrect,
                keyAnswer: _answerKey,
                explanation: '${(accuracy * 10).toStringAsFixed(1)} / 10',
              ),
            Text(
              "TEKAN UNTUK BERBICARA",
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            BlueButton(
              isDisabled: _disable,
              title: _isCheck ? 'Next Word' : 'Periksa',
              onTap: _nextWord,
            ),
          ],
        ),
      ),
    );
  }
}
