import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:toefl/models/games/speak_game.dart';
import 'package:toefl/remote/api/games/speakgame_api.dart';

part 'speaking_games_provider_state.freezed.dart';
part 'speaking_games_provider_state.g.dart';

@freezed
class SpeakGameProviderState with _$SpeakGameProviderState {
  factory SpeakGameProviderState({
    @Default([]) List<SpeakGame> speakGame, // Default agar tidak null
  }) = _SpeakGameProviderState;
}

@riverpod
class SpeakGameProviderStates extends _$SpeakGameProviderStates {
  @override
  FutureOr<SpeakGameProviderState> build() async {
    final askAIList = await SpeakGameApi().getWord();
    
    return SpeakGameProviderState(speakGame: askAIList);
  }

  // Future<SpeakGame?> getQuestion() async {
  //   state = const AsyncLoading(); // Set state loading
  //   try {
  //     final sentenceResponse = await SpeakGameApi().getWord();
  //     return SpeakGame(sentence: sentenceResponse?.sentence);
  //   } catch (e, stackTrace) {
  //     state = AsyncError(e, stackTrace);
  //     return null;
  //   }
  // }
}
