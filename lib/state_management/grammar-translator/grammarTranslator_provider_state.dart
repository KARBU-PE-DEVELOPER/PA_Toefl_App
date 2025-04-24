import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:toefl/models/grammar-translator/grammarTranslator_detail.dart';
import 'package:toefl/models/grammar-translator/question-grammarTranslator_detail.dart';
import 'package:toefl/remote/api/translateQuiz_api.dart';

part 'grammarTranslator_provider_state.freezed.dart';
part 'grammarTranslator_provider_state.g.dart';

@freezed
class GrammarTranslatorProviderState with _$GrammarTranslatorProviderState {
  factory GrammarTranslatorProviderState({
    @Default([]) List<GrammarTranslator> grammarTranslator, // Default agar tidak null
  }) = _GrammarTranslatorProviderState;
}

@riverpod
class GrammarTranslatorProviderStates extends _$GrammarTranslatorProviderStates {
  @override
  FutureOr<GrammarTranslatorProviderState> build() async {
    final GrammarTranslatorList = await GrammarTranslatorAPI().getAllGrammarTranslator();
    
    return GrammarTranslatorProviderState(grammarTranslator: GrammarTranslatorList);
  }

  Future<GrammarTranslator?> storeMessage(Map<String, dynamic> ask) async {
    state = const AsyncLoading(); // Set state loading
    try {
      final response = await GrammarTranslatorAPI().storeMessage(ask);
      return GrammarTranslator(
          id: response?.id,
          userMessage: response?.userMessage,
          botResponse: response?.botResponse,
          isCorrect: response?.isCorrect,
          answerMatch: response?.answerMatch,
          incorrectWord: response?.incorrectWord,
          englishSentence: response?.englishSentence,
          accuracyScore: response?.accuracyScore,
          explanation: response?.explanation);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return null;
    }
  }

  Future<QuestionGrammarTranslator?> getQuestion() async {
    state = const AsyncLoading(); // Set state loading
    try {
      final response = await GrammarTranslatorAPI().getQuestion();
      return QuestionGrammarTranslator(question: response?.question);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return null;
    }
  }

}