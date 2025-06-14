import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toefl/models/courses/course.dart';
import 'package:toefl/state_management/courses/course_list_provider.dart';
import 'package:toefl/widgets/course/build_course_list_widget.dart';
import 'package:toefl/widgets/course/course_card_widget.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:toefl/utils/colors.dart';

class ListCoursePage extends ConsumerWidget {
  const ListCoursePage({super.key});

  String getColorForType(String? type) {
    switch (type) {
      case 'reading':
        return '#4A90E2';
      case 'listening':
        return '#7ED321';
      case 'structure':
        return '#F5A623';
      default:
        return '#CCCCCC';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(courseListProviderProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Courses'),
          bottom: TabBar(
            indicatorColor: HexColor(mariner700),
            labelColor: HexColor(mariner700),
            unselectedLabelColor: HexColor(grey),
            tabs: const [
              Tab(text: 'Reading'),
              Tab(text: 'Listening'),
              Tab(text: 'Structure'),
            ],
          ),
        ),
        body: state.when(
          data: (data) => TabBarView(
            children: [
              BuildCourseListWidget(
                courses: data.reading,
                colorHex: getColorForType('reading'),
              ),
              BuildCourseListWidget(
                courses: data.listening,
                colorHex: getColorForType('listening'),
              ),
              BuildCourseListWidget(
                courses: data.structure,
                colorHex: getColorForType('structure'),
              ),
            ],
          ),
          loading: () => Center(
              child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              HexColor(mariner700),
            ),
          )),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}
