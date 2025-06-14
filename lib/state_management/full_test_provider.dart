import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toefl/models/test/on_going.dart';
import 'package:toefl/models/test/packet_detail.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:toefl/models/test/test_status.dart';
import 'package:toefl/remote/api/full_test_api.dart';
import 'package:toefl/remote/local/shared_pref/test_shared_preferences.dart';
import 'package:toefl/remote/local/sqlite/full_test_table.dart';
import 'package:toefl/remote/local_database_service.dart';
import 'package:toefl/utils/list_ext.dart';
import 'dart:math' as math;
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
      state = state.copyWith(isLoading: true);

      final testStat = await _testSharedPref.getStatus();

      if (testStat != null) {
        if (testStat.id.isEmpty) {
          throw Exception("Invalid test status ID - ID is empty");
        }

        // Update state dengan testStatus dulu
        state = state.copyWith(testStatus: testStat);

        // Reset table logic...
        if (testStat.resetTable) {
          debugPrint("🔄 Resetting table for new test");
          final updatedStatus = TestStatus(
            id: testStat.id,
            startTime: testStat.startTime,
            name: testStat.name,
            resetTable: false,
            isRetake: testStat.isRetake,
          );

          await _testSharedPref.saveStatus(updatedStatus);
          state = state.copyWith(testStatus: updatedStatus);
          await resetPacketTable();
        }

        // Get packet detail
        await _getPacketDetailFromApi(testStat.id);
        state =
            state.copyWith(totalQuestions: state.packetDetail.questions.length);

        // Insert questions
        final existingQuestions = await _fullTestTable.getAllAnswer();
        if (existingQuestions.isEmpty || testStat.resetTable) {
          await _insertQuestionsToLocal();
          debugPrint("📝 Inserted questions to local database");
        } else {
          debugPrint(
              "📋 Using existing questions in local database (${existingQuestions.length} questions)");
        }

        // TAMBAHKAN DEBUG MAPPING SEBELUM SYNC
        await debugQuestionMapping();

        // Sync untuk ongoing test
        if (testStat.isRetake && !testStat.resetTable) {
          debugPrint("🔄 This is a continuing test, syncing with server...");
          await syncWithServerData();

          // DEBUG LAGI SETELAH SYNC
          await debugQuestionMapping();
        } else {
          debugPrint("🆕 This is a new test, no sync needed");
        }

        await getQuestionByNumber(1);

        debugPrint("✅ Initialization completed successfully");
      } else {
        throw Exception("No test status found");
      }
    } catch (e) {
      debugPrint("💥 ERROR IN onInit: $e");
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

  Future<void> syncWithServerData() async {
    try {
      debugPrint(
          "🔍 SYNC DEBUG - state.testStatus.id: '${state.testStatus.id}'");

      if (state.testStatus.id.isEmpty) {
        debugPrint("❌ Cannot sync: test status ID is empty");
        return;
      }

      final ongoingData =
          await _fullTestApi.getOngoingTestData(state.testStatus.id);

      if (ongoingData == null) {
        debugPrint("ℹ️ No ongoing data from server");
        return;
      }

      // Update time information
      if (ongoingData.packetClaim != null) {
        final claim = ongoingData.packetClaim!;
        if (claim.timeStart?.isNotEmpty == true) {
          final updatedStatus = TestStatus(
            id: state.testStatus.id,
            startTime: claim.timeStart!,
            name: state.testStatus.name,
            resetTable: false,
            isRetake: true,
          );

          await _testSharedPref.saveStatus(updatedStatus);
          state = state.copyWith(testStatus: updatedStatus);
          debugPrint("⏰ Updated start time: ${claim.timeStart}");
        }
      }

      // Sync user answers
      if (ongoingData.userAnswers.isNotEmpty) {
        debugPrint(
            "📥 Syncing ${ongoingData.userAnswers.length} answers from server");

        int syncedCount = 0;
        for (final userAnswer in ongoingData.userAnswers) {
          final serverQuestionId = userAnswer.questionId.toString();
          debugPrint(
              "🔍 Processing server answer - Question ID: $serverQuestionId");

          try {
            // Direct database query untuk cari question berdasarkan ID
            final questionNumber =
                await _findQuestionNumberById(serverQuestionId);

            if (questionNumber != null && questionNumber > 0) {
              debugPrint(
                  "✅ Found mapping: Server ID $serverQuestionId -> Local Number $questionNumber");

              if (userAnswer.answerUser.isNotEmpty &&
                  userAnswer.answerUser != "-") {
                await _fullTestTable.updateAnswer(
                    questionNumber, userAnswer.answerUser);
                syncedCount++;
                debugPrint(
                    "✅ Synced answer for question $questionNumber: '${userAnswer.answerUser}'");
              }
            } else {
              debugPrint(
                  "❌ Question not found for server ID: $serverQuestionId");
            }
          } catch (e) {
            debugPrint("❌ Error processing question $serverQuestionId: $e");
          }
        }

        // Update filled status
        final filledStatus = await getQuestionsFilledStatus();
        state = state.copyWith(questionsFilledStatus: filledStatus);

        final answeredCount = filledStatus.where((f) => f).length;
        debugPrint(
            "📊 Sync completed: $syncedCount answers synced, $answeredCount/${filledStatus.length} questions filled");
      }
    } catch (e, stackTrace) {
      debugPrint("⚠️ Error syncing with server: $e");
    }
  }

// Helper method untuk cari question number berdasarkan ID
  Future<int?> _findQuestionNumberById(String questionId) async {
    try {
      final database = await LocalDatabaseService().database;
      final result = await database.rawQuery(
          'SELECT number FROM ${_fullTestTable.tableName} WHERE id_question = ? LIMIT 1',
          [questionId]);

      if (result.isNotEmpty) {
        return result.first['number'] as int?;
      }
      return null;
    } catch (e) {
      debugPrint("❌ Error finding question number for ID $questionId: $e");
      return null;
    }
  }

  Future<void> _insertQuestionsToLocal() async {
    try {
      debugPrint(
          "📝 Starting to insert ${state.packetDetail.questions.length} questions");

      // Reset database dulu untuk memastikan clean state
      await _fullTestTable.resetDatabase();
      debugPrint("🔄 Database reset completed");

      for (int i = 0; i < state.packetDetail.questions.length; i++) {
        final question = state.packetDetail.questions[i];
        final questionNumber = i + 1; // Number dimulai dari 1

        debugPrint(
            "📝 Processing question ${questionNumber}: ID=${question.id}");

        // Insert dengan question number yang benar
        _fullTestTable.insertQuestion(question, questionNumber);
      }

      debugPrint(
          "✅ Successfully inserted ${state.packetDetail.questions.length} questions");

      // Verifikasi hasil insert
      await _verifyDatabaseInsert();
    } catch (e, stackTrace) {
      debugPrint("❌ Error inserting questions: $e");
      debugPrint("❌ Stack trace: $stackTrace");
    }
  }

  Future<void> _verifyDatabaseInsert() async {
    try {
      final allQuestions = await _fullTestTable.getAllAnswer();
      debugPrint(
          "🔍 Database verification: ${allQuestions.length} questions found");

      // Check first 3 questions
      for (int i = 0; i < math.min(3, allQuestions.length); i++) {
        final q = allQuestions[i];
        debugPrint(
            "   DB Question ${i + 1}: ID='${q?.id}', Number=${q?.number}");
      }

      // Check if numbers are set correctly
      final numberSet = allQuestions.map((q) => q?.number).toSet();
      debugPrint("🔍 Question numbers in DB: ${numberSet.take(10)}...");

      if (numberSet.contains(0)) {
        debugPrint("⚠️ WARNING: Found questions with number 0!");
      } else {
        debugPrint("✅ All questions have proper numbers");
      }
    } catch (e) {
      debugPrint("❌ Error verifying database: $e");
    }
  }

  // Tambahkan method debugging untuk melihat struktur data
  Future<void> debugQuestionMapping() async {
    debugPrint("=== QUESTION MAPPING DEBUG ===");

    final questions = state.packetDetail.questions;
    debugPrint("📋 Total questions in packet: ${questions.length}");

    // Show first 10 questions untuk debugging
    for (int i = 0; i < math.min(10, questions.length); i++) {
      final q = questions[i];
      debugPrint("   Question ${i + 1}: ID=${q.id}, Number=${q.number}");
    }

    // Check local database
    final localAnswers = await _fullTestTable.getAllAnswer();
    final answeredLocal =
        localAnswers.where((a) => a?.answer?.isNotEmpty == true).length;
    debugPrint(
        "📊 Local database: $answeredLocal answered out of ${localAnswers.length}");

    // Show answered questions
    for (int i = 0; i < math.min(5, localAnswers.length); i++) {
      final answer = localAnswers[i];
      if (answer?.answer?.isNotEmpty == true) {
        debugPrint("   Local Answer ${i + 1}: '${answer!.answer}'");
      }
    }

    debugPrint("=== END DEBUG ===");
  }

// Di FullTestProvider, tambahkan auto-save yang lebih robust
  Future<void> autoSaveCurrentProgress() async {
    try {
      if (state.selectedQuestions.isNotEmpty) {
        final currentQuestion = state.selectedQuestions.first;

        // Save current answer to server
        final request = [
          {
            "question_id": currentQuestion.id,
            "bookmark": (currentQuestion.bookmarked ?? 0) > 0,
            "answer_user":
                currentQuestion.answer.isNotEmpty ? currentQuestion.answer : "-"
          }
        ];

        await _fullTestApi.saveAsnwerNextPage(request, state.testStatus.id);

        // Update local status
        final filledStatus = await getQuestionsFilledStatus();
        state = state.copyWith(questionsFilledStatus: filledStatus);
      }
    } catch (e) {
      debugPrint("Auto-save error: $e");
    }
  }

// Panggil auto-save setiap kali ada perubahan jawaban
  Future<void> updateAnswer(int number, String answer) async {
    try {
      await _fullTestTable.updateAnswer(number, answer);
      await getQuestionByNumber(number);

      // Auto-save to server
      await autoSaveCurrentProgress();

      final filledStatus = await getQuestionsFilledStatus();
      state = state.copyWith(questionsFilledStatus: filledStatus);
    } catch (e) {
      debugPrint("error: $e");
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
      debugPrint("🔍 GETTING PACKET DETAIL FOR ID: $id"); // Tambahkan ini
      final packetDetail = await _fullTestApi.getPacketDetail(id);
      debugPrint(
          "Packet Detail dari API: ${packetDetail.questions.length} pertanyaan");
      state = state.copyWith(
          packetDetail: packetDetail,
          totalQuestions: packetDetail.questions.length);
    } catch (e) {
      debugPrint(
          "❌ ERROR GETTING PACKET DETAIL FOR ID $id: $e"); // Tambahkan ini
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
          final nestedQuestions = await _fullTestTable
              .getQuestionsByGroupId(question.nestedQuestionId);

          final currentChild =
              nestedQuestions.firstWhereOrNull((q) => q.number == number);

          if (currentChild != null) {
            state = state.copyWith(selectedQuestions: [currentChild]);
          } else {
            debugPrint("No matching nested question for number $number");
            state = state.copyWith(selectedQuestions: []);
          }
        } else {
          state = state.copyWith(selectedQuestions: [question]);
        }

        // if (question.nestedQuestionId.isNotEmpty) {
        //   final nestedQuestion = await _fullTestTable
        //       .getQuestionsByGroupId(question.nestedQuestionId);
        //   state = state.copyWith(selectedQuestions: nestedQuestion);
        // } else {
        //   state = state.copyWith(
        //       selectedQuestions: List.generate(1, (index) => question));
        // }
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

  // Future<void> updateAnswer(int number, String answer) async {
  //   try {
  //     await _fullTestTable.updateAnswer(number, answer);
  //     // Perbarui pertanyaan yang dipilih di state
  //     await getQuestionByNumber(number);
  //     final filledStatus = await getQuestionsFilledStatus();
  //     state = state.copyWith(questionsFilledStatus: filledStatus);
  //   } catch (e) {
  //     debugPrint("error: $e");
  //   }
  // }

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
