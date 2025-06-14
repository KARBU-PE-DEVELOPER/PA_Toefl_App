// import 'package:flutter/material.dart';
// import 'package:toefl/models/courses/course.dart';
// import 'package:toefl/widgets/course/course_card_widget.dart';

// class BuildCourseListWidget extends StatelessWidget {
//   final List<Course> courses;
//   final String colorHex;

//   const BuildCourseListWidget({
//     super.key,
//     required this.courses,
//     required this.colorHex,
//   });

//   @override
//   Widget build(BuildContext context) {
//     if (courses.isEmpty) {
//       return const Center(child: Text('No courses available.'));
//     }

//     return ListView.builder(
//       itemCount: courses.length,
//       itemBuilder: (context, index) {
//         final course = courses[index];
//         return CourseCardWidget(course: course, colorHex: colorHex);
//       },
//     );
//   }
// }
