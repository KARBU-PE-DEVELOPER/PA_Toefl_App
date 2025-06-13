import 'package:flutter/material.dart';

class ScoreCircle extends StatelessWidget {
  final String scoreValue;
  final String label;
  final String type;

  const ScoreCircle({
    Key? key,
    required this.scoreValue,
    required this.label,
    required this.type,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double score = double.tryParse(scoreValue) ?? 0;
    Color scoreColor;

    scoreColor = score >= 80
        ? Colors.green
        : score >= 60
            ? Colors.orange
            : score >= 40
                ? Colors.deepOrange
                : Colors.red;

    return Container(
      width: 120,
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [scoreColor.withOpacity(0.8), scoreColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              score.toInt().toString(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScoreRow extends StatelessWidget {
  final String grammarScore;
  final String lexicalScore;

  const ScoreRow({
    Key? key,
    required this.grammarScore,
    required this.lexicalScore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(width: 12),
          ScoreCircle(
              scoreValue: grammarScore, label: 'Grammar', type: 'grammar'),
          ScoreCircle(
              scoreValue: lexicalScore, label: 'Lexical', type: 'lexical'),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
