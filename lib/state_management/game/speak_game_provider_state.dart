import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:toefl/models/games/speak_game.dart';
import 'package:toefl/remote/api/games/speakgame_api.dart';
import 'package:toefl/remote/dio_toefl.dart';

part 'speak_game_provider_state.freezed.dart';
part 'speak_game_provider_state.g.dart';

@freezed
class SpeakGameProviderState with _$SpeakGameProviderState {
  factory SpeakGameProviderState({
    @Default([]) List<String> sentences,
  }) = _speakGameProviderState;
}

@riverpod
class SpeakGameProviderStates extends _$SpeakGameProviderStates {
  @override
  FutureOr<SpeakGameProviderState> build() async {
    return SpeakGameProviderState(); // default kosong
  }

  Future<SpeakGame?> getSentence() async {
    const AsyncLoading();
    try {
      // Menggunakan DioToefl untuk mendapatkan data dari API
      final speakGame = await SpeakGameApi().getWord();

      // Mengembalikan SpeakGame dengan kalimat yang didapat dari API
      return SpeakGame(sentence: speakGame.sentence);
    } catch (e, stackTrace) {
      AsyncError(e, stackTrace);
      return null;
    }
  }
}
