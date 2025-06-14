import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:toefl/models/games/listening_game.dart';
import 'package:toefl/remote/api/games/listeninggame_api.dart';
import 'package:toefl/remote/dio_toefl.dart';

part 'listening_game_provider_state.freezed.dart';
part 'listening_game_provider_state.g.dart';

@freezed
class ListeningGameProviderState with _$ListeningGameProviderState {
  factory ListeningGameProviderState({
    @Default([]) List<String> sentences,
  }) = _ListeningGameProviderState;
}

@riverpod
class ListeningGameProviderStates extends _$ListeningGameProviderStates {
  @override
  FutureOr<ListeningGameProviderState> build() async {
    return ListeningGameProviderState(); // default kosong
  }

  Future<ListeningGame?> getSentence() async {
    const AsyncLoading();
    try {
      // Menggunakan DioToefl untuk mendapatkan data dari API
      final listeningGame = await ListeningGameApi().getWord();

      // Mengembalikan ListeningGame dengan kalimat yang didapat dari API
      return ListeningGame(sentence: listeningGame.sentence);
    } catch (e, stackTrace) {
      AsyncError(e, stackTrace);
      return null;
    }
  }
}
