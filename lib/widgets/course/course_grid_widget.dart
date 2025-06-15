import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toefl/models/courses/course.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';
import 'package:toefl/widgets/course/course_card_widget.dart';

class CourseGridWidget extends StatelessWidget {
  final List<Course> courses;
  final String courseType;

  const CourseGridWidget({
    super.key,
    required this.courses,
    required this.courseType,
  });

  Color _getColorForType(String type) {
    switch (type) {
      case 'reading':
        return HexColor('#4A90E2');
      case 'listening':
        return HexColor('#7ED321');
      case 'structure':
        return HexColor('#F5A623');
      default:
        return HexColor('#CCCCCC');
    }
  }

  Color _getLightColorForType(String type) {
    switch (type) {
      case 'reading':
        return HexColor('#E3F2FD');
      case 'listening':
        return HexColor('#F1F8E9');
      case 'structure':
        return HexColor('#FFF8E1');
      default:
        return HexColor('#F5F5F5');
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'reading':
        return Icons.menu_book;
      case 'listening':
        return Icons.headphones;
      case 'structure':
        return Icons.architecture;
      default:
        return Icons.school;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForType(courseType),
              size: 64,
              color: HexColor(neutral60),
            ),
            const SizedBox(height: 16),
            Text(
              'No ${courseType.toUpperCase()} courses available',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: HexColor(neutral70),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new courses!',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: HexColor(neutral60),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Stats
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getLightColorForType(courseType),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getColorForType(courseType).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getIconForType(courseType),
                  color: _getColorForType(courseType),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '${courses.length} ${courseType.toUpperCase()} Course${courses.length > 1 ? 's' : ''} Available',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _getColorForType(courseType),
                  ),
                ),
              ],
            ),
          ),

          // Course Grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                return CourseCardWidget(
                  course: courses[index],
                  color: _getColorForType(courseType),
                  lightColor: _getLightColorForType(courseType),
                  icon: _getIconForType(courseType),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
