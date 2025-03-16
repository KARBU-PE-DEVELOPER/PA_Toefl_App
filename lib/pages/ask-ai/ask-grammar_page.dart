import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:toefl/utils/custom_text_style.dart';
import 'package:toefl/state_management/ask-ai/ask-ai_provider_state.dart';

class AskGrammarPage extends ConsumerStatefulWidget {
  const AskGrammarPage({super.key});

  @override
  ConsumerState<AskGrammarPage> createState() => _AskGrammarPageState();
}

class _AskGrammarPageState extends ConsumerState<AskGrammarPage> {
  final TextEditingController _textController = TextEditingController();
  String _accuracyPercentage = "0";
  String _explanation = "Please enter an English sentence first !!";
  String _englishSentence = "";
  String _question = "Loading question...";

  @override
  void initState() {
    super.initState();
    _fetchQuestion();
  }

  void _refreshQuestion() async {
    final response =
        await ref.read(askGrammarProviderStatesProvider.notifier).getQuestion();
    if (response != null) {
      setState(() {
        _question = response.question ?? "";
        _accuracyPercentage = "0";
        _englishSentence = "";
        _explanation = "Please enter an English sentence first !!";
      });
    }
  }

  void _fetchQuestion() async {
    final response =
        await ref.read(askGrammarProviderStatesProvider.notifier).getQuestion();
    if (response != null) {
      setState(() {
        _question = response.question ?? "";
      });
    }
  }

  void _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;

    String userMessage = _textController.text.trim();

    final response = await ref
        .read(askGrammarProviderStatesProvider.notifier)
        .storeMessage({"user_message": userMessage, "question": _question});

    if (response != null) {
      setState(() {
        if (response.isCorrect == false) {
          _explanation =
              response.explanation?.trim() ?? "No explanation provided.";
          _accuracyPercentage = response.accuracyScore?.toString() ?? "0";
          _englishSentence = response.englishSentence?.trim() ?? "";
        } else {
          _explanation = "Your sentence is grammatically correct.";
          _accuracyPercentage = response.accuracyScore?.toString() ?? "0";
          _englishSentence = "";
        }
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
        title: Text("Ask Grammar", style: CustomTextStyle.askGrammarTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _refreshQuestion,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
                          ? "Sentence"
                          : "Accuracy Percentage",
                      style: CustomTextStyle.askGrammarSubtitle,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80, // Adjust height as needed
                      child: SingleChildScrollView(
                        child: Text(
                          _accuracyPercentage == "0"
                              ? _question
                              : _accuracyPercentage,
                          style: CustomTextStyle.askGrammarBody,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: "Write Something...",
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
            if (_englishSentence.isNotEmpty)
            const SizedBox(height: 8),
            if (_englishSentence.isNotEmpty)
              Card(
                color: HexColor(softBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    "Correct Word: $_englishSentence",
                    style: CustomTextStyle.askGrammarSubtitle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: Card(
                color: HexColor(softBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Text(
                      _explanation,
                      style: CustomTextStyle.askGrammarBody,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
