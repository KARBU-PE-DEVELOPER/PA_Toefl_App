import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:toefl/state_management/ask-ai/ask-ai_provider_state.dart';

class AskGrammarPage extends ConsumerStatefulWidget {
  const AskGrammarPage({super.key});

  @override
  ConsumerState<AskGrammarPage> createState() => _AskGrammarPageState();
}

class _AskGrammarPageState extends ConsumerState<AskGrammarPage> {
  final TextEditingController _textController = TextEditingController();
  String _accuracyPercentage = "0";

  String _explanation = "Please input an English sentence first.";
  String _englishSentence = "";

  void _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;

    String userMessage = _textController.text.trim();

    final response = await ref
        .read(askGrammarProviderStatesProvider.notifier)
        .storeMessage({"user_message": userMessage});

    if (response != null) {

      if (response.isCorrect == false) {
        setState(() {
          _explanation = response.explanation ?? "No explanation provided.";
          _accuracyPercentage = response.accuracyScore ?? "0";
          _englishSentence = response.englishSentence ?? "";
        });
      } else if (response.isCorrect == true) {
        setState(() {
          _explanation = response.explanation ?? "";
          _accuracyPercentage = response.accuracyScore ?? "0";
        });
      }
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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Ask Grammar",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Akurasi Persentase
            Card(
              color: HexColor(softBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SizedBox(

                height: 100,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Accuracy Percentage",
                        style: TextStyle(
                          color: HexColor(skyBlue),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "$_accuracyPercentage",
                        style: TextStyle(
                          color: HexColor(royalBlue),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Input Text
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: "Write Something...",
                        hintStyle: TextStyle(color: HexColor(deepSkyBlue)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.black),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),


            // Incorrect Word
            if (_englishSentence.isNotEmpty)
              Card(
                color: HexColor(softBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),

                child: SizedBox(
                  height: 80,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Correct Word: $_englishSentence",
                        style: TextStyle(
                          color: HexColor(royalBlue),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),
            // Hasil Respon
            Card(
              color: HexColor(softBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SizedBox(
                height: 120,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Text(
                        "$_explanation",
                        style:
                            TextStyle(color: HexColor(royalBlue), fontSize: 16),
                      ),
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
