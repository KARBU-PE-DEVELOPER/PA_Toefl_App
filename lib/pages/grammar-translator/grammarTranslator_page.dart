import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:toefl/utils/custom_text_style.dart';
import 'package:toefl/state_management/grammar-translator/grammarTranslator_provider_state.dart';

class GrammarTranslatorPage extends ConsumerStatefulWidget {
  const GrammarTranslatorPage({super.key});

  @override
  ConsumerState<GrammarTranslatorPage> createState() =>
      _GrammarTranslatorPageState();
}

class _GrammarTranslatorPageState extends ConsumerState<GrammarTranslatorPage> {
  final TextEditingController _textController = TextEditingController();
  String _accuracyPercentage = "0";
  String _explanation = "Please enter an English sentence first !!";
  String _englishSentence = "";
  String _question = "Loading question...";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchQuestion();
    });
  }

  void _fetchQuestion() async {
    final response = await ref
        .read(grammarTranslatorProviderStatesProvider.notifier)
        .getQuestion();
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
        .read(grammarTranslatorProviderStatesProvider.notifier)
        .storeMessage({"user_message": userMessage, "question": _question});

    if (response != null) {
      setState(() {
        _explanation = response.explanation?.trim().isNotEmpty == true
            ? response.explanation!.trim()
            : response.botResponse?.trim() ?? "No explanation provided.";
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
            Text("Grammar Translator", style: CustomTextStyle.askGrammarTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchQuestion,
          ),
        ],
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
                            ? "Sentence"
                            : "Accuracy Percentage",
                        style: CustomTextStyle.askGrammarSubtitle,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100, // Adjust height as needed
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
              const SizedBox(height: 16),
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
    );
  }
}
