import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toefl/routes/route_key.dart';
import 'package:toefl/widgets/quiz/modal/modal_confirmation.dart';

class GameAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final double height;
  final List<Widget>? actions; // Tambahkan ini

  const GameAppBar({
    super.key,
    required this.title,
    this.height = kToolbarHeight,
    this.actions, // Tambahkan ini
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: IconButton(
        onPressed: () async {
          showDialog(
            context: context,
            builder: (context) {
              return ModalConfirmation(
                message: "Are you sure want to abort?",
                leftTitle: "Cancel",
                rightTitle: "Confirm",
                leftFunction: () => Navigator.pop(context),
                rightFunction: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  RouteKey.main,
                  (route) => false,
                ),
              );
            },
          );
        },
        icon: Icon(Icons.close),
      ),
      title: Text(
        title,
        style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      actions: actions, // Tambahkan ini agar bisa menerima tombol kanan
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
