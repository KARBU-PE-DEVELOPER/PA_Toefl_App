import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:toefl/utils/custom_text_style.dart';
import 'package:toefl/exceptions/exceptions.dart';
import 'package:toefl/state_management/writing_practice/grammarCommentator_provider_state.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../widgets/games/game_app_bar.dart';
import 'package:toefl/widgets/writingPractice/buildScoreCard.dart';

class WritingpracticePage extends ConsumerStatefulWidget {
  const WritingpracticePage({super.key});

  @override
  ConsumerState<WritingpracticePage> createState() =>
      _WritingpracticePageState();
}

class _WritingpracticePageState extends ConsumerState<WritingpracticePage>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  String _grammarPercentage = "0";
  String _lexicalScore = "0";
  String _explanation = "please_enter_an_english_sentence".tr();
  String _correctResponse = "";
  String _type = "";
  String _question = "loading_question".tr();
  bool _isLoading = false;
  bool _hasSubmitted = false; // Added flag to track submission
  List<Map<String, dynamic>> _highlightedWords = [];
  int _wordCount = 0; // Added word count tracker

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.bounceOut),
    );

    // Add listener to text controller for word count
    _textController.addListener(_updateWordCount);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchQuestion();
      _fadeController.forward();
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _textController.removeListener(_updateWordCount);
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  // Method to count words in text
  void _updateWordCount() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _wordCount = 0;
      });
    } else {
      // Split by whitespace and filter out empty strings
      final words = text.split(RegExp(r'\s+'));
      setState(() {
        _wordCount = words.where((word) => word.isNotEmpty).length;
      });
    }
  }

  // Method to check if text has minimum 10 words
  bool _hasMinimumWords() {
    return _wordCount >= 10;
  }

  String _getHowToPlayText(String type) {
    switch (type) {
      case 'opinion':
        return 'writing_opinion'.tr();
      case 'discussion':
        return 'writing_discussion';
      case 'advantage_disadvantage':
        return 'writing_advantage_disadvantage'.tr();
      case 'problem_solution':
        return 'writing_problem_solution'.tr();
      case 'double_question':
        return 'writing_double_question'.tr();
      default:
        return 'writing_default'.tr();
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'opinion':
        return Icons.lightbulb_outline;
      case 'discussion':
        return Icons.forum_outlined;
      case 'advantage_disadvantage':
        return Icons.balance_outlined;
      case 'problem_solution':
        return Icons.psychology_outlined;
      case 'double_question':
        return Icons.quiz_outlined;
      default:
        return Icons.edit_outlined;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'opinion':
        return const Color(0xFF6C63FF);
      case 'discussion':
        return const Color(0xFF00BCD4);
      case 'advantage_disadvantage':
        return const Color(0xFF4CAF50);
      case 'problem_solution':
        return const Color(0xFFFF9800);
      case 'double_question':
        return const Color(0xFFE91E63);
      default:
        return HexColor(mariner700);
    }
  }

  void _fetchQuestion() async {
    try {
      setState(() {
        _isLoading = true;
        _hasSubmitted =
            false; // Reset submission flag when fetching new question
      });
      final response = await ref
          .read(grammarCommentatorProviderStatesProvider.notifier)
          .getQuestion();
      if (response != null) {
        setState(() {
          _type = response.type ?? "";
          _grammarPercentage = "0";
          _explanation = "please_enter_an_english_sentence".tr();
          _correctResponse = "";
          _isLoading = false;
          _question = response.question ?? "";
        });
        _scaleController.reset();
        _scaleController.forward();
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
    
    // Check if minimum word count is met
    if (!_hasMinimumWords()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please write at least 10 words. Current: $_wordCount words',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

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
        _lexicalScore = response.lexialScore?.toString() ?? "0";
        _correctResponse = response.correctResponse?.trim() ?? "";
        _hasSubmitted = true; // Set submission flag to true
      });
      _textController.clear();

      // Trigger result animation
      _scaleController.reset();
      _scaleController.forward();
    }
  }

  Widget _buildGradientCard({
    required Widget child,
    List<Color>? gradientColors,
    EdgeInsets? padding,
    double? elevation,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors ??
              [
                const Color(0xFFFFFFFF),
                const Color(0xFFF8FAFF),
              ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(20),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: GameAppBar(
        title: "writing_practice".tr(),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded),
            tooltip: "Refresh Question",
            onPressed:
                _isLoading ? null : _fetchQuestion,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // How to Play Section
                if (_type.isNotEmpty)
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildGradientCard(
                      gradientColors: [
                        _getTypeColor(_type).withOpacity(0.1),
                        _getTypeColor(_type).withOpacity(0.05),
                      ],
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getTypeColor(_type).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getTypeIcon(_type),
                              color: _getTypeColor(_type),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          if (!_hasSubmitted)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "how_to_play".tr(),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _getTypeColor(_type),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getHowToPlayText(_type),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Question/Score Section
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildGradientCard(
                    gradientColors: [
                      HexColor(mariner800),
                      HexColor(mariner500),
                    ],
                    child: Column(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _grammarPercentage == "0"
                                  ? "translate_quiz_sentence".tr()
                                  : "your_scores".tr(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (_grammarPercentage != "0") ...[
                              const SizedBox(height: 16),
                              ScoreRow(
                                grammarScore: _grammarPercentage,
                                lexicalScore: _lexicalScore,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (!_hasSubmitted)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: _isLoading
                                ? Center(
                                    child: Column(
                                      children: [
                                        CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  HexColor(mariner700)),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          "Loading amazing question...",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Text(
                                    _grammarPercentage == "0"
                                        ? _question
                                        : _grammarPercentage,
                                    style: TextStyle(
                                      fontSize:
                                          _grammarPercentage == "0" ? 16 : 32,
                                      fontWeight: _grammarPercentage == "0"
                                          ? FontWeight.w500
                                          : FontWeight.bold,
                                      color: Colors.black87,
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (!_hasSubmitted)
                  _buildGradientCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Word count indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Minimum 10 words required",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _hasMinimumWords()
                                    ? Colors.green.shade50
                                    : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _hasMinimumWords()
                                      ? Colors.green.shade200
                                      : Colors.orange.shade200,
                                ),
                              ),
                              child: Text(
                                "$_wordCount words",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _hasMinimumWords()
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _textController,
                            minLines: 3,
                            maxLines: 5,
                            cursorColor: HexColor(mariner700),
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                            ),
                            decoration: InputDecoration(
                              hintText: "write_something".tr(),
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 16,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: HexColor(mariner700),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _hasMinimumWords() ? _sendMessage : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _hasMinimumWords()
                                  ? HexColor(mariner700)
                                  : Colors.grey.shade400,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: _hasMinimumWords() ? 4 : 1,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send_rounded),
                                const SizedBox(width: 8),
                                Text(
                                  _hasMinimumWords()
                                      ? "Submit Response"
                                      : "Need ${10 - _wordCount} more words",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_hasSubmitted)
                  const SizedBox(height: 0)
                else
                  const SizedBox(height: 16),
                // Correct Response Section
                if (_correctResponse.isNotEmpty)
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildGradientCard(
                      gradientColors: [
                        const Color(0xFF11998E),
                        const Color(0xFF38EF7D),
                      ],
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Correct Response",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxHeight: 90, // Kira-kira 4 baris teks
                              ),
                              child: SingleChildScrollView(
                                child: Text(
                                  _correctResponse,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines:
                                      null, // Biarkan scroll yang membatasi
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),
                if (_explanation != "please_enter_an_english_sentence".tr())
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildGradientCard(
                      gradientColors: [
                        HexColor(mariner800),
                        HexColor(mariner500),
                      ],
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.psychology_outlined,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "AI Feedback",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _explanation,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}