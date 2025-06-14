import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/hex_color.dart';

class CustomTextStyle {
  CustomTextStyle._();

  static TextStyle bold16 = GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static TextStyle bold18 = GoogleFonts.nunito(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static TextStyle light13 = GoogleFonts.nunito(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  static TextStyle extraBold16 = GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w900,
  );

  static TextStyle normal12 = GoogleFonts.nunito(
    fontSize: 12,
  );

  static TextStyle appBarTitle = GoogleFonts.nunito(
    fontSize: 22,
    color: HexColor(neutral90),
    fontWeight: FontWeight.bold,
  );

  static TextStyle gamePartTitle = GoogleFonts.nunito(
    fontSize: 12,
    color: HexColor(mariner50),
    fontWeight: FontWeight.bold,
  );

  static TextStyle medium14 = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static TextStyle semibold12 =
      GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600);

  static TextStyle bold12 =
      GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.bold);

  static TextStyle regular10 =
      GoogleFonts.nunito(fontSize: 10, fontWeight: FontWeight.w400);

  static TextStyle extrabold24 =
      GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w800);

  static TextStyle extrabold20 =
      GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800);

  static TextStyle medium15 =
      GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w500);

  static TextStyle gameScoreResult = GoogleFonts.nunito(
      fontSize: 20, fontWeight: FontWeight.bold, color: HexColor(mariner700));

  static TextStyle gameCardTitle = GoogleFonts.nunito(
    fontSize: 18,
    color: HexColor(neutral90),
    fontWeight: FontWeight.bold,
  );

  static TextStyle gameCardScoreSubTitle = GoogleFonts.nunito(
    fontSize: 20,
    color: HexColor(mariner700),
    fontWeight: FontWeight.w900,
  );

  static TextStyle gameCardPredicateSubTitle = GoogleFonts.nunito(
    fontSize: 20,
    color: HexColor(neutral90),
    fontWeight: FontWeight.bold,
  );

  // ==== Tambahan Font Baloo Bhaijaan 2 untuk AskGrammar ====
  static TextStyle askGrammarTitle = GoogleFonts.balooBhaijaan2(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: HexColor(mariner700),
  );

  static TextStyle askGrammarSubtitle = GoogleFonts.balooBhaijaan2(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    color: HexColor(mariner500),
  );

  static TextStyle askGrammarBody = GoogleFonts.balooBhaijaan2(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: HexColor(neutral50),
  );

  static TextStyle buttonBaloo = GoogleFonts.balooBhaijaan2(
    fontSize: 17,
    fontWeight: FontWeight.bold,
  );
}
