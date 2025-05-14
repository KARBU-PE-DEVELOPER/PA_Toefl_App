import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toefl/models/test/packet_detail.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:toefl/models/test/test_status.dart';
import 'package:toefl/remote/api/full_test_api.dart';
import 'package:toefl/remote/local/shared_pref/test_shared_preferences.dart';
import 'package:toefl/remote/local/sqlite/full_test_table.dart';
import 'package:toefl/utils/list_ext.dart';

part 'full_test_provider.freezed.dart';

@freezed
class FullTestProviderState with _$FullTestProviderState {
  const factory FullTestProviderState({
    required PacketDetail packetDetail,
    @Default([]) List<Question> selectedQuestions,
    @Default(true) bool isLoading,
    @Default(false) bool isSubmitLoading,
    @Default([]) List<bool> questionsFilledStatus,
    @Default(0) int totalQuestions, // Tambahkan default 0
    required TestStatus testStatus,
  }) = _FullTestProviderState;

  const FullTestProviderState._();
}

class FullTestProvider extends StateNotifier<FullTestProviderState> {
  FullTestProvider()
      : super(FullTestProviderState(
          packetDetail: PacketDetail(id: '', name: '', questions: []),
          selectedQuestions: [],
          questionsFilledStatus: [],
          testStatus: TestStatus(
              id: '',
              startTime: '',
              resetTable: false,
              name: '',
              isRetake: false),
        )) {
    // _onInit();
  }

  final FullTestTable _fullTestTable = FullTestTable();
  final FullTestApi _fullTestApi = FullTestApi();
  final TestSharedPreference _testSharedPref = TestSharedPreference();

