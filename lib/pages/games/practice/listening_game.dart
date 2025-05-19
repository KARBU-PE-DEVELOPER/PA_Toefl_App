import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:toefl/remote/api/games/speakgame_api.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:toefl/widgets/answer_validation_container.dart';
import 'package:toefl/widgets/blue_button.dart';
import '../../../widgets/games/game_app_bar.dart';
import 'package:toefl/widgets/quiz/modal/modal_confirmation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:toefl/utils/custom_text_style.dart';
import 'package:toefl/state_management/game/speak_game_provider_state.dart';

class ListeningGamePage extends ConsumerStatefulWidget {
  const ListeningGamePage({super.key});

  @override
  ConsumerState<ListeningGamePage> createState() => _ListeningGamePageState();
}

class _ListeningGamePageState extends ConsumerState<ListeningGamePage> {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  List<double> _scores = [];
  bool _speechEnabled = false;
  String _userAnswer = '';
  String _answerKey = "";
  bool _isCheck = false;
  bool _isCorrect = false;
  bool _disable = true;
  double accuracy = 0;
  bool _isLoadingFirst = true;
  bool _isLoading = false;
  bool _isMicButtonDisabled = false;

  List<String> _sentences = [];
  int _currentSentenceIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSentences();
    _initSpeech();
    _initTTS();
  }

  void _initTTS() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(0.75);
    await _flutterTts.setSpeechRate(0.3);
  }

  Future<void> _speakSentenceByWord(String sentence) async {
    await _flutterTts.speak(sentence);
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    if (_isMicButtonDisabled) return;
    setState(() {
      _isMicButtonDisabled = true;
    });

    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {
      _disable = true;
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final recognizedWords = result.recognizedWords;

    setState(() {
      _userAnswer = recognizedWords;
      _disable = recognizedWords.isEmpty;
      final hasCorrectWord = _hasAnyCorrectWord(recognizedWords, _answerKey);

      _isMicButtonDisabled = hasCorrectWord;
    });
  }

  bool _hasAnyCorrectWord(String userAnswer, String answerKey) {
    final userWords = userAnswer.toLowerCase().split(RegExp(r'\s+'));
    final keyWords = answerKey.toLowerCase().split(RegExp(r'\s+'));

    for (var userWord in userWords) {
      for (var keyWord in keyWords) {
        if (userWord == keyWord) {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _loadSentences() async {
    try {
      final speakGameProvider =
          ref.read(speakGameProviderStatesProvider.notifier);
      final game = await speakGameProvider.getSentence();

      if (game != null && game.sentence.isNotEmpty) {
        await _flutterTts.speak(game.sentence.first);
        setState(() {
          _sentences = game.sentence;
          _answerKey = _sentences.first;
          _isLoadingFirst = false;
        });
      }
    } catch (e) {
      print('error_loading_sentences'.tr(args: [e.toString()]));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("failed_load_questions".tr())),
      );
    }
  }

  void _checkAnswer() async {
    setState(() {
      _isLoading = true;
    });
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
      await SpeakGameApi().store(averageScore); // Kirim nilai rata-rata
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
    // Stop TTS jika sedang bicara
    await _flutterTts.stop();

    // Aktifkan kembali tombol mic
    setState(() {
      _isMicButtonDisabled = false;
    });
    if (_isCheck && _currentSentenceIndex < _sentences.length - 1) {
      setState(() {
        _currentSentenceIndex++;
        _answerKey = _sentences[_currentSentenceIndex];
        _resetState();
        _isLoading = false;
      });
    } else if (_isCheck) {
      final averageScore = await _storeScore();
      _showCompletionDialog(averageScore); // Show dialog pakai skor rata-rata
    } else {
      _checkAnswer();
      setState(() {
        _isLoading = false;
      });
      await _speakSentenceByWord(_answerKey);
    }
  }

  void _resetState() {
    _userAnswer = '';
    _isCheck = false;
    _isCorrect = false;
    _disable = true;
    _isLoading = false;
    _isMicButtonDisabled = false;
  }

  void restartGame() async {
    Navigator.pop(context); // Tutup dialog
    await _flutterTts.stop();

    setState(() {
      _isMicButtonDisabled = false;
      _isLoading = true;
      _scores.clear();
      _userAnswer = '';
      _answerKey = '';
      _isCheck = false;
      _isCorrect = false;
      _disable = true;
      _currentSentenceIndex = 0;
    });

    await _loadSentences();

    setState(() {
      _isLoading = false;
    });
  }

  void _showCompletionDialog(double averageScore) {
    showDialog(
      context: context,
      builder: (context) => ModalConfirmation(
        message:
            '${'average_score'.tr()}: ${averageScore.toStringAsFixed(1)} / 100',
        leftTitle: 'restart'.tr(),
        rightTitle: 'quit'.tr(),
        leftFunction: restartGame,
        rightFunction: () {
          Navigator.popUntil(context, (route) => route.isFirst);
        },
      ),
    );
  }

  Widget _buildSentenceAudioButton() {
    String maskedAnswer = _answerKey.split('').map((char) {
      return char == ' ' ? ' ' : '_';
    }).join();

    return GestureDetector(
      onTap: () => _speakSentenceByWord(_answerKey),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.volume_up, size: 28, color: HexColor(mariner700)),
              const SizedBox(width: 8),
              Text(
                'play_sound'.tr(),
                style: GoogleFonts.balooBhaijaan2(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: HexColor(mariner700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            maskedAnswer,
            textAlign: TextAlign.center,
            style: GoogleFonts.balooBhaijaan2(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GameAppBar(title: 'listening_game'.tr()),
      body: _isLoadingFirst
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(HexColor(mariner700)),
              ),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 26, right: 26, top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Progress Indicator
                    Text(
                      "${'question'.tr()} ${_currentSentenceIndex + 1} ${'of'.tr()} ${_sentences.length}",
                      style: GoogleFonts.balooBhaijaan2(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Answer Key Container
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8E9FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    HexColor(mariner700)),
                              ),
                            )
                          : _buildSentenceAudioButton(),
                    ),
                    const SizedBox(height: 18),

                    // TextField untuk jawaban
                    TextField(
                      onChanged: (val) {
                        setState(() {
                          _userAnswer = val;
                          _disable = val.trim().isEmpty;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'type_your_answer'.tr(),
                        hintStyle: CustomTextStyle.askGrammarBody,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: HexColor(mariner700),
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: HexColor(mariner800),
                            width: 3,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.red, // Optional
                            width: 2,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.red, // Optional
                            width: 3,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      minLines: 3,
                      maxLines: 6,
                      style: GoogleFonts.balooBhaijaan2(fontSize: 16),
                    ),
                    Spacer(),
                    if (_isCheck)
                      AnswerValidationContainer(
                        isCorrect: _isCorrect,
                        keyAnswer: _answerKey,
                        explanation:
                            'Skor: ${(accuracy * 100).toStringAsFixed(1)}/100',
                      ),

                    const SizedBox(height: 10),
                    Text(
                      "play_sound".tr(),
                      style: GoogleFonts.balooPaaji2(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: HexColor(grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: BlueButton(
            size: MediaQuery.of(context).size.width * 0.15,
            height: MediaQuery.of(context).size.height * 0.07,
            isDisabled: _disable && !_isCheck,
            title: _isCheck
                ? (_currentSentenceIndex < _sentences.length - 1
                    ? 'next_question'.tr()
                    : 'end'.tr())
                : 'check_answer'.tr(),
            onTap: _nextSentence,
          ),
        ),
      ),
    );
  }
}
