import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:toefl/models/courses/course.dart';
import 'package:toefl/remote/api/courses/course_api.dart';

part 'course_detail_provider.freezed.dart';
part 'course_detail_provider.g.dart';

@freezed
class CourseDetailState with _$CourseDetailState {
  factory CourseDetailState({
    Course? course,
  }) = _CourseDetailState;
}

@riverpod
class CourseDetailProvider extends _$CourseDetailProvider {
  @override
  FutureOr<CourseDetailState> build(int courseId) async {
    try {
      final response = await CourseApi().fetchCourseDetail(courseId);
      return CourseDetailState(course: response);
    } catch (e) {
      throw Exception("Gagal mengambil course: $e");
    }
  }
}
