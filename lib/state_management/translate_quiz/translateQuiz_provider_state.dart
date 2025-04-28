import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:toefl/models/translate_quiz/translateQuiz_detail.dart';
import 'package:toefl/models/translate_quiz/questionTranslateQuiz_detail.dart';
import 'package:toefl/remote/api/games/translateQuiz_api.dart';

part 'translateQuiz_provider_state.freezed.dart';
part 'translateQuiz_provider_state.g.dart';

@freezed
class TranslateQuizProviderState with _$TranslateQuizProviderState {
  factory TranslateQuizProviderState({
    @Default([]) List<TranslateQuiz> translateQuiz, // Default agar tidak null
  }) = _TranslateQuizProviderState;
}

@riverpod
class TranslateQuizProviderStates extends _$TranslateQuizProviderStates {
  @override
  FutureOr<TranslateQuizProviderState> build() async {
    final TranslateQuizList = await TranslateQuizAPI().getAllTranslateQuiz();
    return TranslateQuizProviderState(translateQuiz: TranslateQuizList);
  }

  Future<TranslateQuiz?> storeMessage(Map<String, dynamic> ask) async {
    state = const AsyncLoading(); // Set state loading
    try {
      final response = await TranslateQuizAPI().storeMessage(ask);
      return TranslateQuiz(
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

  Future<QuestionTranslateQuiz?> getQuestion() async {
    state = const AsyncLoading(); // Set state loading
    try {
      final response = await TranslateQuizAPI().getQuestion();
      return QuestionTranslateQuiz(question: response?.question);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return null;
    }
  }
}
