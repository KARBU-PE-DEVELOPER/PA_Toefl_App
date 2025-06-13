import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dart:async';
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
import 'package:toefl/state_management/game/speak_game_provider_state.dart';

class SpeakingGame extends ConsumerStatefulWidget {
  const SpeakingGame({super.key});
  @override
  ConsumerState<SpeakingGame> createState() => _SpeakingGameState();
}

class _SpeakingGameState extends ConsumerState<SpeakingGame> {
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
  Timer? _silenceTimer;
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

  void _onSoundLevelChange(double level) {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 2), () {
      if (_speechToText.isListening) {
        _stopListening(); // otomatis berhenti kalau user diam 2 detik
      }
    });
  }

  void _startListening() async {
    if (_isMicButtonDisabled) return;
    setState(() {
      _isMicButtonDisabled = true;
    });

    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 60), // optional: batas waktu maksimal
      pauseFor: const Duration(seconds: 5),
      onSoundLevelChange: _onSoundLevelChange,
    );

    setState(() {
      _disable = true;
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      
    });
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
      _isCorrect = similarity > 0.7;
      _isCheck = true;

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
        _isMicButtonDisabled = true;
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

  List<InlineSpan> _buildColoredAnswerKey() {
    final answerWords = _answerKey.trim().split(RegExp(r'\s+'));
    final userWords = _userAnswer.trim().split(RegExp(r'\s+'));

    return List.generate(answerWords.length, (i) {
      final realWord = answerWords[i];

      final cleanedAnswerWord =
          realWord.replaceAll(RegExp(r'[.,?!]'), '').toLowerCase();

      String cleanedUserWord = '';
      if (i < userWords.length) {
        cleanedUserWord =
            userWords[i].replaceAll(RegExp(r'[.,?!]'), '').toLowerCase();
      }

      Color wordColor;

      if (!_isCheck) {
        wordColor = HexColor(neutral50); // belum dicek → abu-abu
      } else {
        final isMatched = cleanedAnswerWord.similarityTo(cleanedUserWord) > 0.7;
        wordColor = isMatched
            ? HexColor(colorSuccess) // cocok → hijau
            : Colors.redAccent; // tidak cocok → merah
      }

      return TextSpan(
        text: '$realWord ',
        style: GoogleFonts.balooBhaijaan2(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: wordColor,
        ),
      );
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GameAppBar(title: 'speaking_game'.tr()),
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
                          : RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: _buildColoredAnswerKey(),
                              ),
                            ),
                    ),
                    // User Answer Card
                    // if (_userAnswer.isNotEmpty) ...[
                    //   const SizedBox(height: 16),
                    //   Container(
                    //     width: double.infinity,
                    //     padding: const EdgeInsets.all(16),
                    //     decoration: BoxDecoration(
                    //       color: Colors.white,
                    //       borderRadius: BorderRadius.circular(12),
                    //       border: Border.all(color: HexColor(mariner700)),
                    //       boxShadow: [
                    //         BoxShadow(
                    //           color: Colors.black12,
                    //           blurRadius: 4,
                    //           offset: Offset(0, 2),
                    //         ),
                    //       ],
                    //     ),
                    //     child: Column(
                    //       crossAxisAlignment: CrossAxisAlignment.start,
                    //       children: [
                    //         Text(
                    //           'your_answer'.tr(),
                    //           style: GoogleFonts.balooBhaijaan2(
                    //             fontSize: 16,
                    //             fontWeight: FontWeight.w600,
                    //             color: HexColor(mariner700),
                    //           ),
                    //         ),
                    //         const SizedBox(height: 8),
                    //         Text(
                    //           _userAnswer,
                    //           style: GoogleFonts.balooBhaijaan2(
                    //             fontSize: 18,
                    //             fontWeight: FontWeight.w700,
                    //             color: Colors.black87,
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ],

                    const SizedBox(height: 18),

                    // Mic Button
                    Center(
                      child: GestureDetector(
                        onTap: _isMicButtonDisabled
                            ? null
                            : (_speechToText.isNotListening
                                ? _startListening
                                : _stopListening),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD8E9FF),
                            borderRadius: BorderRadius.circular(7.5),
                            boxShadow: [
                              const BoxShadow(
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
                                _speechToText.isListening
                                    ? Icons.mic_off
                                    : Icons.mic,
                                size: 28,
                                color: const Color(0xFF387EFF),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _speechToText.isListening
                                    ? 'mic_on'.tr()
                                    : 'mic_off'.tr(),
                                style: GoogleFonts.balooBhaijaan2(
                                  color: Color(0xFF387EFF),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (_isCheck)
                      AnswerValidationContainer(
                        isCorrect: _isCorrect,
                        keyAnswer: _answerKey,
                        explanation:
                            'Skor: ${(accuracy * 100).toStringAsFixed(1)}/100',
                      ),

                    const SizedBox(height: 10),
                    Text(
                      "mic_off".tr(),
                      style: GoogleFonts.balooBhaijaan2(
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