  Future<void> onInit() async {
    try {
      var newPacketDetail = PacketDetail(
          id: state.packetDetail.id,
          name: state.packetDetail.name,
          questions: state.packetDetail.questions);
      state = state.copyWith(
          isLoading: true,
          packetDetail: newPacketDetail,
          totalQuestions: newPacketDetail.questions.length);
      final testStat = await _testSharedPref.getStatus();
      debugPrint("total pertanyaan ${state.totalQuestions}");
      if (testStat != null) {
        if (testStat.resetTable) {
          await _testSharedPref.saveStatus(
            TestStatus(
              id: testStat.id,
              startTime: testStat.startTime,
              name: testStat.name,
              resetTable: false,
              isRetake: testStat.isRetake,
            ),
          );
          await initPacketDetail(testStat.id).then((val) {
            getQuestionByNumber(1);
          });
        } else {
          getQuestionByNumber(1);
        }
        state = state.copyWith(testStatus: testStat);
      }
    } catch (e) {
      debugPrint("error: $e");
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> resetPacketTable() async {
    await _fullTestTable.resetDatabase();
  }

  Future<void> resetTestStatus() async {
    await _testSharedPref.removeStatus();
  }

  Future<bool> initPacketDetail(String id) async {
    try {
      await resetPacketTable();
      await _getPacketDetailFromApi(id);
      await _insertQuestionsToLocal();

      state = state.copyWith(
          isLoading: false,
          totalQuestions: state.packetDetail.questions.length);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  // Future<void> _getPacketDetailFromApi(String id) async {
  //   try {
  //     final packetDetail = await _fullTestApi.getPacketDetail(id);
  //     debugPrint(
  //         "Packet Detail dari API: ${packetDetail.questions.length} pertanyaan");
  //     state = state.copyWith(packetDetail: packetDetail);
  //   } catch (e) {
  //     rethrow;
  //   }
  // }

  Future<void> _getPacketDetailFromApi(String id) async {
    try {
      final packetDetail = await _fullTestApi.getPacketDetail(id);
      debugPrint(
          "Packet Detail dari API: ${packetDetail.questions.length} pertanyaan");
      state = state.copyWith(
          packetDetail: packetDetail,
          totalQuestions: packetDetail.questions.length);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _insertQuestionsToLocal() async {
    try {
      final packetDetail = state.packetDetail;
      for (var i = 0; i < packetDetail.questions.length; i++) {
        final question = packetDetail.questions[i];
        debugPrint("Insert ke SQLite: ${question.id}");
        _fullTestTable.insertQuestion(question, (i + 1));
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> getQuestionByNumber(int number) async {
    var ableToGet = true;
    for (var element in state.selectedQuestions) {
      if (element.number == number) {
        ableToGet = false;
      }
    }

    if (ableToGet) {
      state = state.copyWith(isLoading: true, selectedQuestions: []);
      await Future.delayed(const Duration(milliseconds: 50));
      try {
        final question = await _fullTestTable.getQuestionByNumber(number);
        if (question.nestedQuestionId.isNotEmpty) {
          final nestedQuestion = await _fullTestTable
              .getQuestionsByGroupId(question.nestedQuestionId);
          state = state.copyWith(selectedQuestions: nestedQuestion);
        } else {
          state = state.copyWith(
              selectedQuestions: List.generate(1, (index) => question));
        }
      } catch (e) {
        debugPrint("error : $e");
      } finally {
        final filledStatus = await getQuestionsFilledStatus();
        state = state.copyWith(
            isLoading: false, questionsFilledStatus: filledStatus);
      }
    }
  }

  Future<void> updateBookmark(List<Question> questions, int bookmarked) async {
    try {
      for (var element in questions) {
        await _fullTestTable.updateBookmark(element.number, bookmarked);
      }
    } catch (e) {
      debugPrint("error: $e");
    }
  }

  // Future<void> updateAnswer(int number, String answer) async {
  //   try {
  //     await _fullTestTable.updateAnswer(number, answer);
  //   } catch (e) {
  //     debugPrint("error: $e");
  //   }
  // }

  Future<void> updateAnswer(int number, String answer) async {
    try {
      await _fullTestTable.updateAnswer(number, answer);
      // Perbarui pertanyaan yang dipilih di state
      await getQuestionByNumber(number);
      final filledStatus = await getQuestionsFilledStatus();
      state = state.copyWith(questionsFilledStatus: filledStatus);
    } catch (e) {
      debugPrint("error: $e");
    }
  }

  // Future<List<bool>> getQuestionsFilledStatus() async {
  //   try {
  //     final questions = await _fullTestTable.getAllAnswer();
  //     return questions.map((e) {
  //       return e?.answer.isNotEmpty ?? false;
  //     }).toList();
  //   } catch (e) {
  //     debugPrint("error: $e");
  //     return [];
  //   }
  // }

  // Future<List<bool>> getQuestionsFilledStatus() async {
  //   final totalQuestions =
  //       state.packetDetail.questions.length; // Ambil dari API
  //   return List.generate(totalQuestions, (index) {
  //     return state.questionsFilledStatus.length > index
  //         ? state.questionsFilledStatus[index]
  //         : false;
  //   });
  // }

  Future<List<bool>> getQuestionsFilledStatus() async {
    try {
      final questions = await _fullTestTable.getAllAnswer();
      return state.packetDetail.questions.map((q) {
        final userAnswer = questions.firstWhereOrNull((ans) => ans?.id == q.id);

        return userAnswer?.answer.isNotEmpty ?? false;
      }).toList();
    } catch (e) {
      debugPrint("error: $e");
      return List.filled(state.packetDetail.questions.length, false);
    }
  }

  Future<bool> submitAnswer() async {
    state = state.copyWith(isSubmitLoading: true);
    try {
      final questions = await _fullTestTable.getAllAnswer();
      final request = questions
          .map((e) => {
                "question_id": e?.id ?? "",
                "bookmark": (e?.bookmarked ?? 0) > 0,
                "answer_user":
                    ((e?.answer)?.isNotEmpty ?? false) ? e!.answer : "-"
              })
          .toList();
      final response =
          await _fullTestApi.submitAnswer(request, state.testStatus.id);
      if (response) {
        debugPrint("success submit answer");
        return true;
      } else {
        debugPrint("failed submit answer");
        return false;
      }
    } catch (e) {
      debugPrint("error: $e");
      return false;
    } finally {
      // state = state.copyWith(isSubmitLoading: false);
    }
  }

  Future<bool> saveAnswerForCurrentQuestion() async {
    state = state.copyWith(isSubmitLoading: false);
    try {
      // Dapatkan nomor soal saat ini
      int currentNumber = state.selectedQuestions.firstOrNull?.number ?? 0;
      if (currentNumber == 0) {
        debugPrint("No current question number found.");
        return false;
      }

      // Ambil data terbaru dari database
      final currentQuestion =
          await _fullTestTable.getQuestionByNumber(currentNumber);
      if (currentQuestion == null) {
        debugPrint("No question found for number $currentNumber");
        return false;
      }

      final request = [
        {
          "question_id": currentQuestion.id,
          "bookmark": (currentQuestion.bookmarked ?? 0) > 0,
          "answer_user":
              currentQuestion.answer.isNotEmpty ? currentQuestion.answer : "-"
        }
      ];

      final response =
          await _fullTestApi.saveAsnwerNextPage(request, state.testStatus.id);

      if (response) {
        debugPrint("Success submit current answer");
        return true;
      } else {
        debugPrint("Failed submit current answer");
        return false;
      }
    } catch (e) {
      debugPrint("Error: $e");
      return false;
    }
  }

  Future<bool> resetAll() async {
    state = state.copyWith(isSubmitLoading: true);
    try {
      await resetPacketTable();
      await resetTestStatus();
      return true;
    } catch (e) {
      return false;
    } finally {
      await Future.delayed(const Duration(seconds: 4));
      state = state.copyWith(isSubmitLoading: false);
    }
  }

  void resetState() {
    state = FullTestProviderState(
      packetDetail: PacketDetail(id: '', name: '', questions: []),
      selectedQuestions: [],
      isLoading: true,
      isSubmitLoading: false,
      questionsFilledStatus: [],
      totalQuestions: 0, // Memastikan totalQuestions juga di-reset
      testStatus: TestStatus(
          id: '', startTime: '', resetTable: false, name: '', isRetake: false),
    );
  }
}

final fullTestProvider =
    StateNotifierProvider<FullTestProvider, FullTestProviderState>((ref) {
  final provider = FullTestProvider();
  ref.onDispose(() {
    debugPrint("dispose full test provider");
    provider.resetState();
  });

  return provider;
});
