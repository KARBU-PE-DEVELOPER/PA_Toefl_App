import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:toefl/models/ask-ai/ask-ai_detail.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toefl/state_management/ask-ai/ask-ai_provider_state.dart';

class AskGrammarPage extends ConsumerStatefulWidget {
  const AskGrammarPage({super.key});

  @override
  ConsumerState<AskGrammarPage> createState() => _AskGrammarPageState();
}

class _AskGrammarPageState extends ConsumerState<AskGrammarPage> {
  final List<TextEditingController> _textControllers = _textControllers.last.text.trim();
  final List<String> _messages = [];
  String _accuracyPercentage = "0";

  _sendMessage() async {
    if (_textControllers.isEmpty) return;

    String userMessage = _textControllers.last.text.trim();
    if (userMessage.isEmpty) return;

    final askAI = AskAI(
      id: "",
      userMessage: userMessage,
      botResponse: "",
      isCorrect: false,
      incorrectWord: "",
      englishSentence: "",
      accuracyScore: "",
      explanation: "",
    );

    final response = await ref
        .read(askGrammarProviderStatesProvider.notifier)
        .storeMessage(userMessage);

    if (response != null) {
      setState(() {
        _accuracyPercentage = response.accuracyScore ?? "0";
        _messages.add(response.botResponse ?? "No response");
        _textControllers.add(TextEditingController()); // Tambah input baru
      });
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
          onPressed: () {},
        ),
        title: const Text(
          "Ask Grammar",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.view_sidebar_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Persentase Akurasi
            Card(
              color: HexColor(softBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SizedBox(
                height: 150,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Your Accurate Percentage",
                        style: TextStyle(
                          color: HexColor(skyBlue),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HexColor(royalBlue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: Text(
                          "${_accuracyPercentage}",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500),
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
                        hintText: "Write Something",
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

            // Output Box
            Card(
              color: HexColor(softBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SizedBox(
                height: 80,
                width: double.infinity,
                child: Center(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final state = ref.watch(askGrammarProviderStatesProvider);

                      return state.when(
                        data: (askGrammarState) {
                          if (askGrammarState.askAI.isNotEmpty) {
                            final lastResponse = askGrammarState.askAI.last;
                            return Text(
                              lastResponse.explanation ??
                                  "No explanation available",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.black),
                            );
                          } else {
                            return const Text(
                              "Waiting for response...",
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 16, color: Colors.black),
                            );
                          }
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (err, _) => Text(
                          "Error: $err",
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(fontSize: 16, color: Colors.red),
                        ),
                      );
                    },
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
