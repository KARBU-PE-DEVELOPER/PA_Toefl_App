import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:toefl/models/ask-ai/ask-ai_detail.dart';
import 'package:toefl/remote/api/ask-ai_api.dart';

part 'ask-ai_provider_state.freezed.dart';
part 'ask-ai_provider_state.g.dart';

@freezed
class AskGrammarProviderState with _$AskGrammarProviderState {
  factory AskGrammarProviderState({
    @Default([]) List<AskAI> askAI, // Default agar tidak null
  }) = _AskGrammarProviderState;
}

@riverpod
class AskGrammarProviderStates extends _$AskGrammarProviderStates {
  @override
  FutureOr<AskGrammarProviderState> build() async {
    final askAIList = await AskAIAPI().getAllAskGrammar();
    return AskGrammarProviderState(askAI: askAIList);
  }

  // Future<void> storeMessage(String userMessage) async {
  //   state = const AsyncLoading(); // Tampilkan loading sebelum request
  //   try {
  //     final response = await AskAIAPI().storeMessage(userMessage);
  //     print(response);
  //     // if (response.success) {
  //     //   final updatedAskAIList = await AskAIAPI().getAllAskGrammar();
  //     //   state = AsyncData(AskGrammarProviderState(askAI: updatedAskAIList));
  //     // } else {
  //     //   state = AsyncError(response.message ?? "Failed to store message", StackTrace.current);
  //     // }
  //   } catch (e, stackTrace) {
  //     print("Error in storeMessage: $e");
  //     state = AsyncError(e, stackTrace);
  //   }
  // }
}
