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
<<<<<<< HEAD
import 'package:toefl/state_management/games/speaking_games_provider_state.dart';
=======
import 'package:toefl/remote/local/shared_pref/auth_shared_preferences.dart';
>>>>>>> 4b323c465a35fbd301f7e29366e8819d4f7ab1dc
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

  List<String> _sentences = [];
  int _currentSentenceIndex = 0;

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    // _loadWords();
=======
    _loadSentences();
>>>>>>> 4b323c465a35fbd301f7e29366e8819d4f7ab1dc
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

<<<<<<< HEAD
  // void _loadWords() async {
  //   try {
  //     List<SpeakGame> words = await SpeakGameApi().getWord();
  //     debugPrint("$words");
  //     setState(() {
  //       _answerKey = '';
  //     });
  //   } catch (e) {
  //     print("Error loading words: $e");
  //   }
  // }
=======
  void _loadSentences() async {
    try {
      final game =
          await SpeakGameApi(dio: Dio(), authPref: AuthSharedPreference())
              .getWord();
      setState(() {
        _sentences = game.sentence;
        if (_sentences.isNotEmpty) {
          _answerKey = _sentences.first;
        }
      });
    } catch (e) {
      print("Error loading sentences: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memuat soal")),
      );
    }
  }
>>>>>>> 4b323c465a35fbd301f7e29366e8819d4f7ab1dc

  void _checkAnswer() {
    final cleanedAnswer =
        _answerKey.replaceAll(RegExp(r'[.,]'), '').toLowerCase();
    final cleanedUserAnswer =
        _userAnswer.replaceAll(RegExp(r'[.,]'), '').toLowerCase();

    final similarity = cleanedAnswer.similarityTo(cleanedUserAnswer);

    setState(() {
      accuracy = similarity;
      _isCorrect = similarity > 0.7; // Threshold diturunkan ke 70%
      _isCheck = true;
    });
  }

  void _nextSentence() {
    if (_isCheck && _currentSentenceIndex < _sentences.length - 1) {
      setState(() {
        _currentSentenceIndex++;
        _answerKey = _sentences[_currentSentenceIndex];
        _resetState();
      });
<<<<<<< HEAD
      // _loadWords();
    } else if (_userAnswer.isNotEmpty) {
=======
    } else if (_isCheck) {
      _showCompletionDialog();
    } else {
>>>>>>> 4b323c465a35fbd301f7e29366e8819d4f7ab1dc
      _checkAnswer();
    }
  }

  void _resetState() {
    _userAnswer = '';
    _isCheck = false;
    _isCorrect = false;
    _disable = true;
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Selamat!"),
        content: Text("Anda telah menyelesaikan semua soal."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(speakGameProviderStatesProvider);

    return Scaffold(
      appBar: GameAppBar(title: 'Pronunciation Practice'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
<<<<<<< HEAD
            state.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text("Error: $e"),
              data: (data) {
                final sentences =
                    data.speakGame.expand((e) => e.sentence).toList();

                return Expanded(
                  child: GridView.builder(
                    shrinkWrap: true,
                    itemCount: sentences.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.5,
                    ),
                    itemBuilder: (context, index) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            sentences[index],
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
=======
            // Progress Indicator
            Text(
              "Soal ${_currentSentenceIndex + 1} dari ${_sentences.length}",
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
            const SizedBox(height: 24),

            // User Answer Display
            if (_userAnswer.isNotEmpty)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _userAnswer,
                  style: GoogleFonts.nunito(fontSize: 16),
                ),
              ),
            const SizedBox(height: 16),

            // Microphone Button
>>>>>>> 4b323c465a35fbd301f7e29366e8819d4f7ab1dc
            GestureDetector(
              onTap: _speechToText.isNotListening
                  ? _startListening
                  : _stopListening,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _speechToText.isListening
                      ? Colors.red[100]
                      : Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
<<<<<<< HEAD
                    Icon(Icons.mic, color: Colors.blue[900]),
=======
                    Icon(
                      _speechToText.isListening ? Icons.mic_off : Icons.mic,
                      color: Colors.blue[900],
                    ),
>>>>>>> 4b323c465a35fbd301f7e29366e8819d4f7ab1dc
                    const SizedBox(width: 8),
                    Text(
                      _speechToText.isListening
                          ? "KETUK UNTUK BERHENTI"
                          : "KETUK UNTUK BICARA",
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
            const Spacer(),
<<<<<<< HEAD
=======

            // Validation Section
>>>>>>> 4b323c465a35fbd301f7e29366e8819d4f7ab1dc
            if (_isCheck)
              AnswerValidationContainer(
                isCorrect: _isCorrect,
                keyAnswer: _answerKey,
                explanation: 'Skor: ${(accuracy * 10).toStringAsFixed(1)}/10',
              ),
<<<<<<< HEAD
            Text(
              "TEKAN UNTUK BERBICARA",
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
=======

            // Check/Next Button
>>>>>>> 4b323c465a35fbd301f7e29366e8819d4f7ab1dc
            BlueButton(
              isDisabled: _disable && !_isCheck,
              title: _isCheck
                  ? (_currentSentenceIndex < _sentences.length - 1
                      ? 'Soal Selanjutnya'
                      : 'Selesai')
                  : 'Periksa Jawaban',
              onTap: _nextSentence,
            ),
          ],
        ),
      ),
    );
  }
}
