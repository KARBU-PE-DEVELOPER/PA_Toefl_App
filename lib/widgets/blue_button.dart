import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/colors.dart';
import '../utils/custom_text_style.dart';
import '../utils/hex_color.dart';

class BlueButton extends StatelessWidget {
  const BlueButton({
    super.key,
    this.size = -1,
    this.height = -1,
    required this.title,
    required this.onTap,
    this.isDisabled = false,
    this.child,
  });

  final double size;
  final double height;
  final String title;
  final void Function() onTap;
  final bool isDisabled;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    double buttonWidth =
        size >= 0 ? size : MediaQuery.of(context).size.width * 0.9;
    double buttonHeight =
        height >= 0 ? height : MediaQuery.of(context).size.height * 0.075;

    return GestureDetector(
      onTap: isDisabled ? () {} : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDisabled
              ? HexColor("#939393").withOpacity(0.27)
              : HexColor(mariner700),
          borderRadius: BorderRadius.circular(10),
        ),
        width: buttonWidth,
        height: buttonHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11.0, horizontal: 16.0),
          child: Center(
            child: child ?? // Kalau child tidak null, tampilkan child
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: isDisabled ? HexColor(neutral60) : Colors.white,
                  ),
                ),
          ),
        ),
      ),
    );
  }
}
