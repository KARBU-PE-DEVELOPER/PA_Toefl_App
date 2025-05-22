import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:toefl/remote/api/games/listeninggame_api.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:toefl/widgets/answer_validation_container.dart';
import 'package:toefl/widgets/blue_button.dart';
import 'package:toefl/widgets/games/listening/sentence_audio_button.dart';
import '../../../widgets/games/game_app_bar.dart';
import 'package:toefl/widgets/quiz/modal/modal_confirmation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:toefl/utils/custom_text_style.dart';
import 'package:toefl/state_management/game/listening_game_provider_state.dart';

class ListeningGamePage extends ConsumerStatefulWidget {
  const ListeningGamePage({super.key});

  @override
  ConsumerState<ListeningGamePage> createState() => _ListeningGamePageState();
}

class _ListeningGamePageState extends ConsumerState<ListeningGamePage> {
  final FlutterTts _flutterTts = FlutterTts();
  final TextEditingController _textController = TextEditingController();
  List<double> _scores = [];
  String _userAnswer = '';
  String _answerKey = "";
  bool _isCheck = false;
  bool _isCorrect = false;
  bool _disable = true;
  double accuracy = 0;
  bool _isLoadingFirst = true;
  bool _isLoading = false;

  List<String> _sentences = [];
  int _currentSentenceIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadSentences();
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
      final listeningGameProvider =
          ref.read(listeningGameProviderStatesProvider.notifier);
      final game = await listeningGameProvider.getSentence();

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

    final answerWords = _answerKey
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .toLowerCase()
        .split(RegExp(r'\s+'));

    final userWords = _userAnswer
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .toLowerCase()
        .split(RegExp(r'\s+'));

    int correctCount = 0;
    final matchedIndexes = <int>{};

    for (var userWord in userWords) {
      double bestScore = 0.0;
      int bestIndex = -1;

      for (int i = 0; i < answerWords.length; i++) {
        if (matchedIndexes.contains(i)) continue;

        double similarity =
            StringSimilarity.compareTwoStrings(userWord, answerWords[i]);
        if (similarity > bestScore) {
          bestScore = similarity;
          bestIndex = i;
        }
      }

      // Anggap benar jika similarity di atas threshold, misal 0.75
      if (bestScore >= 0.75) {
        correctCount++;
        matchedIndexes.add(bestIndex);
      }
    }

    final totalWords = answerWords.length;
    double wordAccuracy = totalWords == 0 ? 0 : correctCount / totalWords;
    setState(() {
      accuracy = wordAccuracy;
      _isCorrect = wordAccuracy > 0.7;
      _isCheck = true;

      if (_scores.length == _currentSentenceIndex) {
        _scores.add(wordAccuracy * 100);
      }

      _isLoading = false;
    });
  }

  double _calculateTotalScore() {
    return _scores.fold(0, (sum, item) => sum + item);
  }

  Future<double> _storeScore() async {
    double totalScore = _calculateTotalScore();
    double averageScore = totalScore / _sentences.length; // karena 3 soal

    try {
      await ListeningGameApi().store(averageScore); // Kirim nilai rata-rata
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
    _textController.clear();

    setState(() {
      _isLoading = true;
    });
    if (_isCheck && _currentSentenceIndex < _sentences.length - 1) {
      setState(() {
        _currentSentenceIndex++;
        _answerKey = _sentences[_currentSentenceIndex];
        _resetState();
        _isLoading = false;
        _userAnswer = '';
      });
      await _flutterTts.speak(_answerKey);
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
  }

  void restartGame() async {
    Navigator.pop(context); // Tutup dialog
    await _flutterTts.stop();

    setState(() {
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

  @override
  void dispose() {
    _flutterTts.stop(); 
    _textController.dispose();
    super.dispose();
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
                          : SentenceAudioButton(
                              isCheck: _isCheck,
                              answerKey: _answerKey,
                              userAnswer: _userAnswer,
                              onPlayAudio: () =>
                                  _speakSentenceByWord(_answerKey),
                            ),
                    ),
                    const SizedBox(height: 18),

                    // TextField untuk jawaban
                    TextField(
                      controller: _textController, // Controller untuk TextField
                      maxLength: 100,
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
                          borderSide: const BorderSide(
                            color: Colors.red, // Optional
                            width: 2,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Colors.red, // Optional
                            width: 3,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      cursorColor: HexColor(mariner700),
                      minLines: 3,
                      maxLines: 6,
                      
                      style: GoogleFonts.balooBhaijaan2(fontSize: 16),
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
