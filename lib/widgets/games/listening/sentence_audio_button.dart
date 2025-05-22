import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:string_similarity/string_similarity.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';

class SentenceAudioButton extends StatelessWidget {
  final bool isCheck;
  final String answerKey;
  final String userAnswer;
  final VoidCallback onPlayAudio;

  const SentenceAudioButton({
    Key? key,
    required this.isCheck,
    required this.answerKey,
    required this.userAnswer,
    required this.onPlayAudio,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isCheck) {
      final answerWords = answerKey.split(RegExp(r'\s+'));
      final userWords = userAnswer.split(RegExp(r'\s+'));

      List<TextSpan> wordSpans = [];

      for (int i = 0; i < answerWords.length; i++) {
        final answerWord = answerWords[i];
        Color wordColor = Colors.red;

        if (i < userWords.length) {
          final userWord = userWords[i];
          final similarity = StringSimilarity.compareTwoStrings(
            userWord.toLowerCase(),
            answerWord.toLowerCase(),
          );

          wordColor = similarity >= 0.75 ? Colors.green : Colors.red;
        }

        wordSpans.add(TextSpan(
          text: answerWord,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: wordColor,
            fontSize: 18,
          ),
        ));

        wordSpans.add(const TextSpan(text: ' '));
      }

      return RichText(
        textAlign: TextAlign.center,
        text: TextSpan(children: wordSpans),
      );
    } else {
      String maskedAnswer = answerKey.split('').map((char) {
        return char == ' ' ? ' ' : '_';
      }).join();

      return GestureDetector(
        onTap: onPlayAudio,
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
  }
}
