import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:toefl/utils/custom_text_style.dart';
import 'package:toefl/state_management/translate_quiz/translateQuiz_provider_state.dart';
import 'package:toefl/widgets/blue_button.dart';
import 'package:easy_localization/easy_localization.dart';

class TranslatequizPage extends ConsumerStatefulWidget {
  const TranslatequizPage({super.key});

  @override
  ConsumerState<TranslatequizPage> createState() =>
      _TranslatequizPageState();
}

class _TranslatequizPageState extends ConsumerState<TranslatequizPage> {
  final TextEditingController _textController = TextEditingController();
  bool _showTextField = true;
  String _accuracyPercentage = "0";
  String _explanation = "please_enter_an_english_sentence".tr();
  String _englishSentence = "";
  String _question = "loading_question".tr();
  bool _isCheck = false;
  bool _disable = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchQuestion();
    });
  }

  void _fetchQuestion() async {
    final response = await ref
        .read(translateQuizProviderStatesProvider.notifier)
        .getQuestion();
    if (response != null) {
      setState(() {
        _question = response.question ?? "";
        _accuracyPercentage = "0";
        _explanation = "please_enter_an_english_sentence".tr();
        _englishSentence = "";
        _showTextField = true;
        _disable = true;
      });
    }
  }

  void _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;

    String userMessage = _textController.text.trim();

    setState(() {
      _showTextField = false; // Hide text field after sending
      _isCheck = true;
      _disable = false;
    });

    final response = await ref
        .read(translateQuizProviderStatesProvider.notifier)
        .storeMessage({"user_message": userMessage, "question": _question});

    if (response != null) {
      setState(() {
        if (response.explanation != null &&
            response.explanation!.trim().isNotEmpty) {
          _explanation = response.explanation!.trim();
          _accuracyPercentage = "0";
        } else if (response.botResponse != null &&
            response.botResponse!.trim().isNotEmpty) {
          _explanation = response.botResponse!.trim();
          _accuracyPercentage = "0";
        } else {
          _explanation = "no_explanation_provided".tr();
        }

        _accuracyPercentage = response.accuracyScore?.toString() ?? "0";
        _englishSentence = response.englishSentence?.trim() ?? "";
      });
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title:
            Text("translate_quiz".tr(), style: CustomTextStyle.askGrammarTitle),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 6,
                shadowColor: Colors.black26,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: HexColor(softBlue),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _accuracyPercentage == "0"
                            ? "translate_quiz_sentence".tr()
                            : "accuracy_percentage".tr(),
                        style: CustomTextStyle.askGrammarSubtitle,
                      ),
                      const SizedBox(height: 8),
                      if (_showTextField)
                        SizedBox(
                          height: 100,
                          child: SingleChildScrollView(
                            child: Text(
                              _question,
                              style: CustomTextStyle.askGrammarBody,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        Text(
                          _accuracyPercentage,
                          style: CustomTextStyle.askGrammarBody,
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Visibility(
                visible: _showTextField,
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: "write_something".tr(),
                    hintStyle: CustomTextStyle.askGrammarBody,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send, color: Colors.black),
                      onPressed: _sendMessage,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_englishSentence.isNotEmpty)
                Card(
                  color: HexColor(softBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Correct Word: $_englishSentence",
                      style: CustomTextStyle.askGrammarSubtitle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Card(
                color: HexColor(softBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _explanation,
                    style: CustomTextStyle.askGrammarBody,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: BlueButton(
          isDisabled: _disable,
          title: 'restart'.tr(),
          onTap: _fetchQuestion,
        ),
      ),
    );
  }
}
