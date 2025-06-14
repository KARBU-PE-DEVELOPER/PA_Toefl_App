import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toefl/models/courses/course.dart';
import 'package:toefl/utils/hex_color.dart';

class CourseCardWidget extends StatelessWidget {
  final Course course;
  final String colorHex;

  const CourseCardWidget({
    super.key,
    required this.course,
    required this.colorHex,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: HexColor(colorHex),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: HexColor('#ffffff').withOpacity(0.2),
              radius: 24,
              child: Text(
                course.courseType?.substring(0, 1).toUpperCase() ?? '?',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.courseName ?? 'No name',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Type: ${course.courseType}',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
