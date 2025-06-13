import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:toefl/models/grammar-commentator/grammarCommentator_detail.dart';
import 'package:toefl/models/grammar-commentator/question-grammarCommentator_detail.dart';
import 'package:toefl/remote/api/writingPractice_api.dart';

part 'grammarCommentator_provider_state.freezed.dart';
part 'grammarCommentator_provider_state.g.dart';

@freezed
class GrammarCommentatorProviderState with _$GrammarCommentatorProviderState {
  factory GrammarCommentatorProviderState({
    @Default([]) List<GrammarCommentator> grammarCommentator, // Default agar tidak null
  }) = _GrammarCommentatorProviderState;
}

@riverpod
class GrammarCommentatorProviderStates extends _$GrammarCommentatorProviderStates {
  @override
  FutureOr<GrammarCommentatorProviderState> build() async {
    final GrammarCommentatorList = await GrammarCommentatorAPI().getAllGrammarCommentator();
    
    return GrammarCommentatorProviderState(grammarCommentator: GrammarCommentatorList);
  }

  Future<GrammarCommentator?> storeMessage(Map<String, dynamic> ask) async {
    state = const AsyncLoading(); // Set state loading
    try {
      final response = await GrammarCommentatorAPI().storeMessage(ask);
      return GrammarCommentator(
          id: response?.id,
          userMessage: response?.userMessage,
          botResponse: response?.botResponse,
          englishCorrect: response?.englishCorrect,
          relevance: response?.relevance,
          coherenceScore: response?.coherenceScore,
          lexialScore: response?.lexialScore,
          grammarScore: response?.grammarScore,
          incorrectPart: response?.incorrectPart,
          correctResponse: response?.correctResponse,
          correctedSentence: response?.correctedSentence,
          explanation: response?.explanation);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return null;
    }
  }

  Future<QuestionGrammarCommentator?> getQuestion() async {
    state = const AsyncLoading(); // Set state loading
    try {
      final response = await GrammarCommentatorAPI().getQuestion();
      return QuestionGrammarCommentator(
        question: response?.question,
        type: response?.type
        );
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return null;
    }
  }

}