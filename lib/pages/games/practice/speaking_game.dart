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
      print("Error loading sentences: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memuat soal")),
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
      _isCorrect = similarity > 0.7; // Threshold diturunkan ke 70%
      _isCheck = true;

      // Simpan skor ke dalam list
      if (_scores.length == _currentSentenceIndex) {
        _scores.add(similarity * 10); // Skor dari 0-10
      }
    });
  }

  double _calculateTotalScore() {
    return _scores.fold(0, (sum, item) => sum + item);
  }

  Future<double> _storeScore() async {
    double totalScore = _calculateTotalScore();

    try {
      await SpeakGameApi(dio: Dio()).store(totalScore); // Kirim skor ke API
    } catch (e) {
      print("Error storing score: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan skor")),
      );
    }

    return totalScore;
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
      final totalScore = await _storeScore(); // Simpan dan dapatkan skor
      final score = _calculateTotalScore();
      final averageScore = score / _scores.length;
      _showCompletionDialog(score, averageScore); // Panggil dialog dengan skor
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

  void _showCompletionDialog(double score, double averageScore) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Selamat!"),
        content: Text(
          "Anda telah menyelesaikan semua soal.\n\n"
          "Skor total: ${score.toStringAsFixed(1)} / ${_sentences.length * 10}\n"
          "Rata-rata: ${averageScore.toStringAsFixed(1)} / 10",
        ),
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
    return Scaffold(
      appBar: GameAppBar(title: 'Speaking Games'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
                    Icon(
                      _speechToText.isListening ? Icons.mic_off : Icons.mic,
                      color: Colors.blue[900],
                    ),
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
            if (_isCheck)
              AnswerValidationContainer(
                isCorrect: _isCorrect,
                keyAnswer: _answerKey,
                explanation: 'Skor: ${(accuracy * 10).toStringAsFixed(1)}/10',
              ),

            Text(
              "TEKAN UNTUK BERBICARA",
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
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
