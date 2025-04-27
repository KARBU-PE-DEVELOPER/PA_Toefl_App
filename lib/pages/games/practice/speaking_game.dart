import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:toefl/models/games/speak_game.dart';
import 'package:toefl/remote/api/games/speakgame_api.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:toefl/remote/local/shared_pref/auth_shared_preferences.dart';

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
  List<double> _scores = [];
  bool _speechEnabled = false;
  String _userAnswer = '';
  String _answerKey = "";
  bool _isCheck = false;
  bool _isCorrect = false;
  bool _disable = true;
  double accuracy = 0;

  List<String> _sentences = [];
  int _currentSentenceIndex = 0;

  @override
  void initState() {
    super.initState();

    _loadSentences();

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
      _disable = result.recognizedWords.isEmpty;
    });
  }

  void _loadSentences() async {
    try {
      final game = await SpeakGameApi(dio: Dio()).getWord();
      setState(() {
        _sentences = game.sentence;
        if (_sentences.isNotEmpty) {
          _answerKey = _sentences.first;
        }
      });
    } catch (e) {
      print('error_loading_sentences'.tr(args: [e.toString()]));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("failed_load_questions".tr())),
      );
    }
  }

  void _checkAnswer() {
    final cleanedAnswer =
        _answerKey.replaceAll(RegExp(r'[.,]'), '').toLowerCase();
    final cleanedUserAnswer =
        _userAnswer.replaceAll(RegExp(r'[.,]'), '').toLowerCase();

    final similarity = cleanedAnswer.similarityTo(cleanedUserAnswer);

    setState(() {
      accuracy = similarity;
      _isCorrect = similarity > 0.7; // Threshold tetap 70%
      _isCheck = true;

      // Skor skala 100
      if (_scores.length == _currentSentenceIndex) {
        _scores.add(similarity * 100);
      }
    });
  }

  double _calculateTotalScore() {
    return _scores.fold(0, (sum, item) => sum + item);
  }

  Future<double> _storeScore() async {
    double totalScore = _calculateTotalScore();
    double averageScore = totalScore / _sentences.length; // karena 3 soal

    try {
      await SpeakGameApi(dio: Dio())
          .store(averageScore); // Kirim nilai rata-rata
    } catch (e) {
      print("Error storing score: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("failed_save_score".tr())),
      );
    }

    return averageScore;
  }

  double _calculateAverageScore() {
    if (_scores.isEmpty) return 0;
    return _calculateTotalScore() / _scores.length;
  }

  void _nextSentence() async {
    if (_isCheck && _currentSentenceIndex < _sentences.length - 1) {
      setState(() {
        _currentSentenceIndex++;
        _answerKey = _sentences[_currentSentenceIndex];
        _resetState();
      });
    } else if (_isCheck) {
      final averageScore = await _storeScore();
      _showCompletionDialog(averageScore); // Show dialog pakai skor rata-rata
    } else {
      _checkAnswer();
    }
  }

  void _resetState() {
    _userAnswer = '';
    _isCheck = false;
    _isCorrect = false;
    _disable = true;
  }

  void restartGame() {
    Navigator.pop(context); // Tutup dialog

    setState(() {
      _scores.clear();
      _userAnswer = '';
      _answerKey = '';
      _isCheck = false;
      _isCorrect = false;
      _disable = true;
      _currentSentenceIndex = 0;
    });

    _loadSentences(); // Fetch ulang soal
  }

  void _showCompletionDialog(double averageScore) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('congratulations'.tr()),
        content: Text(
          '${'completed_all_questions'.tr()}\n\n'
          '${'average_score'.tr()}: ${averageScore.toStringAsFixed(1)} / 100',
        ),
        actions: [
          TextButton(
            onPressed: restartGame,
            child: Text("restart".tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: Text("quit".tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GameAppBar(title: 'speaking_game'.tr()),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Progress Indicator
            Text(
              "${'question'.tr()} ${_currentSentenceIndex + 1} ${'of'.tr()} ${_sentences.length}",
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // Answer Key Container
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFD8E9FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _answerKey,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF387EFF),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: _speechToText.isNotListening
                    ? _startListening
                    : _stopListening,
                child: Container(
                  width: 302,
                  height: 99,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8E9FF),
                    borderRadius: BorderRadius.circular(7.5),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x3F000000),
                        blurRadius: 4,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _speechToText.isListening ? Icons.mic_off : Icons.mic,
                        size: 36,
                        color: const Color(0xFF387EFF),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _speechToText.isListening
                            ? 'mic_on'.tr()
                            : 'mic_off'.tr(),
                        style: const TextStyle(
                          color: Color(0xFF387EFF),
                          fontSize: 20,
                          fontFamily: 'Baloo Bhaijaan',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // User Answer Display
            const SizedBox(height: 16),
            if (_userAnswer.isNotEmpty)
              Center(
                child: Container(
                  width: 302,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8E9FF),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x3F888888),
                        blurRadius: 4,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _userAnswer,
                      style: const TextStyle(
                        color: Color(0xFF387EFF),
                        fontSize: 20,
                        fontFamily: 'Baloo Bhaijaan 2',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            const Spacer(),
            if (_isCheck)
              AnswerValidationContainer(
                isCorrect: _isCorrect,
                keyAnswer: _answerKey,
                explanation: 'Skor: ${(accuracy * 100).toStringAsFixed(1)}/100',
              ),

            Text(
              "mic_off".tr(),
              style: GoogleFonts.balooPaaji2(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: HexColor(grey),
              ),
            ),
            const SizedBox(height: 8),
            BlueButton(
              isDisabled: _disable && !_isCheck,
              title: _isCheck
                  ? (_currentSentenceIndex < _sentences.length - 1
                      ? 'next_question'.tr()
                      : 'end'.tr())
                  : 'check_answer'.tr(),
              onTap: _nextSentence,
            ),
          ],
        ),
      ),
    );
  }
}
