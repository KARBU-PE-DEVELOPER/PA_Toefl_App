import 'package:flutter/material.dart';
import 'package:toefl/models/quiz_game_result.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';

class ResultQuiz extends StatelessWidget {
  final QuizGameResult result;
  ResultQuiz({super.key, required this.result});

  final List<Map<String, dynamic>> results = [
    {"title": "Correct"},
    {"title": "Incorrect"},
    {"title": "Score"}
  ];

  @override
  Widget build(BuildContext context) {
    final List<String> content = [
      result.benar.toString(),
      (result.total - result.benar).toString(),
      // ((result.benar / result.total * 100)).toStringAsFixed(0) + '%'
      result.score.toString()
    ];
    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.08),
      child: Row(
        children: List.generate(results.length * 2 - 1, (index) {
          if (index.isOdd) {
            return SizedBox(width: 25);
          } else {
            final resultIndex = index ~/ 2;
            final result = results[resultIndex];
            return Expanded(
              child: Container(
                height: 74,
                width: 74,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: HexColor(mariner600),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      child: Text(
                        result["title"],
                        style: TextStyle(color: HexColor(neutral10)),
                      ),
                    ),
                    Container(
                      width: 63,
                      height: 49,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: HexColor(neutral10),
                      ),
                      child: Center(
                        child: Text(
                          content[resultIndex],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 35,
                            color: HexColor(colorSuccess),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }),
      ),
    );
  }
}
