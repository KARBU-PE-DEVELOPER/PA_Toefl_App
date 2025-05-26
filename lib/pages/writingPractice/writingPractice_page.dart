import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:toefl/utils/custom_text_style.dart';
import 'package:toefl/exceptions/exceptions.dart';
import 'package:toefl/state_management/writing_practice/grammarCommentator_provider_state.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../widgets/games/game_app_bar.dart';

class WritingpracticePage extends ConsumerStatefulWidget {
  const WritingpracticePage({super.key});

  @override
  ConsumerState<WritingpracticePage> createState() =>
      _WritingpracticePageState();
}

class _WritingpracticePageState extends ConsumerState<WritingpracticePage> {
  final TextEditingController _textController = TextEditingController();
  String _grammarPercentage = "0";
  String _explanation = "please_enter_an_english_sentence".tr();
  String _correctResponse = "";
  String _question = "loading_question".tr();
  bool _isLoading = false;
  List<Map<String, dynamic>> _highlightedWords = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchQuestion();
    });
  }

  void _fetchQuestion() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final response = await ref
          .read(grammarCommentatorProviderStatesProvider.notifier)
          .getQuestion();
      if (response != null) {
        setState(() {
          _grammarPercentage = "0";
          _explanation = "please_enter_an_english_sentence".tr();
          _correctResponse = "";
          _isLoading = false;
          _question = response.question ?? "";
        });
      }
    } on ApiException catch (e) {
      setState(() {
        _isLoading = false;
        _question = e.message;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _question = "error_fetching_question".tr();
      });
    }
  }

  void _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;

    String userMessage = _textController.text.trim();

    final response = await ref
        .read(grammarCommentatorProviderStatesProvider.notifier)
        .storeMessage({"user_message": userMessage, "question": _question});

    if (response != null) {
      setState(() {
        _explanation = response.explanation?.trim().isNotEmpty == true
            ? response.explanation!.trim()
            : response.botResponse?.trim() ?? "no_explanation_provided".tr();
        _grammarPercentage = response.grammarScore?.toString() ?? "0";
        _correctResponse = response.correctResponse?.trim() ?? "";
      });
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: GameAppBar(
        title: "writing_practice".tr(),
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
                        _grammarPercentage == "0"
                            ? "translate_quiz_sentence".tr()
                            : "grammar_percentage".tr(),
                        style: CustomTextStyle.askGrammarTitle,
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        child: Center(
                          child: _isLoading
                              ? Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        HexColor(mariner700)), // biru hex
                                  ),
                                )
                              : SingleChildScrollView(
                                  child: Text(
                                    _grammarPercentage == "0"
                                        ? _question
                                        : _grammarPercentage,
                                    style: CustomTextStyle.askGrammarSubtitle,
                                    textAlign: TextAlign.center,
                                  ),
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
                minLines: 4,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: "write_something".tr(),
                  hintStyle: CustomTextStyle.askGrammarBody,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: HexColor(mariner700),
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: HexColor(mariner800),
                      width: 3,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.red, // Optional
                      width: 2,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.red, // Optional
                      width: 3,
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black),
                    onPressed: _sendMessage,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_correctResponse.isNotEmpty)
                Card(
                  color: Color(0xFFD8E9FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Correct Word: $_correctResponse",
                      style: CustomTextStyle.askGrammarSubtitle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Card(
                color: Color(0xFFD8E9FF),
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
