import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:toefl/utils/colors.dart';
import 'package:toefl/utils/custom_text_style.dart';
import 'package:toefl/utils/hex_color.dart';

class ChangeLangDialog extends StatelessWidget {
  const ChangeLangDialog({
    super.key,
    required this.onNo,
    required this.onYes,
  });

  final Function onNo;
  final Function onYes;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      surfaceTintColor: Colors.white,
      backgroundColor: HexColor(mariner100),
      contentPadding: const EdgeInsets.symmetric(vertical: 30, horizontal: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(
          color: HexColor(mariner700),
          width: 5,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding:
                const EdgeInsets.only(top: 12, left: 24, right: 24, bottom: 40),
            child: Text(
              "change_language".tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: HexColor(neutral90),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => onNo(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 12),
                    backgroundColor: HexColor(neutral10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: HexColor(mariner700)),
                    ),
                  ),
                  child: Text(
                    "no".tr(),
                    style: CustomTextStyle.buttonBaloo.copyWith(
                      color: HexColor(mariner700),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: TextButton(
                  onPressed: () => onYes(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 12),
                    backgroundColor: HexColor(mariner700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "yes".tr(),
                    style: CustomTextStyle.buttonBaloo.copyWith(
                      color: HexColor(neutral10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
