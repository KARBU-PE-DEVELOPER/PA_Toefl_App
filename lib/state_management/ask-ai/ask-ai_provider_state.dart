// import 'package:freezed_annotation/freezed_annotation.dart';
// import 'package:riverpod_annotation/riverpod_annotation.dart';

// import 'package:toefl/models/ask-ai/ask-ai_detail.dart';
// import 'package:toefl/remote/api/ask-ai_api.dart';

// part 'ask-ai_provider_state.freezed.dart';
// part 'ask-ai_provider_state.g.dart';

// @freezed
// class AskGrammarProviderState with _$AskGrammarProviderState {
//   factory AskGrammarProviderState({
//     @Default([]) List<AskAI> askAI, // Default agar tidak null
//   }) = _AskGrammarProviderState;
// }

// @riverpod
// class AskGrammarProviderStates extends _$AskGrammarProviderStates {
//   @override
//   FutureOr<AskGrammarProviderState> build() async {
//     final askAIList = await AskAIAPI().getAllAskGrammar();
//     return AskGrammarProviderState(askAI: askAIList);
//   }

  Future<AskAI?> storeMessage(List<Map<String, dynamic>> ask) async {
    state = const AsyncLoading(); // Set state loading
    try {
      final response = await AskAIAPI().storeMessage(ask);
      return AskAI(
          id: response.last.id,
          userMessage: response.last.userMessage,
          botResponse: response.last.botResponse,
          isCorrect: response.last.isCorrect,
          incorrectWord: response.last.incorrectWord,
          englishSentence: response.last.englishSentence,
          accuracyScore: response.last.accuracyScore,
          explanation: response.last.explanation);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return null;
    }
  }
}
