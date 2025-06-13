import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:toefl/utils/custom_text_style.dart';
import 'package:toefl/state_management/translate_quiz/translateQuiz_provider_state.dart';
import 'package:toefl/widgets/blue_button.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../widgets/games/game_app_bar.dart';

class TranslatequizPage extends ConsumerStatefulWidget {
  const TranslatequizPage({super.key});

  @override
  ConsumerState<TranslatequizPage> createState() => _TranslatequizPageState();
}

class _TranslatequizPageState extends ConsumerState<TranslatequizPage> 
    with TickerProviderStateMixin {
  // Controllers
  final TextEditingController _textController = TextEditingController();
  late AnimationController _pulseAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  // State variables
  bool _showTextField = true;
  bool _isLoading = false;
  bool _isCheck = false;
  bool _disable = true;
  
  // Content variables
  String _accuracyPercentage = "0";
  String _explanation = "";
  String _englishSentence = "";
  String _question = "";

  @override
  void initState() {
    super.initState();
    _explanation = "please_enter_an_english_sentence".tr();
    _question = "loading_question".tr();
    
    // Initialize animations
    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _pulseAnimationController.repeat(reverse: true);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchQuestion();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _pulseAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  // === BUSINESS LOGIC METHODS ===
  
  Future<void> _fetchQuestion() async {
    if (!mounted) return;
    
    _setLoadingState(true);
    
    try {
      final response = await ref
          .read(translateQuizProviderStatesProvider.notifier)
          .getQuestion();
          
      if (response != null && mounted) {
        _resetQuestionState(response.question ?? "");
        _slideAnimationController.forward();
      }
    } catch (e) {
      debugPrint('Error fetching question: $e');
    } finally {
      if (mounted) {
        _setLoadingState(false);
      }
    }
  }

  Future<void> _sendMessage() async {
    final userMessage = _textController.text.trim();
    if (userMessage.isEmpty) return;

    _setCheckingState();

    try {
      final response = await ref
          .read(translateQuizProviderStatesProvider.notifier)
          .storeMessage({
            "user_message": userMessage, 
            "question": _question
          });

      if (response != null && mounted) {
        _updateResponseState(response);
        _textController.clear();
        _slideAnimationController.reset();
        _slideAnimationController.forward();
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  // === STATE UPDATE METHODS ===
  
  void _setLoadingState(bool isLoading) {
    if (!mounted) return;
    setState(() {
      _isLoading = isLoading;
    });
  }

  void _resetQuestionState(String question) {
    setState(() {
      _question = question;
      _accuracyPercentage = "0";
      _explanation = "please_enter_an_english_sentence".tr();
      _englishSentence = "";
      _showTextField = true;
      _disable = true;
      _isCheck = false;
    });
    _slideAnimationController.reset();
  }

  void _setCheckingState() {
    setState(() {
      _showTextField = false;
      _isCheck = true;
      _disable = false;
    });
  }

  void _updateResponseState(dynamic response) {
    setState(() {
      if (response.explanation != null && response.explanation!.trim().isNotEmpty) {
        _explanation = response.explanation!.trim();
      } else if (response.botResponse != null && response.botResponse!.trim().isNotEmpty) {
        _explanation = response.botResponse!.trim();
      } else {
        _explanation = "no_explanation_provided".tr();
      }

      _accuracyPercentage = response.accuracyScore?.toString() ?? "0";
      _englishSentence = response.englishSentence?.trim() ?? "";
    });
  }

  // === UI BUILDING METHODS ===

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HexColor(neutral10),
      appBar: GameAppBar(title: 'translate_quiz'.tr()),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBody() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            HexColor(mariner50),
            HexColor(neutral10),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 24),
              _buildMainQuizCard(),
              const SizedBox(height: 20),
              _buildInputSection(),
              const SizedBox(height: 20),
              _buildResultsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              HexColor(deepSkyBlue),
              HexColor(skyBlue),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: HexColor(deepSkyBlue).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.translate,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Translation Challenge',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Test your translation skills',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainQuizCard() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: HexColor(mariner200).withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildQuizHeader(),
            _buildQuizContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HexColor(softBlue),
            HexColor(mariner100),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: HexColor(deepSkyBlue),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.quiz,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _accuracyPercentage == "0"
                ? "translate_quiz_sentence".tr()
                : "accuracy_percentage".tr(),
            style: TextStyle(
              color: HexColor(mariner800),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: _showTextField ? _buildQuestionSection() : _buildAccuracySection(),
    );
  }

  Widget _buildQuestionSection() {
    if (_isLoading) {
      return Column(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: HexColor(mariner50),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      HexColor(deepSkyBlue),
                    ),
                    strokeWidth: 3,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your challenge...',
            style: TextStyle(
              color: HexColor(mariner600),
              fontSize: 16,
            ),
          ),
        ],
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HexColor(mariner50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: HexColor(mariner200),
          width: 2,
        ),
      ),
      child: Text(
        _question,
        style: TextStyle(
          color: HexColor(mariner800),
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAccuracySection() {
    final accuracy = double.tryParse(_accuracyPercentage) ?? 0;
    Color accuracyColor;
    IconData accuracyIcon;
    
    if (accuracy >= 80) {
      accuracyColor = HexColor(colorSuccess);
      accuracyIcon = Icons.celebration;
    } else if (accuracy >= 60) {
      accuracyColor = HexColor(goldenOrange);
      accuracyIcon = Icons.thumb_up;
    } else {
      accuracyColor = HexColor(colorError);
      accuracyIcon = Icons.info;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: accuracyColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accuracyColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                accuracyIcon,
                color: accuracyColor,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                '$_accuracyPercentage%',
                style: TextStyle(
                  color: accuracyColor,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Accuracy Score',
                style: TextStyle(
                  color: HexColor(neutral70),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputSection() {
    return Visibility(
      visible: _showTextField,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: HexColor(mariner100).withOpacity(0.5),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit,
                      color: HexColor(deepSkyBlue),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Your Translation',
                      style: TextStyle(
                        color: HexColor(mariner800),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: TextField(
                  minLines: 4,
                  maxLines: 6,
                  cursorColor: HexColor(deepSkyBlue),
                  controller: _textController,
                  style: TextStyle(
                    color: HexColor(mariner800),
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: "write_something".tr(),
                    hintStyle: TextStyle(
                      color: HexColor(neutral60),
                      fontSize: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: HexColor(mariner200),
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: HexColor(deepSkyBlue),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: HexColor(mariner50),
                    contentPadding: const EdgeInsets.all(16),
                    suffixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: HexColor(deepSkyBlue),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    return Column(
      children: [
        if (_englishSentence.isNotEmpty) _buildCorrectAnswerCard(),
        if (_englishSentence.isNotEmpty) const SizedBox(height: 16),
        _buildExplanationCard(),
      ],
    );
  }

  Widget _buildCorrectAnswerCard() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              HexColor(verySoftGreen),
              HexColor(secondaryGreen).withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: HexColor(seaGreen).withOpacity(0.5),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: HexColor(seaGreen),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Correct Answer',
                  style: TextStyle(
                    color: HexColor(seaGreen),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _englishSentence,
                style: TextStyle(
                  color: HexColor(mariner800),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationCard() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: HexColor(mariner100).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: HexColor(goldenOrange),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lightbulb,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Explanation',
                  style: TextStyle(
                    color: HexColor(mariner800),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: HexColor(softCream),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: HexColor(goldenOrange).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                _explanation,
                style: TextStyle(
                  color: HexColor(mariner800),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: HexColor(mariner100).withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _disable || _isLoading
                    ? [
                        HexColor(neutral40),
                        HexColor(neutral50),
                      ]
                    : [
                        HexColor(deepSkyBlue),
                        HexColor(royalBlue),
                      ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: _disable || _isLoading
                  ? []
                  : [
                      BoxShadow(
                        color: HexColor(deepSkyBlue).withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: (_disable || _isLoading) ? null : _fetchQuestion,
                child: Center(
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.refresh,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'restart'.tr(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}