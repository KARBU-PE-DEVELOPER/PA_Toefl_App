import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';

class HeadingCourseWidget extends StatelessWidget {
  const HeadingCourseWidget({
    super.key,
    this.name,
    this.sumCourse,
    this.backgroundColor,
    this.avatarColor,
  });

  final String? name;
  final int? sumCourse;
  final String? backgroundColor;
  final String? avatarColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),
        color: HexColor(backgroundColor ?? softBlue),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: HexColor(avatarColor ?? deepSkyBlue),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name?.isNotEmpty == true ? name! : "Course",
                        style: GoogleFonts.nunito(
                          fontSize: 14.56,
                          fontWeight: FontWeight.w600,
                          color: HexColor(neutral90),
                        ),
                      ),
                      Text(
                        sumCourse?.isNaN == false
                            ? "$sumCourse Course"
                            : "0 Course",
                        style: GoogleFonts.nunito(
                          fontSize: 14.56,
                          fontWeight: FontWeight.w600,
                          color: HexColor(neutral90),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.expand_more_rounded,
                color: Colors.blueGrey,
                size: 30.0,
                semanticLabel: 'Text to announce in accessibility modes',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
