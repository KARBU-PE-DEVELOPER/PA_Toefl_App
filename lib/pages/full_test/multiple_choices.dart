import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toefl/models/test/packet_detail.dart';

import '../../state_management/full_test_provider.dart';
import '../../widgets/answer_button.dart';

class MultipleChoices extends ConsumerStatefulWidget {
  const MultipleChoices({super.key, required this.question});

  final Question question;

  @override
  ConsumerState<MultipleChoices> createState() => _MultipleChoicesState();
}

class _MultipleChoicesState extends ConsumerState<MultipleChoices> {
  var selectedAnswer = "";
  var choices = [];

  @override
  void initState() {
    super.initState();
    selectedAnswer = widget.question.answer;
    choices = widget.question.choices;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(4, (index) {
        return Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: AnswerButton(
                onTap: () async {
                  if (choices.length >= 4) {
                    final newAnswer = choices[index].choice;

                    if (selectedAnswer != newAnswer) {
                      setState(() {
                        selectedAnswer = newAnswer;
                      });

                      // Update jawaban di local database (state)
                      await ref
                          .read(fullTestProvider.notifier)
                          .updateAnswer(widget.question.number, newAnswer);

                      // Kirim langsung ke backend
                      await ref
                          .read(fullTestProvider.notifier)
                          .saveAnswerForCurrentQuestion();
                    }
                  }
                },
                title:
                    "(${String.fromCharCode(65 + index)})  ${choices.length >= 4 ? choices[index].choice : "Choice $index"}",
                isActive: choices.length >= 4
                    ? selectedAnswer == choices[index].choice
                    : false));
      }),
    );
  }
}
