import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:toefl/models/courses/course.dart';
import 'package:toefl/remote/api/courses/course_api.dart';

part 'course_list_provider.freezed.dart';
part 'course_list_provider.g.dart';

@freezed
class CourseListState with _$CourseListState {
  factory CourseListState({
    @Default([]) List<Course> reading,
    @Default([]) List<Course> listening,
    @Default([]) List<Course> structure,
  }) = _CourseListState;
}

@riverpod
class CourseListProvider extends _$CourseListProvider {
  @override
  FutureOr<CourseListState> build() async {
    try {
      final result = await CourseApi().fetchAllCourses();

      return CourseListState(
        reading: result['reading'] ?? [],
        listening: result['listening'] ?? [],
        structure: result['structure'] ?? [],
      );
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return CourseListState();
    }
  }
}
